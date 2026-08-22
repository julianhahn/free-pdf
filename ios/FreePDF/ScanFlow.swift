//  ScanFlow.swift - one scan, from the first photo to the finished PDF.
//
//  One screen that switches on `scan.state`, and that state is read from the files
//  every time. Nothing here stores where the user got to, so a kill cannot leave this
//  screen believing something the disk disagrees with ([`AGENTS.md`](../AGENTS.md)).

import SwiftUI

struct ScanFlow: View {
    let scan: Scan

    /// The one piece of view state the design allows: the camera is shown while it is
    /// true. Everything else on this screen comes from the files.
    @State private var shooting: Bool
    /// The photo the check screen sent him back from, or nil. Handed to the camera once so
    /// the corner picture survives that trip, and cleared by every other way in.
    @State private var carriedOn: URL?
    /// The page number the next shot lands on. `nil` while shooting new pages, a number
    /// while retaking one.
    @State private var slot: Int?
    /// The pages the engine refused. In memory only, so a relaunch retries once - and it
    /// is what keeps one unreadable photo from wedging the whole scan for ever.
    @State private var failed: Set<Int> = []
    /// What the disk said the last time it was read. The files are still the only state;
    /// this is what SwiftUI redraws on, and it is refreshed at every moment they change.
    @State private var photos: [Int] = []
    @State private var pages: [Int] = []
    /// What the photos cost, read with them rather than on every redraw.
    @State private var photoBytes = 0
    /// What the finished PDF costs, read the same way, for the one line the done screen
    /// prints. Zero until there is one.
    @State private var pdfBytes = 0
    /// How small the pages of this scan are written, as `quality.txt` says it. Part of the
    /// same cache as `photos` and `pages` and refreshed with them, because a view body must
    /// not read the files itself - and it starts on the default, which is what an absent
    /// file means too.
    @State private var quality = Engine.PageQuality.small
    /// Whether `scan.pdf` was there the last time the files were read. Part of the same
    /// cache and for the same reason: `scan.state` lists two directories, and a body that
    /// lists a directory the drain is writing into answers differently twice in a frame.
    @State private var finished = false
    /// The scan's stored name, part of the same cache and for the same reason: the done
    /// screen's field opens on it, and a view body must not read a file itself. Empty means
    /// the list row reads the date.
    @State private var name = ""
    /// The page the carousel is on, by its number.
    @State private var showing = 0
    @State private var message: String?
    @State private var making = false
    /// Whether the done screen has raised the keyboard once already. It is that screen's
    /// own business and lives here for one reason: `Change pages` destroys it and Make PDF
    /// builds it again, so nothing over there can remember across the round trip
    /// ([`DoneView.swift`](./DoneView.swift)).
    @State private var focusTaken = false
    /// True while the check after the first photo is up. In memory only, and set by the
    /// camera the moment that photo lands: once per scan, and a relaunch shows the
    /// viewfinder again rather than the check, because by then the photo is old news.
    @State private var checkingFirst = false
    /// The page the Adjust screen is open on. `nil` means the screen is not up.
    @State private var adjusting: Int?
    /// Grey as the files say it: the lowest-numbered page that has a state file answers
    /// for the whole scan. Part of the same cache as `photos` and `pages` and refreshed
    /// with them, because a view body must not read the files itself.
    @State private var grey = false
    /// True while one page is being written, so the Adjust screen can say so.
    @State private var applyingOne = false
    /// The pages an all-pages run still has to write, and how many it has done. Non-nil
    /// is the takeover: no app bar, no way back, and nothing else on screen.
    @State private var applyingAll: [Int]?
    @State private var applied = 0

    init(scan: Scan) {
        self.scan = scan
        // No pages at all means he was still shooting, so he gets the viewfinder back.
        // Some pages plus leftovers means the scanning was cut off, so the drain below
        // picks it up where it stopped.
        let step = scan.state
        _shooting = State(initialValue: step == .empty || step == .shooting)
    }

