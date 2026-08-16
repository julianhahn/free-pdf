//  ScanFlow.swift - one scan, from the first photo to the finished PDF.
//
//  One screen that switches on `scan.state`, and that state is read from the files
//  every time. Nothing here stores where the user got to, so a kill cannot leave this
//  screen believing something the disk disagrees with ([`AGENTS.md`](../AGENTS.md)).

import PDFKit
import SwiftUI

struct ScanFlow: View {
    let scan: Scan

    /// The one piece of view state the design allows: the camera is shown while it is
    /// true. Everything else on this screen comes from the files.
    @State private var shooting: Bool
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
    /// Whether `scan.pdf` was there the last time the files were read. Part of the same
    /// cache and for the same reason: `scan.state` lists two directories, and a body that
    /// lists a directory the drain is writing into answers differently twice in a frame.
    @State private var finished = false
    /// The page the carousel is on, by its number.
    @State private var showing = 0
    @State private var message: String?
    @State private var making = false
    @State private var reading = false
    /// The name for the copy that leaves, and the temporary link that carries it. Nothing
    /// is stored: both die with the screen, and the file on disk is always `scan.pdf`.
    @State private var name = ""
    /// The name field's focus, and whether it has been taken already. Make PDF always
    /// means a copy is about to leave, so the field is raised with the screen and the
    /// keyboard's first load is paid there rather than on the first tap. Taken once:
    /// `Change pages` destroys this branch and Make PDF builds it again, and a second
    /// raise would throw the keyboard over a screen he came back to read.
    @FocusState private var naming: Bool
    @State private var focusTaken = false
    @State private var shareCopy: URL?
    @State private var confirmingPhotos = false
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
                CameraView(scan: scan, slot: slot) {
                    slot = nil
                    shooting = false
                    refresh()
                }
            } else if applyingAll != nil {
                takeover
            } else if let adjusting {
                AdjustView(photo: scan.photoURL(adjusting),
                           page: scan.pageURL(adjusting),
                           position: (numbers.firstIndex(of: adjusting) ?? 0) + 1,
                           grey: grey,
                           stored: scan.readState(adjusting),
                           applying: applyingOne,
                           message: message,
                           onCancel: { self.adjusting = nil; message = nil },
                           onApply: { values, allPages in
                               Task { await apply(adjusting, values, allPages: allPages) }
                           })
            } else if finished {
                done
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
            do {
                try await Task.detached(priority: .utility) {
                    try Engine.scanPage(scan.photoURL(number), into: scan.pageURL(number))
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
        // The PDF is derived from the pages, so a rewritten page makes it wrong. Same
        // move as Change pages and Shoot another page, and it goes first: a kill after it
        // costs a rebuild, never a PDF holding a page the user replaced.
        try? FileManager.default.removeItem(at: scan.pdf)
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
        try? FileManager.default.removeItem(at: scan.pdf)
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
    private func write(_ number: Int, _ values: Engine.Adjustments, on own: Bool) async -> Bool {
        let photo = scan.photoURL(number)
        let page = scan.pageURL(number)
        let values = values.composed(onto: scan.readState(number))
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
                try Engine.adjustPage(photo, into: page, mine)
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
                  showing: $showing,
                  onRetake: retake,
                  onDelete: deletePage,
                  onGrey: { wanted in Task { await flipGrey(to: wanted) } },
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
        try? FileManager.default.removeItem(at: scan.pdf)
        slot = nil
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

    // MARK: - Finished

    private var done: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Token.Size.space4) {
                nameField
                VStack(spacing: Token.Size.space2) {
                    Button("Open PDF") { reading = true }
                        .buttonStyle(OutlineStyle(ink: Token.Palette.accent,
                                                  edge: Token.Palette.accent))
                        .accessibilityHint("Reads the PDF here in the app.")
                    // The whole export. The system's own sheet has Save to Files - and
                    // with it iCloud Drive, in his folder rather than one this app picked -
                    // plus AirDrop and Mail. Nothing is uploaded behind his back and no
                    // entitlement is needed: this is a tool, not an opinion about where
                    // his PDFs live.
                    ShareLink(item: shareCopy ?? scan.pdf) { Text("Share PDF") }
                        .buttonStyle(OutlineStyle(ink: Token.Palette.accent,
                                                  edge: Token.Palette.accent))
                    Button("Change pages") {
                        // Safe precisely because the PDF is derived: every page file is
                        // still there and rebuilding costs two seconds. Without it, a bad
                        // page spotted only after Make PDF would cost the whole scan.
                        try? FileManager.default.removeItem(at: scan.pdf)
                        refresh()
                    }
                    .buttonStyle(OutlineStyle(ink: Token.Palette.accent, edge: .clear))
                    .accessibilityHint("Goes back to the pages. The PDF is made again afterwards.")
                }
                // Gone whole once the photos are, never greyed out: there is nothing left
                // to press and nothing to announce.
                if photoBytes > 0 { photosBlock }
            }
            .padding(Token.Size.screenPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Token.Palette.bg)
        .tint(Token.Palette.accent)
        .navigationTitle("PDF ready")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $reading) { reader }
        // The copy that leaves carries the typed name; nothing is stored, so leaving the
        // scan and coming back empties the field again.
        .onChange(of: name) { nameTheCopy() }
        // Once, when this screen opens. It belongs to the branch and not to the Group's
        // own `.onAppear`, which is shared with the camera, the takeover, Adjust and the
        // pages - screens with no name field. The sheets need no guard of their own: the
        // reader and the share sheet present over this screen without removing it.
        .onAppear {
            guard !focusTaken else { return }
            focusTaken = true
            naming = true
        }
    }

    /// The name for the copy that leaves. On disk the file is always `scan.pdf`, so this
    /// is the one field in the app and it holds nothing: the share sheet reads it and it
    /// dies with the screen ([`../../user-flows.md`](../../user-flows.md) section 10).
    private var nameField: some View {
        VStack(alignment: .leading, spacing: Token.Size.space1) {
            Text("Name for the shared copy")
                .font(Token.Face.body(Token.Size.textMeta))
                .foregroundStyle(Token.Palette.textMuted)
            TextField("scan", text: $name)
                .font(Token.Face.body(Token.Size.textControl))
                .foregroundStyle(Token.Palette.text)
                .autocorrectionDisabled()
                .focused($naming)
                .padding(.horizontal, Token.Size.space2)
                .frame(minHeight: Token.Size.inputMinH)
                .overlay(RoundedRectangle(cornerRadius: Token.Size.radiusMd)
                    .stroke(Token.Palette.divider, lineWidth: Token.Size.hairlineW))
        }
        .accessibilityElement(children: .combine)
    }

    private var photosBlock: some View {
        VStack(alignment: .leading, spacing: Token.Size.space2) {
            Rectangle()
                .fill(Token.Palette.divider)
                .frame(height: Token.Size.hairlineW)
                .padding(.bottom, Token.Size.space2)
            Text("Photos")
                .font(Token.Face.heading(Token.Size.textH6))
                .tracking(Token.Size.textH6 * Token.Number.trackingH6)
                .textCase(.uppercase)
                .foregroundStyle(Token.Palette.textMuted)
            Button(photosLine) { confirmingPhotos = true }
                .buttonStyle(OutlineStyle(ink: Token.Palette.destructive,
                                          edge: Token.Palette.destructive))
            Text("The PDF stays. Deleted photos cannot be brought back.")
                .font(Token.Face.body(Token.Size.textMeta))
                .lineSpacing(Token.Size.textMeta * (Token.Number.leadingBody - 1))
                .foregroundStyle(Token.Palette.textMuted)
        }
        // Asked every time and never remembered: there is no settings screen, and doing
        // nothing is the other half of the choice, so no "keep the photos" button exists.
        .confirmationDialog(photosQuestion,
                            isPresented: $confirmingPhotos,
                            titleVisibility: .visible) {
            Button("Delete photos", role: .destructive) {
                scan.deletePhotos()
                refresh()
            }
            .accessibilityHint("Deletes this scan's photos.")
            Button("Cancel", role: .cancel) {}
                .accessibilityHint("Keeps the photos.")
        } message: {
            Text("The PDF stays. Without the photos the pages can no longer be adjusted.")
        }
    }

    /// "Delete the 40 photos (78 MB)" - the count and what they cost, both read off the
    /// files with everything else on this screen. The plural is the one `Scan.deleteBody`
    /// already carries.
    private var photosLine: String {
        "Delete the \(photos.count) photo\(photos.count == 1 ? "" : "s") (\(megabytes))"
    }

    private var photosQuestion: String {
        "Delete the \(photos.count) photo\(photos.count == 1 ? "" : "s")?"
    }

    /// "78 MB", in whatever the phone calls megabytes.
    private var megabytes: String {
        ByteCountFormatter.string(fromByteCount: Int64(photoBytes), countStyle: .file)
    }

    /// A hard link in the temporary directory carrying the typed name, so the share sheet
    /// offers `Rental contract.pdf` while the file on disk stays `scan.pdf`. A link rather
    /// than a copy: it costs no bytes and no time, and the same volume is the app's own
    /// container. Nothing is stored - the link is temporary and the field is empty at the
    /// next open.
    private func nameTheCopy() {
        if let old = shareCopy { try? FileManager.default.removeItem(at: old) }
        shareCopy = nil
        // A name is one path component, so the two characters that are not allowed in one
        // are the only thing taken out of what he typed.
        let wanted = name.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        guard !wanted.isEmpty else { return }
        let url = FileManager.default.temporaryDirectory.appending(path: wanted + ".pdf")
        try? FileManager.default.removeItem(at: url)
        try? FileManager.default.linkItem(at: scan.pdf, to: url)
        if FileManager.default.fileExists(atPath: url.path) { shareCopy = url }
    }

    /// The reader: the system's own PDF view under the system's own sheet. Nothing is
    /// copied and nothing leaves the app - and there is nothing else on it, no share, no
    /// print, no page count.
    private var reader: some View {
        NavigationStack {
            Reader(url: scan.pdf)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle("PDF")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { reading = false } label: { Image(systemName: "xmark") }
                            .accessibilityLabel("Close the PDF")
                    }
                }
        }
        .tint(Token.Palette.accent)
    }

    /// The finished PDF, read with the system's own PDF view. Nothing is copied and
    /// nothing leaves the app.
    private struct Reader: UIViewRepresentable {
        let url: URL

        func makeUIView(context: Context) -> PDFView {
            let view = PDFView()
            view.document = PDFDocument(url: url)
            view.autoScales = true
            return view
        }

        func updateUIView(_ view: PDFView, context: Context) {}
    }

    // MARK: - Reading the disk

    /// Reads the files again and hands SwiftUI something to redraw on. Called at every
    /// moment the files change, which is the only way this screen learns anything.
    private func refresh() {
        photos = scan.photos
        pages = scan.pages
        photoBytes = scan.photoBytes
        finished = FileManager.default.fileExists(atPath: scan.pdf.path)
        // The lowest-numbered page that has a state file answers for the scan.
        grey = Array(Set(photos + pages)).sorted().lazy.compactMap(scan.readState).first?.grey ?? false
        if !numbers.contains(showing) { showing = numbers.first ?? 0 }
    }
}

/// The done screen's buttons: outlined, never filled, the label in the heading face. One
/// style with two colours covers all four - `edge` is clear for Change pages, which is the
/// quiet one.
private struct OutlineStyle: ButtonStyle {
    let ink: Color
    let edge: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Token.Face.heading(Token.Size.textControl))
            .tracking(Token.Size.textControl * Token.Number.trackingHeading)
            .padding(.vertical, Token.Size.buttonPaddingY)
            .padding(.horizontal, Token.Size.buttonPaddingX)
            .frame(maxWidth: .infinity, minHeight: Token.Size.touchMin)
            .background(configuration.isPressed ? Token.Palette.pressAccent : .clear,
                        in: RoundedRectangle(cornerRadius: Token.Size.radiusMd))
            .overlay(RoundedRectangle(cornerRadius: Token.Size.radiusMd)
                .stroke(edge, lineWidth: Token.Size.hairlineW))
            .foregroundStyle(ink)
    }
}
