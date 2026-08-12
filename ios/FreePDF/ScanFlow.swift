//  ScanFlow.swift - one scan, from the first photo to the finished PDF.
//
//  One screen that switches on `scan.state`, and that state is read from the files
//  every time. Nothing here stores where the user got to, so a kill cannot leave this
//  screen believing something the disk disagrees with ([`AGENTS.md`](../AGENTS.md)).

import ImageIO
import PDFKit
import SwiftUI
import UIKit

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
                FakeShoot(scan: scan, slot: slot) {
                    slot = nil
                    shooting = false
                    refresh()
                }
            } else if scan.state == .done {
                done
            } else if scan.unscanned.allSatisfy(failed.contains) {
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
        VStack(spacing: 16) {
            ProgressView(value: Double(pages.count), total: Double(max(photos.count, 1)))
            Text("Scanning page \(current) of \(photos.count)")
            Text("You can close the app. It carries on from here.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            if let message {
                Text(message).font(.footnote).foregroundStyle(.red)
            }
        }
        .padding()
        .navigationTitle(scan.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await drain() }
    }

    /// The page being worked on, read from the files rather than counted, so a gap or a
    /// page that was deleted cannot make the line say a number that is not being done.
    private var current: Int {
        scan.unscanned.first { !failed.contains($0) } ?? photos.count
    }

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
    private func drain() async {
        while !Task.isCancelled,
              let number = scan.unscanned.first(where: { !failed.contains($0) }) {
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
        VStack {
            TabView(selection: $showing) {
                ForEach(numbers, id: \.self) { number in
                    page(number).tag(number)
                }
            }
            .tabViewStyle(.page)

            if let message {
                Text(message).font(.footnote).foregroundStyle(.red)
            }
            // Hidden until every photo has a page, so a scan can never lose a page to a
            // PDF the user thought was whole.
            if scan.unscanned.isEmpty {
                Button(making ? "Making the PDF…" : "Make PDF") {
                    Task { await makePDF() }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(making)
            }
        }
        .navigationTitle("Page \(position) of \(numbers.count)")
        .navigationBarTitleDisplayMode(.inline)
        // The second of the two lines the camera stand-in reaches out of its own file
        // with: it presses Make PDF for the check. Deleting `FakeShoot.swift` in
        // milestone 5 makes the compiler point straight at this line.
        // The same condition the button carries, or a refused page would be left out of
        // a PDF nobody asked for.
        .task { if FakeShoot.pagesWanted != nil, scan.unscanned.isEmpty, !making { await makePDF() } }
        .toolbar {
            Menu("Page", systemImage: "ellipsis.circle") {
                Button("Retake this page") { retake(showing) }
                Button("Delete page", role: .destructive) { deletePage(showing) }
            }
        }
    }

    /// Every page number this scan has, whether it got as far as a page file or not.
    /// A photo the engine refused has to be on this carousel too - it is the only place
    /// the user can do something about it.
    private var numbers: [Int] { Array(Set(photos + pages)).sorted() }

    /// Where in the carousel he is. Counted, not the page number: a page deleted in the
    /// middle keeps its gap for ever, and "Page 7 of 6" would be the result.
    private var position: Int { (numbers.firstIndex(of: showing) ?? 0) + 1 }

    @ViewBuilder
    private func page(_ number: Int) -> some View {
        if let image = Self.thumbnail(scan.pageURL(number)) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            ContentUnavailableView("This page could not be scanned.",
                                   systemImage: "exclamationmark.triangle")
        }
    }

    /// One page, decoded small enough to look at.
    ///
    /// A full page decodes to about 34 MB and a paging carousel keeps roughly three
    /// alive; at 1600 px they are about 7 MB each. 400 px would be too soft to see
    /// whether the small print survived, which is the only reason this screen exists.
    ///
    /// ponytail: decoded while the view is being drawn, so paging costs about 40 ms of
    /// main thread per page. Move it into a `.task` with a `@State` image if that ever
    /// feels slow.
    private static func thumbnail(_ url: URL) -> UIImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 1600,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        else { return nil }
        return UIImage(cgImage: image)
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
            Button("Change pages") {
                // Safe precisely because the PDF is derived: every page file is still
                // there and rebuilding costs two seconds. Without it, a bad page spotted
                // only after Make PDF would cost the whole scan.
                try? FileManager.default.removeItem(at: scan.pdf)
                refresh()
            }
        }
        .padding()
        .navigationTitle("PDF ready")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $reading) {
            Reader(url: scan.pdf)
        }
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
        if !numbers.contains(showing) { showing = numbers.first ?? 0 }
    }
}