    var body: some View {
        Group {
            if shooting {
                CameraView(scan: scan, slot: slot, taken: carriedOn, onFirstPhoto: {
                    shooting = false
                    checkingFirst = true
                    refresh()
                }) {
                    slot = nil
                    shooting = false
                    refresh()
                }
            } else if checkingFirst, let first = photos.first {
                FirstPageCheck(photo: scan.photoURL(first),
                               number: first,
                               quality: quality,
                               // The one screen where the page size can be judged, so it
                               // is where the switch sits. The screen hands the rung out
                               // and this owns the file work, like every other move.
                               onQuality: { wanted in
                                   Task { await setQuality(to: wanted) }
                               },
                               // The retake that already exists: it puts the camera back
                               // on that page number, and no second path is built here.
                               onRetake: {
                                   checkingFirst = false
                                   retake(first)
                               },
                               onCarryOn: {
                                   checkingFirst = false
                                   slot = nil
                                   // The shot he just judged is still the newest one he
                                   // took, so the viewfinder shows it rather than going
                                   // blank until the second page lands.
                                   carriedOn = scan.photoURL(first)
                                   shooting = true
                               })
            } else if applyingAll != nil {
                takeover
            } else if let adjusting {
                AdjustView(photo: scan.photoURL(adjusting),
                           page: scan.pageURL(adjusting),
                           position: (numbers.firstIndex(of: adjusting) ?? 0) + 1,
                           grey: grey,
                           quality: quality,
                           stored: scan.readState(adjusting),
                           applying: applyingOne,
                           message: message,
                           onCancel: { self.adjusting = nil; message = nil },
                           onApply: { values, allPages in
                               Task { await apply(adjusting, values, allPages: allPages) }
                           })
            } else if finished {
                DoneView(pdf: scan.pdf,
                         storedName: name,
                         photos: photos.count,
                         photoBytes: photoBytes,
                         pdfBytes: pdfBytes,
                         focusTaken: $focusTaken,
                         onName: {
                             // Every keystroke, because there is no Save button: the write
                             // is one small file renamed into place, and the list reads it
                             // off the disk the next time it draws.
                             scan.writeName($0)
                         },
                         onChangePages: {
                             // Safe precisely because the PDF is derived: every page file
                             // is still there and rebuilding costs two seconds. Without
                             // it, a bad page spotted only after Make PDF would cost the
                             // whole scan.
                             scan.deletePDF()
                             refresh()
                         },
                         onDeletePhotos: {
                             scan.deletePhotos()
                             refresh()
                         })
                // The third line the camera stand-in reaches out of its own file with:
                // it presses Shoot another page, once, because nothing can tap a
                // simulator ([`FakeShoot.swift`](./FakeShoot.swift)). Once, because the
                // extra pages make a new PDF and this screen comes back.
                .task {
                    if FakeShoot.morePagesWanted != nil,
                       photos.count == FakeShoot.pagesWanted { shootAnother() }
                }
            } else if unscanned.allSatisfy(failed.contains) {
                // Nothing left the drain can do: either every photo has a page, or the
                // ones without have already been refused. Both belong on the pages, not
                // on a progress bar that would never move again.
                check
            } else {
                scanning
            }
        }
        .onAppear(perform: refresh)
    }

    // MARK: - Scanning

