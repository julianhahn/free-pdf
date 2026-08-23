//  AdjustView.swift - the six tools, one at a time, on one page.
//
//  Reached from the Page menu only. Every change shows what it would do: a moment after
//  a value moves, the picture becomes a real engine run of the current values into a
//  scratch file outside the scan folder, so what is on screen is what Apply would write.
//  Only Apply writes a page - it re-runs the recipe from `photo/NNNN.jpg` with the values
//  below and replaces the page file whole ([`../../../user-flows.md`](../../../user-flows.md)
//  section 7). Julian reversed the old "no live preview" rule on 2026-08-16.
//
//  The engine seeds a page once - `freepdf_suggest_adjustments`, what it would have done
//  by itself - and after that the controls open on what was last applied, out of the
//  page's `state/NNNN.txt`. "Back to the suggestion" puts the engine's own answer back on
//  one tool, which is the only way back to it. The exception is what the engine measures
//  for itself - the straightening angle and the two tone points - which only mean something
//  against one set of corners, so moving the sheet measures them again and replaces what is
//  showing, whether the engine put it there or the user did. A photo the engine cannot read
//  means the page cannot be adjusted at all, and the screen says so instead of opening on
//  zeros.
//
//  Like the pages, this screen never lists a directory: the numbers come in from
//  `ScanFlow` and the two files it reads are named, not searched for.
//
//  Every colour, size and step comes from `Token`. No number is written here beyond the
//  ranges the engine itself sets (-10…10 degrees, 0…20 radius, 0…3 quarter turns).
//
//  The screen is four files. This one holds what comes in, every piece of view state and
//  the body; [`AdjustPicture.swift`](./AdjustPicture.swift) draws the picture and the
//  handles over it, [`AdjustTools.swift`](./AdjustTools.swift) paints the six tools'
//  controls, and [`AdjustValues.swift`](./AdjustValues.swift) is everything said to the
//  engine. What ties the four together is [`AGENTS.md`](./AGENTS.md).

import SwiftUI

struct AdjustView: View {
    let photo: URL
    let page: URL
    /// The page as the user counts it - what the title says.
    let position: Int
    /// The scan's Grey switch as the files say it, carried through: applying without it
    /// would quietly un-grey the page.
    let grey: Bool
    /// How small the scan's pages are written, carried through for the same reason: the
    /// preview below is a real engine run, and one made at another rung would show a page
    /// Apply is not going to write. `ScanFlow` writes the page, and it uses this rung too.
    let quality: Engine.PageQuality
    /// What the user last asked for on this page, read out of `state/NNNN.txt` by
    /// `ScanFlow`. `nil` the first time a page is adjusted, and then the engine's
    /// suggestion is what the controls open on.
    let stored: Engine.Adjustments?
    /// True while one page is being written. Nothing moves; Apply says so and Cancel is
    /// refused, because stopping halfway would leave a half-written page.
    let applying: Bool
    let message: String?
    var onCancel: () -> Void
    var onApply: (Engine.Adjustments, Bool) -> Void

    enum Tool: String, CaseIterable {
        case edges = "Edges", straighten = "Straighten", brightness = "Brightness"
        case sharpen = "Sharpen", crop = "Crop", turn = "Turn"
    }

    @State var tool: Tool = .edges
    /// What the engine would have done by itself, and what every control opens on. `nil`
    /// until it arrives; `refusal` holds the engine's sentence if it never does, and then
    /// the page cannot be adjusted at all - a photo that cannot be read is the one thing
    /// this screen needs.
    @State var suggestion: Engine.Suggestion?
    @State var refusal: String?
    /// The four sheet corners and the four crop corners, each as a fraction of the
    /// picture. Fractions rather than pixels because the picture is laid out by the
    /// screen and the two files have their own sizes.
    @State var sheet = Self.wholePicture
    @State var box = Self.wholePicture
    @State var pullFlat = false
    @State var angle = 0.0
    @State var black = 0.0
    @State var white = 100.0
    @State var tones = false
    @State var sharpen = 0.6
    @State var turns = 0
    @State private var allPages = false
    /// What the two files measure, read once. The photo because the engine takes the
    /// sheet corners in its pixels; the page because a handle is only the fraction it
    /// looks like when the block it is dragged in is the shape of the picture inside it.
    @State var photoSize = CGSize.zero
    @State var pageSize = CGSize.zero
    /// The last good preview - a page the engine really wrote, from the current values,
    /// into a file that is not `photo/`, `page/`, `state/` or `scan.pdf`. `nil` until the
    /// first run lands, and then the picture is this instead of the page on disk.
    @State var previewFile: URL?
    /// What the engine said about a preview that failed, in its own sentence. The last
    /// good picture stays up under it.
    @State var previewFailure: String?
    /// Which corner is under the finger right now, and so where the magnifier is. Set the
    /// moment a finger lands on a corner, not once it has moved. `nil` when no corner is
    /// touched, which is when there is no magnifier at all.
    @State var held: Int?
    /// Which corner was grabbed and where it sat when the finger landed on it. The drag
    /// moves the corner from there by how far the finger has travelled, so a touch that
    /// lands off centre - anywhere in the 44 point target - does not teleport the corner
    /// under the fingertip.
    ///
    /// The corner's own number is stored with the point because a second finger on a second
    /// handle would otherwise read the first one's starting point and throw its corner
    /// across the picture. Two fingers on two handles is a thing a hand does by accident.
    @State var grabbed: (corner: Int, at: CGPoint)?
    /// The sheet the numbers on screen were measured against.
    ///
    /// The angle and the two levels points only mean something against one set of
    /// corners, because the engine reads the tilt and the tone points off the picture
    /// *after* it has been pulled flat. When this no longer matches the corners on
    /// screen the engine is asked again and its numbers replace the ones showing, hand
    /// set or not: a number set against corners the user then moved describes an image
    /// the app no longer makes (Julian, 2026-08-16). `nil` means they belong to no sheet
    /// on screen, so the next settle measures one.
    @State var measuredFor: ([CGPoint], Bool)?

