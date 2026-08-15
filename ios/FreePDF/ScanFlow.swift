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
                bar
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
    private var bar: some View {
        Rectangle()
            .fill(Token.Palette.dividerStrong)
            .frame(height: Token.Size.progressBarH)
            .overlay {
                Rectangle()
                    .fill(Token.Palette.accent)
                    .scaleEffect(x: CGFloat(atPhoto) / CGFloat(max(photos.count, 1)),
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
            } catch {
                // One photo the engine will not take must not wedge the scan: without
                // this the loop would pick the same number for ever.
                failed.insert(number)
                message = error.localizedDescription
            }
            refresh()
        }
    }

    // MARK: - Checking the pages

    private var check: some View {
        PagesView(scan: scan,
                  numbers: numbers,
                  failed: failed,
                  complete: unscanned.isEmpty,
                  making: making,
                  message: message,
                  showing: $showing,
                  onRetake: retake,
                  onDelete: deletePage,
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
        VStack(spacing: 20) {
            Text("PDF ready").font(.title2)
            Button("Open PDF") { reading = true }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            // The whole export. The system's own sheet has Save to Files - and with it
            // iCloud Drive, in his folder rather than one this app picked - plus AirDrop
            // and Mail. Nothing is uploaded behind his back and no entitlement is needed:
            // this is a tool, not an opinion about where his PDFs live.
            ShareLink(item: scan.pdf) { Text("Share PDF") }
            Button("Change pages") {
                // Safe precisely because the PDF is derived: every page file is still
                // there and rebuilding costs two seconds. Without it, a bad page spotted
                // only after Make PDF would cost the whole scan.
                try? FileManager.default.removeItem(at: scan.pdf)
                refresh()
            }
            if photoBytes > 0 {
                Button("Delete the \(photos.count) photos (\(megabytes))", role: .destructive) {
                    scan.deletePhotos()
                    refresh()
                }
                .padding(.top)
                Text("The PDF stays. Deleted photos cannot be brought back.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .navigationTitle("PDF ready")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $reading) {
            Reader(url: scan.pdf)
        }
    }

    /// "78 MB", in whatever the phone calls megabytes.
    private var megabytes: String {
        ByteCountFormatter.string(fromByteCount: Int64(photoBytes), countStyle: .file)
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
        if !numbers.contains(showing) { showing = numbers.first ?? 0 }
    }
}