    private var scanning: some View {
        VStack(alignment: .leading, spacing: Token.Size.space4) {
            // The refusal sits at the top, and the block stays centred in what is left:
            // a refusal is one page's outcome, not the run's, so the bar carries on.
            if let message { ErrorLine(sentence: message) }
            VStack(alignment: .leading, spacing: Token.Size.space2) {
                Text(line)
                    .font(Token.Face.body(Token.Size.textSub))
                    .lineSpacing(Token.Size.textSub * (Token.Number.leadingBody - 1))
                    // Tabular figures, so the line does not shuffle its width between
                    // "1 of 12" and "11 of 12".
                    .monospacedDigit()
                    .foregroundStyle(Token.Palette.text)
                bar(atPhoto, of: photos.count)
                Text(note)
                    .font(Token.Face.body(Token.Size.textMeta))
                    .lineSpacing(Token.Size.textMeta * (Token.Number.leadingBody - 1))
                    .foregroundStyle(Token.Palette.textMuted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .padding(Token.Size.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Token.Palette.bg)
        .tint(Token.Palette.accent)
        .navigationBarTitleDisplayMode(.inline)
        .task { await drain() }
    }

    /// The bar: a rule that fills, no radius and no system tint. The filled part is a
    /// full width rule squeezed from the left, so nothing here has to measure the space
    /// it was given.
    private func bar(_ done: Int, of total: Int) -> some View {
        Rectangle()
            .fill(Token.Palette.dividerStrong)
            .frame(height: Token.Size.progressBarH)
            .overlay {
                Rectangle()
                    .fill(Token.Palette.accent)
                    .scaleEffect(x: CGFloat(done) / CGFloat(max(total, 1)),
                                 y: 1,
                                 anchor: .leading)
            }
    }

    private var line: String { "Scanning page \(atPhoto) of \(photos.count)" }
    private var note: String { "You can close the app. It carries on from here." }

    /// Which photo of the run is being worked on, 1 based - what the line counts and how
    /// far the bar has come.
    private var atPhoto: Int { min(photosDone + 1, photos.count) }

    /// How many photos are done, counted in the run rather than read as a page number:
    /// page numbers keep their gaps after a delete, so "page 12 of 11" is what a number
    /// would say.
    ///
    /// Counted out of `photos` and `pages` - the disk as it was last read - and never off
    /// the disk itself. A view body that lists a directory the drain is writing into gives
    /// a different answer twice in one frame, and SwiftUI then never settles: every page
    /// lands, and the app sits on this screen for ever instead of moving on to the PDF.
    private var photosDone: Int { photos.filter(pages.contains).count }

    /// One page at a time, from the first photo that has no page file, until there is
    /// none left it can do.
    ///
    /// One page at a time is the memory guarantee, and it is the shape of this loop
    /// rather than a comment: sharpening one page peaks near 220 MB on its own
    /// ([`../../ffi/AGENTS.md`](../../ffi/AGENTS.md)).
    ///
    /// The task is cancelled when the screen goes away, but a page already in flight
    /// runs to the end - `Task.detached` does not inherit cancellation. That is what is
    /// wanted: a page either lands on disk whole or was never there.
    /// The photos with no page yet, out of the cache above and never off the disk. This
    /// is what decides the screen, what hides Make PDF, and what the drain picks from -
    /// three answers that have to agree inside one frame, which a directory listing under
    /// a running drain cannot promise.
    private var unscanned: [Int] { photos.filter { !pages.contains($0) } }

    private func drain() async {
        while !Task.isCancelled,
              let number = unscanned.first(where: { !failed.contains($0) }) {
            // The scan's own rung, out of the cache with everything else: a page the
            // drain writes has to be the size the switch promised, including every page
            // shot after the switch was moved.
            let rung = quality
            do {
                try await Task.detached(priority: .utility) {
                    try Engine.scanPage(scan.photoURL(number),
                                        into: scan.pageURL(number), rung)
                }.value
                // The page the engine just built carries the engine's own recipe, so
                // any older sidecar is about a photo that is gone - a retake. It goes
                // with the page it no longer describes.
                scan.deleteState(number)
            } catch {
                // One photo the engine will not take must not wedge the scan: without
                // this the loop would pick the same number for ever.
                failed.insert(number)
                message = error.localizedDescription
            }
            refresh()
        }
    }

    // MARK: - Applying

    /// The all-pages run, and the one screen in this app that takes the phone over: no
    /// app bar and no way back, because a kill leaves a mix of adjusted and unadjusted
    /// pages with nothing on disk telling them apart.
    ///
    /// It is the drain's furniture with the drain's note turned around. The drain says
    /// "You can close the app" because it resumes; this cannot resume, so it says the
    /// opposite, and the counter above the bar is the second line that tells the two
    /// screens apart.
    private var takeover: some View {
        let total = applyingAll?.count ?? 0
        return VStack(alignment: .leading, spacing: Token.Size.space4) {
            Text("Page \(min(applied + 1, total)) of \(total)")
                .font(Token.Face.body(Token.Size.textSub))
                .monospacedDigit()
                .foregroundStyle(Token.Palette.text)
            Text("Applying to \(total) pages…")
                .font(Token.Face.body(Token.Size.textSub))
                .monospacedDigit()
                .foregroundStyle(Token.Palette.text)
            bar(applied, of: total)
            Text("Keep the app open.")
                .font(Token.Face.body(Token.Size.textMeta))
                .foregroundStyle(Token.Palette.textMuted)
        }
        .padding(Token.Size.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(Token.Palette.bg)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Applying to \(total) pages. Keep the app open.")
    }

    private func apply(_ number: Int, _ values: Engine.Adjustments, allPages: Bool) async {
        // Two taps land as two tasks before either sets a flag, and the second run would
        // count "Page 14 of 7" over the first one's pages.
        guard !applyingOne, applyingAll == nil else { return }
        message = nil
        scan.deletePDF()
        if allPages {
            await everyPage { one in await write(one, values, on: one == number) }
            adjusting = nil
        } else {
            applyingOne = true
            if await write(number, values, on: true) { adjusting = nil }
            applyingOne = false
            refresh()
        }
    }

    /// Every page of the scan, one at a time, under the takeover. `each` writes one page
    /// and says whether it worked. Two things reach it: Apply to all pages, and the Grey
    /// switch.
    ///
    /// The numbers come straight off the disk, like `makePDF()`: the run has to cover
    /// every page and the cache one refresh behind could leave one out. Both directories,
    /// because a page whose photo is gone has to be refused and named, not silently
    /// missed.
    private func everyPage(_ each: (Int) async -> Bool) async {
        let numbers = Array(Set(scan.photos + scan.pages)).sorted()
        let photos = Set(scan.photos)
        applyingAll = numbers
        applied = 0
        var skipped: [Int] = []
        for one in numbers {
            if !photos.contains(one) { skipped.append(one) }
            if !(await each(one)) {
                // Whatever went wrong, the engine's own sentence is on screen and it
                // has to say which page it was about.
                message = "Page \(one): " + (message ?? "")
            }
            applied += 1
            refresh()
        }
        applyingAll = nil
        // One missing photo already put the engine's own sentence on screen, named with
        // its page. More than one needs the sentence that names them all - and that
        // sentence is only ever about missing photos, which is its only cause.
        if skipped.count > 1 {
            let all = skipped.map(String.init).formatted(.list(type: .and))
            message = "Pages \(all) were not changed, because their photos are missing."
        }
    }

    /// Grey is a fact about the pages, not about the screen, so the switch rewrites all
    /// of them: the same takeover, the same words, each page with its own stored values
    /// and only `grey` moved. A page with no state file gets the engine's suggestion
    /// plus the flipped switch, exactly as Adjust would open it.
    ///
    /// ponytail: the switch shows the lowest-numbered page's answer, so a scan whose
    /// pages disagree shows one of them. Ceiling: reconcile when someone reports it.
    private func flipGrey(to wanted: Bool) async {
        guard !applyingOne, applyingAll == nil, wanted != grey else { return }
        message = nil
        scan.deletePDF()
        await everyPage { one in
            guard var values = await asked(one) else { return false }
            values.grey = wanted
            // `write` lays a new cut inside the stored one, and these *are* the stored
            // values - so this run asks for no further cut and keeps the page as it is.
            (values.cropX, values.cropY) = (0, 0)
            (values.cropWidth, values.cropHeight) = (0, 0)
            return await write(one, values, on: true)
        }
    }

    /// How small a page is written is one fact about the whole scan, exactly like Grey, so
    /// moving the switch rewrites every page that exists: the same takeover, the same
    /// words, and nothing about a page changes but its size on disk.
    ///
    /// The order, and what a kill costs at each point:
    ///
    /// 1. **The PDF.** Every action that touches a page deletes it first, and this is no
    ///    different: a kill here costs the PDF only, which is derived from the pages and
    ///    comes back in two seconds.
    /// 2. **`quality.txt`.** One atomic rename, so it is there whole or not at all. A kill
    ///    here leaves the setting new and the pages old, and nothing is lost: every page
    ///    written from that moment on - the drain's included - is at the new rung, and the
    ///    switch shows what the file says, so flipping it twice puts the old pages right.
    ///    The other order would be worse: pages at the new rung under a file naming the old
    ///    one would send the switch back and cost the whole run again, not one page.
    /// 3. **The pages, one at a time.** Each is renamed into place by the engine, so a kill
    ///    costs the one page in flight - and that page is whole and old or whole and new,
    ///    never half. A scan left half at each rung reads perfectly and looks slightly
    ///    uneven, which is what the takeover's "Keep the app open." already warns about
    ///    (`../../user-flows.md` DECISIONS point 3); no page and no scan is ever lost.
    private func setQuality(to wanted: Engine.PageQuality) async {
        guard !applyingOne, applyingAll == nil, wanted != quality else { return }
        message = nil
        scan.deletePDF()
        scan.writeQuality(wanted)
        quality = wanted
        // The pages that exist, read once off the disk. A photo with no page yet belongs to
        // the drain, which writes it at the new rung by itself - and on the first page check
        // there is no page at all yet, where doing it here would be a second engine run
        // beside the one this screen's own picture needs.
        let written = Set(scan.pages)
        await everyPage { one in
            guard written.contains(one) else { return true }
            return await rewrite(one, at: wanted)
        }
    }

    /// One page written again at the given rung, and nothing else about it changed.
    ///
    /// Two ways back, and the disk says which: a page that still has its `state/NNNN.txt`
    /// goes through `adjust_page` with exactly those values, so a crop, a turn or a nudged
    /// level survives; a page with none goes through `scan_page`, which is the run that made
    /// it in the first place. Nothing is written into `state/` either way, because what the
    /// user asked for has not changed - only how small it is written.
    ///
    /// A page whose photo is gone cannot be made again at all, and the engine is what says
    /// so: `No file found at …/photo/0007.jpg.` `everyPage` puts `Page 7: ` in front of it,
    /// and more than one missing photo becomes the copy table's "Pages 4, 9 and 18 were not
    /// changed, because their photos are missing." The page file that is there stays exactly
    /// as it was, because a call that fails writes nothing.
    private func rewrite(_ number: Int, at rung: Engine.PageQuality) async -> Bool {
        let photo = scan.photoURL(number)
        let page = scan.pageURL(number)
        let stored = scan.readState(number)
        do {
            try await Task.detached(priority: .userInitiated) {
                if let stored {
                    try Engine.adjustPage(photo, into: page, stored, rung)
                } else {
                    try Engine.scanPage(photo, into: page, rung)
                }
            }.value
            return true
        } catch {
            message = error.localizedDescription
            return false
        }
    }

    /// What that page was last told, or what the engine would do to it by itself.
    private func asked(_ number: Int) async -> Engine.Adjustments? {
        if let stored = scan.readState(number) { return stored }
        let photo = scan.photoURL(number)
        do {
            return try await Task.detached(priority: .userInitiated) {
                try Engine.suggest(photo).values
            }.value
        } catch {
            message = error.localizedDescription
            return nil
        }
    }

    /// One page rewritten, or the engine's sentence on screen and `false`. Detached, so a
    /// page in flight runs to the end: it lands whole or was never there.
    ///
    /// `own` is false for every page of an all-pages run except the one the user was
    /// looking at. Only the corners are pixels of that one photo and mean nothing on any
    /// other, so they are asked of the engine again, per page. The crop travels: it is a
    /// fraction, so the same box cuts the same piece out of every page.
    ///
    /// The switch comes from that page's own suggestion too, not from the page the user
    /// was looking at: a photo with no sheet in it has no corners to pull flat, and one
    /// that runs off the frame would be bent. Both are left alone rather than refused,
    /// exactly as the automatic run leaves them ([`../../ffi/AGENTS.md`](../../ffi/AGENTS.md)).
    /// The rung is the scan's own and travels with every write: it is one setting for the
    /// whole scan, so an Apply that dropped it would quietly push one page back to full
    /// quality behind a switch that says otherwise.
    private func write(_ number: Int, _ values: Engine.Adjustments, on own: Bool) async -> Bool {
        let photo = scan.photoURL(number)
        let page = scan.pageURL(number)
        let values = values.composed(onto: scan.readState(number))
        let rung = quality
        do {
            let asked = try await Task.detached(priority: .userInitiated) { () -> Engine.Adjustments in
                var mine = values
                if !own {
                    if mine.pullTheSheetFlat {
                        let its = try Engine.suggest(photo)
                        mine.corners = its.values.corners
                        mine.pullTheSheetFlat = its.foundASheet && !its.runsOffThePicture
                    } else {
                        mine.corners = Array(repeating: 0, count: 8)
                    }
                }
                try Engine.adjustPage(photo, into: page, mine, rung)
                return mine
            }.value
            // The page first, its sidecar second, and that order is the whole safety
            // argument. Killed before the rename: the old page and the old instruction,
            // nothing happened. Killed in between: the new page with the previous
            // instruction, so the user redoes one nudge - nothing is corrupt and no
            // screen lies, because `Scan.state` never reads this file. The reverse skew,
            // a sidecar ahead of its page, cannot happen.
            //
            // What is stored is what was really sent: on an all-pages run each page
            // writes its own re-asked corners, not the corners of the page the user was
            // looking at.
            scan.writeState(number, asked)
            return true
        } catch {
            message = error.localizedDescription
            return false
        }
    }

    // MARK: - Checking the pages

    private var check: some View {
        PagesView(scan: scan,
                  numbers: numbers,
                  photos: photos,
                  failed: failed,
                  complete: unscanned.isEmpty,
                  making: making,
                  message: message,
                  grey: grey,
                  quality: quality,
                  showing: $showing,
                  onRetake: retake,
                  onDelete: deletePage,
                  onGrey: { wanted in Task { await flipGrey(to: wanted) } },
                  onQuality: { wanted in Task { await setQuality(to: wanted) } },
                  onAdjust: { number in
                      message = nil
                      adjusting = number
                  },
                  onShootAnother: shootAnother,
                  onMakePDF: { Task { await makePDF() } })
        // The second of the two lines the camera stand-in reaches out of its own file
        // with: it presses Make PDF for the check ([`FakeShoot.swift`](./FakeShoot.swift)).
        // The same condition the button carries, or a refused page would be left out of
        // a PDF nobody asked for.
        .task { if FakeShoot.pagesWanted != nil, unscanned.isEmpty, !making { await makePDF() } }
    }

    /// Every page number this scan has, whether it got as far as a page file or not.
    /// A photo the engine refused has to be on this carousel too - it is the only place
    /// the user can do something about it.
    private var numbers: [Int] { Array(Set(photos + pages)).sorted() }

    /// One more page at the end of a scan that was already whole. The PDF goes first: it
    /// is what the screen reads as finished, and a scan that still had one would send him
    /// to the done screen instead of the camera, with the new photo never drained.
    private func shootAnother() {
        scan.deletePDF()
        slot = nil
        carriedOn = nil
        shooting = true
        refresh()
    }

    private func retake(_ number: Int) {
        // The page file goes first. A kill in between leaves the page merely unscanned,
        // so the drain rebuilds it from the old photo - never a fresh photo wearing a
        // page made from the one before it.
        try? FileManager.default.removeItem(at: scan.pageURL(number))
        failed.remove(number)
        slot = number
        carriedOn = nil
        shooting = true
        refresh()
    }

    private func deletePage(_ number: Int) {
        // Page first again, for the same reason turned around: a kill in between costs
        // the deletion, never a page in the PDF he asked to be rid of.
        try? FileManager.default.removeItem(at: scan.pageURL(number))
        try? FileManager.default.removeItem(at: scan.photoURL(number))
        scan.deleteState(number)
        failed.remove(number)
        refresh()
    }

    private func makePDF() async {
        making = true
        message = nil
        // Straight from the disk, not from the cache above: this is the one place where
        // reading a list that is one refresh out of date would leave a page out of the
        // PDF.
        let files = scan.pages.map(scan.pageURL)
        let pdf = scan.pdf
        do {
            try await Task.detached(priority: .userInitiated) {
                try Engine.pagesToPDF(files, out: pdf)
            }.value
        } catch {
            message = error.localizedDescription
        }
        making = false
        refresh()
    }

    // MARK: - Reading the disk

    /// Reads the files again and hands SwiftUI something to redraw on. Called at every
    /// moment the files change, which is the only way this screen learns anything.
    private func refresh() {
        photos = scan.photos
        pages = scan.pages
        photoBytes = scan.photoBytes
        pdfBytes = scan.pdfBytes
        finished = scan.finished
        quality = scan.quality
        name = scan.name ?? ""
        // The lowest-numbered page that has a state file answers for the scan.
        grey = Array(Set(photos + pages)).sorted().lazy.compactMap(scan.readState).first?.grey ?? false
        if !numbers.contains(showing) { showing = numbers.first ?? 0 }
    }
}