    /// True while the numbers on screen belong to a sheet that is no longer on screen.
    /// It gates the re-measure and it holds Apply, so a tap straight after a corner
    /// drag cannot write the numbers the drag just made wrong.
    var measuredForAnotherSheet: Bool {
        measuredFor.map { $0.0 != sheet || $0.1 != pullFlat } ?? true
    }

    static let wholePicture = [CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 0),
                                       CGPoint(x: 1, y: 1), CGPoint(x: 0, y: 1)]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Token.Size.space4) {
                    if let said = refusal ?? message ?? previewFailure { ErrorLine(sentence: said) }
                    picture
                    if tool == .edges, let suggestion {
                        if suggestion.runsOffThePicture {
                            ErrorLine(sentence: "The page runs off the frame. Move back and photograph it again.")
                        }
                        if suggestion.fillsTheWholePhoto {
                            note("The sheet fills the whole photo, so there is nothing to cut away.")
                        }
                    }
                    strip
                    controls
                        // Nothing can be moved before the engine has said where it would
                        // put it, or the first drag would be against a zero.
                        .disabled(suggestion == nil)
                }
                .padding(Token.Size.screenPadding)
            }
            Rectangle()
                .fill(Token.Palette.divider)
                .frame(height: Token.Size.hairlineW)
            footer
        }
        .background(Token.Palette.bg)
        .tint(Token.Palette.accent)
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { bar }
        .task {
            photoSize = Self.pixels(photo)
            pageSize = Self.pixels(page)
            // After the size, never before: the corners come back in photo pixels and
            // are only a fraction of the picture once the photo has been measured.
            let file = photo
            do {
                suggestion = try await Task.detached(priority: .userInitiated) {
                    try Engine.suggest(file)
                }.value
                // The suggestion is asked for on every open whatever the state file
                // says: its two notes are about the photo, not about the values.
                seed(nil, from: stored)
            } catch {
                refusal = error.localizedDescription
            }
        }
        // Every value change is a new run and cancels the one before it: `task(id:)` is
        // the one-at-a-time rule, and the sleep is what makes a dragged slider one run
        // rather than fifty.
        .task(id: previewValues) { await showWhatItWouldDo() }
        .onDisappear {
            if let previewFile { try? FileManager.default.removeItem(at: previewFile) }
        }
    }

    // MARK: - The bar

    @ToolbarContentBuilder
    private var bar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Cancel") { onCancel() }
                .disabled(applying)
                .accessibilityHint("Leaves the page as it is.")
        }
        ToolbarItem(placement: .principal) {
            Text("Adjust page \(position)")
                .font(Token.Face.heading(Token.Size.textH5))
                .tracking(Token.Size.textH5 * Token.Number.trackingHeading)
                .monospacedDigit()
                .foregroundStyle(Token.Palette.text)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button(applying ? "Applying…" : "Apply") { onApply(values, allPages) }
                .disabled(applying || suggestion == nil || measuredForAnotherSheet)
                .accessibilityHint("Rewrites this page from its photo.")
        }
    }

    // MARK: - The footer

    private var footer: some View {
        toggle("Apply to all pages", $allPages,
               hint: "Rewrites every page of this scan from its own photo.")
            .padding(Token.Size.screenPadding)
    }
}
