//  FirstPageCheck.swift - the one look at a page before the rest of the scan is shot blind.
//
//  Shown once per scan, after the first photo lands and before the second shot, and never
//  again in that scan (Julian, 2026-08-17): nobody knows in advance how long a scan is, so
//  the earliest moment is the only good one to find out that the desk is too dark. Two ways
//  out, and no third: shoot this page again, or photograph the rest in one go.
//
//  The picture is a real engine run of the photo into a scratch file under the system's
//  temporary directory - never `photo/`, `page/`, `state/` or `scan.pdf`, so `sweep()`
//  never sees it - for the same reason the Adjust screen runs one: a picture drawn to look
//  about right is a promise the app cannot keep. The real page is still written by the
//  drain and by nothing else.
//
//  It shows the photo beside the page it becomes, in that order, and that pair is taught
//  here once so the viewfinder's corner thumbnail needs no caption
//  ([`CameraView.swift`](./CameraView.swift)).
//
//  Every colour, size and step comes from `Token`. No number is written here.

import SwiftUI

struct FirstPageCheck: View {
    let photo: URL
    /// The page the photo landed on, in the words the camera's counter uses.
    let number: Int
    var onRetake: () -> Void
    /// The scan is one page and that page is this one, so it is finished from here. Julian
    /// on 2026-08-18, on his own phone: without it a single page scan cannot be finished
    /// at all, because both other ways out lead back to the camera and this screen hides
    /// the footer that scans. Two ways out was the design; three is what a receipt needs.
    var onScanIt: () -> Void
    var onCarryOn: () -> Void

    /// The page the engine really wrote from this photo, into a scratch file. `nil` until
    /// the run lands.
    @State private var preview: URL?
    /// The engine's own sentence if it refused the photo. Both controls still work then -
    /// a page the engine refused is a reason to retake, not a trap.
    @State private var failure: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Token.Size.space4) {
            if let failure { ErrorLine(sentence: failure) }
            // Only when there is a page to look at: the promise over an empty slot reads
            // as a second failure.
            if failure == nil {
                Text("This is how your pages will come out.")
                    .font(Token.Face.heading(Token.Size.textH4))
                    .tracking(Token.Size.textH4 * Token.Number.trackingHeading)
                    .foregroundStyle(Token.Palette.text)
            }
            // The photo small and the page large, in that order: the page is what he is
            // judging. One column of three for the photo, so no width is invented here.
            HStack(alignment: .top, spacing: Token.Size.space3) {
                PageImage(url: photo, maxPixels: 400)
                    .containerRelativeFrame(.horizontal, count: 3, span: 1,
                                            spacing: Token.Size.space3)
                if let preview {
                    PageImage(url: preview)
                        .frame(maxWidth: .infinity)
                }
            }
            Text("Your photo becomes this page.")
                .font(Token.Face.body(Token.Size.textSub))
                .lineSpacing(Token.Size.textSub * (Token.Number.leadingBody - 1))
                .foregroundStyle(Token.Palette.text)
            Text("Not right? More light or a plainer surface fixes most of it.")
                .font(Token.Face.body(Token.Size.textMeta))
                .lineSpacing(Token.Size.textMeta * (Token.Number.leadingBody - 1))
                .foregroundStyle(Token.Palette.textMuted)
            Spacer(minLength: 0)
            Button("Scan this page again") { onRetake() }
                .buttonStyle(GhostStyle())
                .accessibilityHint("Photographs page \(number) again.")
            // A one page document is finished here. The words are the camera footer's own
            // for one page, because it is the same action.
            Button("Scan \(pageCount(1))") { onScanIt() }
                .buttonStyle(GhostStyle())
            // The normal answer, so it is the one slab on the screen.
            Button("Photograph the rest") { onCarryOn() }
                .buttonStyle(PrimaryStyle(wide: true))
        }
        .padding(Token.Size.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Token.Palette.bg)
        .tint(Token.Palette.accent)
        .navigationTitle("Page \(number)")
        .navigationBarTitleDisplayMode(.inline)
        .task { await showThePage() }
        // The one tap the camera stand-in cannot make from its own file, because this
        // screen is not the camera: **Scan 1 page**, for the one page scan
        // ([`FakeShoot.swift`](./FakeShoot.swift)).
        .task { if FakeShoot.onePageWanted { onScanIt() } }
        // The scratch file is this screen's, and it goes with the screen.
        .onDisappear {
            if let preview { try? FileManager.default.removeItem(at: preview) }
        }
    }

    /// One engine run, exactly the one the drain would make on this photo, into a file
    /// outside the scan folder. A refusal is the engine's sentence unchanged.
    private func showThePage() async {
        let scratch = FileManager.default.temporaryDirectory
            .appendingPathComponent("first-page-\(UUID().uuidString).jpg")
        let source = photo
        do {
            try await Task.detached(priority: .userInitiated) {
                try Engine.scanPage(source, into: scratch)
            }.value
            preview = scratch
            failure = nil
        } catch {
            try? FileManager.default.removeItem(at: scratch)
            failure = error.localizedDescription
        }
    }
}
