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
//  The run is made at the rung the scan is set to, and the switch on this screen is what
//  moves that rung. Both halves of one rule: what he looks at here is what every page of
//  the scan will be, so the preview may never be made at one rung while the pages are
//  written at another.
//
//  Every colour, size and step comes from `Token`. No number is written here.

import SwiftUI

struct FirstPageCheck: View {
    let photo: URL
    /// The page the photo landed on, in the words the camera's counter uses.
    let number: Int
    /// How small the pages of this scan are written, as `quality.txt` says it. The picture
    /// below is made at this rung, and the switch hands a new one out - `ScanFlow` writes
    /// the file and remakes the page, like every other file move.
    let quality: Engine.PageQuality
    var onQuality: (Engine.PageQuality) -> Void
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
    /// A run is out. The picture on screen is then the page the *other* rung made, so the
    /// screen has to say so - previewing one thing while writing another is the whole
    /// failure this screen exists to prevent, and a switch that jumps while the picture
    /// stays put is exactly that failure with no sentence under it.
    @State private var making = false

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
            // Only beside a page there is something to judge, exactly like the promise
            // above it: the switch asks "does this look good enough", and over a refusal
            // there is nothing to answer about. The pages screen carries the same switch
            // for the scan that gets there anyway.
            if failure == nil { smaller }
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
        // Keyed on the rung: the switch is what makes the page again, and the screen
        // never shows a page made at a rung the switch is not on.
        .task(id: quality) { await showThePage() }
        // The one tap the camera stand-in cannot make from its own file, because this
        // screen is not the camera: **Scan 1 page**, for the one page scan
        // ([`FakeShoot.swift`](./FakeShoot.swift)).
        .task { if FakeShoot.onePageWanted { onScanIt() } }
        // The scratch file is this screen's, and it goes with the screen.
        .onDisappear {
            if let preview { try? FileManager.default.removeItem(at: preview) }
        }
    }

    /// The page size setting, on the one screen where he can see what it costs. On, the
    /// default, is the smaller page; off is full quality, for the scan where this page
    /// does not look good enough.
    ///
    /// A switch and not a picker, because there are two rungs and a switch is the honest
    /// control for two - and the design system has neither a picker nor a segmented
    /// control ([`../../client-guide-design-system/components.md`](../../client-guide-design-system/components.md)).
    /// Nothing is written here: the value goes out and the new picture comes back in.
    private var smaller: some View {
        VStack(alignment: .leading, spacing: Token.Size.space1) {
            Toggle("Smaller pages", isOn: Binding(get: { quality == .small },
                                                  set: { onQuality($0 ? .small : .original) }))
                .toggleStyle(SettingStyle())
                // Dead while a run is out, so a second flip cannot stack a second run on the
                // first. The sentence under it says why, rather than a control going quiet
                // with no reason given.
                .disabled(making)
                .accessibilityHint("Writes every page of this scan at about half the file size.")
            // While the run is out, the picture above is still the page the other rung
            // made, and this line is the only thing that can say so. No spinner: this app
            // says things in sentences.
            Text(making
                 ? "Making this page again…"
                 : "About half the file size. Switch it off if this page looks too soft.")
                .font(Token.Face.body(Token.Size.textMeta))
                .lineSpacing(Token.Size.textMeta * (Token.Number.leadingBody - 1))
                .foregroundStyle(Token.Palette.textMuted)
        }
    }

    /// How long a flip waits before the engine is asked, in milliseconds. The Adjust
    /// screen's own preview carries the same number for the same reason; 300 ms is a tap
    /// changed its mind about, not a tap meant.
    private static let settle = 300

    /// One engine run, exactly the one the drain would make on this photo at this rung,
    /// into a file outside the scan folder. A refusal is the engine's sentence unchanged.
    ///
    /// Re-run by the switch, because `task(id:)` is keyed on the rung. The page that is up
    /// stays up until the new one has landed and is deleted only then, the way the Adjust
    /// screen's preview does it: a superseded run can never take the picture that is up,
    /// and there is never a moment with nothing to judge.
    private func showThePage() async {
        // The same settle the Adjust screen's preview waits out, for the same reason: a
        // flip flipped back costs one engine run, not one per flip. Without it every tap
        // starts a run that nothing stops, and the one-run-at-a-time rule the memory
        // budget rests on is gone ([`../AGENTS.md`](../AGENTS.md)).
        try? await Task.sleep(for: .milliseconds(Self.settle))
        guard !Task.isCancelled else { return }

        making = true
        defer { making = false }

        let scratch = FileManager.default.temporaryDirectory
            .appendingPathComponent("first-page-\(UUID().uuidString).jpg")
        let source = photo
        let rung = quality
        do {
            try await Task.detached(priority: .userInitiated) {
                try Engine.scanPage(source, into: scratch, rung)
            }.value
            // A flip while this run was out cancelled this task, and the run it started
            // is the one that tells the truth now.
            guard !Task.isCancelled else {
                try? FileManager.default.removeItem(at: scratch)
                return
            }
            let stale = preview
            preview = scratch
            failure = nil
            if let stale { try? FileManager.default.removeItem(at: stale) }
        } catch {
            try? FileManager.default.removeItem(at: scratch)
            guard !Task.isCancelled else { return }
            failure = error.localizedDescription
        }
    }
}
