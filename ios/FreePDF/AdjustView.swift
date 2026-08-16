//  AdjustView.swift - the six tools, one at a time, on one page.
//
//  Reached from the Page menu only. Every change shows what it would do: a moment after
//  a value moves, the picture becomes a real engine run of the current values into a
//  scratch file outside the scan folder, so what is on screen is what Apply would write.
//  Only Apply writes a page - it re-runs the recipe from `photo/NNNN.jpg` with the values
//  below and replaces the page file whole ([`../../user-flows.md`](../../user-flows.md)
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

import ImageIO
import SwiftUI

struct AdjustView: View {
    let photo: URL
    let page: URL
    /// The page as the user counts it - what the title says.
    let position: Int
    /// The scan's Grey switch as the files say it, carried through: applying without it
    /// would quietly un-grey the page.
    let grey: Bool
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

    @State private var tool: Tool = .edges
    /// What the engine would have done by itself, and what every control opens on. `nil`
    /// until it arrives; `refusal` holds the engine's sentence if it never does, and then
    /// the page cannot be adjusted at all - a photo that cannot be read is the one thing
    /// this screen needs.
    @State private var suggestion: Engine.Suggestion?
    @State private var refusal: String?
    /// The four sheet corners and the four crop corners, each as a fraction of the
    /// picture. Fractions rather than pixels because the picture is laid out by the
    /// screen and the two files have their own sizes.
    @State private var sheet = Self.wholePicture
    @State private var box = Self.wholePicture
    @State private var pullFlat = false
    @State private var angle = 0.0
    @State private var black = 0.0
    @State private var white = 100.0
    @State private var tones = false
    @State private var sharpen = 0.6
    @State private var turns = 0
    @State private var allPages = false
    /// What the two files measure, read once. The photo because the engine takes the
    /// sheet corners in its pixels; the page because a handle is only the fraction it
    /// looks like when the block it is dragged in is the shape of the picture inside it.
    @State private var photoSize = CGSize.zero
    @State private var pageSize = CGSize.zero
    /// The last good preview - a page the engine really wrote, from the current values,
    /// into a file that is not `photo/`, `page/`, `state/` or `scan.pdf`. `nil` until the
    /// first run lands, and then the picture is this instead of the page on disk.
    @State private var previewFile: URL?
    /// What the engine said about a preview that failed, in its own sentence. The last
    /// good picture stays up under it.
    @State private var previewFailure: String?
    /// Which corner is under the finger right now, and so where the magnifier is. `nil`
    /// between drags, which is when there is no magnifier at all.
    @State private var held: Int?
    /// The sheet the numbers on screen were measured against.
    ///
    /// The angle and the two levels points only mean something against one set of
    /// corners, because the engine reads the tilt and the tone points off the picture
    /// *after* it has been pulled flat. When this no longer matches the corners on
    /// screen the engine is asked again and its numbers replace the ones showing, hand
    /// set or not: a number set against corners the user then moved describes an image
    /// the app no longer makes (Julian, 2026-08-16). `nil` means they belong to no sheet
    /// on screen, so the next settle measures one.
    @State private var measuredFor: ([CGPoint], Bool)?

    /// True while the numbers on screen belong to a sheet that is no longer on screen.
    /// It gates the re-measure and it holds Apply, so a tap straight after a corner
    /// drag cannot write the numbers the drag just made wrong.
    private var measuredForAnotherSheet: Bool {
        measuredFor.map { $0.0 != sheet || $0.1 != pullFlat } ?? true
    }

    private static let wholePicture = [CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 0),
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

    // MARK: - What it would do

    /// The picture becomes the page the current values would produce.
    ///
    /// It is a real run of the engine's recipe, not an approximation drawn here, so what
    /// is on screen is what Apply writes. It goes to its own file under the system's
    /// temporary directory - never `photo/`, `page/`, `state/` or `scan.pdf`, so `sweep()`
    /// never sees it and a kill mid-run leaves nothing new in the scan folder. Each run
    /// writes its own file and the one before it is deleted only once the new one has
    /// landed, so a superseded run can never take the picture that is up.
    private func showWhatItWouldDo() async {
        guard suggestion != nil else { return }
        try? await Task.sleep(for: .milliseconds(Self.settle))
        guard !Task.isCancelled else { return }
        if measuredForAnotherSheet {
            let before = previewValues
            await measureAgain()
            // A new number re-keys `task(id:)` and that run draws the picture. If it came
            // back the same number nothing was re-keyed, so this run draws it instead. A
            // settled drag costs two engine passes at most, never one per frame.
            if previewValues != before { return }
        }
        let asked = previewValues, source = photo
        let scratch = FileManager.default.temporaryDirectory
            .appendingPathComponent("adjust-preview-\(UUID().uuidString).jpg")
        do {
            try await Task.detached(priority: .userInitiated) {
                try Engine.adjustPage(source, into: scratch, asked)
            }.value
            guard !Task.isCancelled else {
                try? FileManager.default.removeItem(at: scratch)
                return
            }
            let stale = previewFile
            previewFile = scratch
            // The preview carries the turn and the cut, so it is the file the block's
            // shape now comes from.
            pageSize = Self.pixels(scratch)
            previewFailure = nil
            if let stale { try? FileManager.default.removeItem(at: stale) }
        } catch {
            try? FileManager.default.removeItem(at: scratch)
            // The engine's sentence, unchanged, exactly as Apply shows it. The last good
            // picture stays up.
            previewFailure = error.localizedDescription
        }
    }

    /// What the engine measures for itself, measured again against the corners now on
    /// screen: the straightening angle and the two tone points.
    ///
    /// Julian found this on a real phone: the common case is that find-page cut his page
    /// off, so he opens Adjust on Edges, puts the four crosshairs on the real corners and
    /// taps Apply without ever seeing another tab. Apply has to give him the page the
    /// automatic run would have made if find-page had found those corners itself - so
    /// every number the engine measures for itself is measured again. The angle was read
    /// off the engine's own frame; the black and white points were read off the pixels
    /// inside that frame, which caught the desk. Both describe a picture the app no
    /// longer makes.
    ///
    /// This replaces the numbers whether the engine put them there or the user nudged
    /// them (Julian, 2026-08-16). A number set by hand against corners he then moved is
    /// not his any more. From here he is back to nudging.
    private func measureAgain() async {
        let source = photo, asked = values
        do {
            let fresh = try await Task.detached(priority: .userInitiated) {
                try Engine.suggest(source, for: asked)
            }.value
            guard !Task.isCancelled else { return }
            // The whole answer, not a piece of it. Asked about the user's sheet the
            // engine hands back its own found corners, its own switch and its three
            // notes unchanged - only the angle, the two tone points and the tones
            // switch are measured against what it was given. So this is still the
            // engine's own answer, now about the sheet on screen, and "Back to the
            // suggestion" reads exactly the same corners it read before.
            suggestion = fresh
            angle = Double(fresh.values.straightenDegrees)
            black = Self.percent(fresh.values.black)
            white = Self.percent(fresh.values.white)
            tones = fresh.values.adjustTheTones
        } catch {
            // The engine's sentence, exactly as a failed preview shows it, last good
            // picture up.
            previewFailure = error.localizedDescription
        }
        // Set whether it worked or not: a photo the engine refuses must not leave Apply
        // dead forever, and Apply would show the same sentence anyway.
        measuredFor = (sheet, pullFlat)
    }

    /// How long a value has to sit still before the engine is asked, in milliseconds. A
    /// run costs about as much as one scan, so a drag would otherwise queue one per frame.
    private static let settle = 300

    /// What the preview runs - the values Apply would send, composed onto what is stored
    /// exactly as `ScanFlow` composes them.
    ///
    /// Crop is the one difference, and it is not a second code path: the box the user is
    /// dragging is a fraction of the picture **before** the cut, so while that tool is up
    /// the preview shows that picture, which is the page with the stored cut and nothing
    /// further. Every other tool sees the finished page.
    private var previewValues: Engine.Adjustments {
        var mine = values
        if tool == .crop {
            (mine.cropX, mine.cropY, mine.cropWidth, mine.cropHeight) = (0, 0, 0, 0)
        }
        return ScanFlow.composed(mine, onto: stored)
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

    // MARK: - The page

    /// The page as it stands now, with the handles of the active tool over it. The block
    /// keeps its own shape, so a handle sits where it is dragged.
    ///
    /// Edges shows the **photo** instead: its handles are the sheet's corners, which the
    /// engine takes in photo pixels, and drawing them over the page would put them in a
    /// space nothing maps back to. Crop stays on the page, because the fraction the user
    /// drags there is the fraction the engine cuts.
    private var picture: some View {
        GeometryReader { geo in
            // The engine turns the picture before it cuts, so the page is drawn turned as
            // well - otherwise a crop box dragged onto the bottom is cut off the side.
            let upright = quarter % 2 == 0
            let inner = upright ? geo.size : CGSize(width: geo.size.height, height: geo.size.width)
            PageImage(url: drawn)
                .overlay {
                    switch tool {
                    case .edges: handles($sheet, colour: Token.Palette.accent)
                    case .crop: handles($box, colour: Token.Palette.accent)
                    default: EmptyView()
                    }
                }
                .frame(width: inner.width, height: inner.height)
                .rotationEffect(.degrees(Double(quarter) * 90))
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .aspectRatio(aspect, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .background(Token.Palette.paper, in: RoundedRectangle(cornerRadius: Token.Size.radiusLg))
    }

    /// The file the picture draws, and the one the magnifier draws again: the photo under
    /// Edges, because its corners are photo pixels, and otherwise what the values would
    /// make of the page, falling back to the page on disk until the first preview lands.
    private var drawn: URL {
        tool == .edges ? photo : (previewFile ?? page)
    }

    /// How far the picture on screen is turned - only the turns added since the last
    /// Apply, because the page file already carries the stored ones. Edges draws the
    /// photo, which the turn does not touch, and a preview was turned by the engine
    /// itself, so neither is turned again here.
    private var quarter: Int {
        tool == .edges || previewFile != nil
            ? 0 : (turns - Int(stored?.quarterTurns ?? 0) + 4) % 4
    }

    /// The shape of the picture on screen, measured from the file that is drawn. It has
    /// to be the real one: `PageImage` fits the picture inside this block, so any other
    /// shape leaves bars the handles could be parked on, and the fraction on screen
    /// would not be the fraction the engine is sent. The token is only the fallback for
    /// a file that could not be measured.
    private var aspect: CGFloat {
        let file = tool == .edges ? photoSize : pageSize
        guard file.height > 0 else { return Token.Number.pageRatio }
        return quarter % 2 == 0 ? file.width / file.height : file.height / file.width
    }

    /// Four draggable corners over the picture, and while one is held, the magnifier that
    /// makes it aimable.
    private func handles(_ points: Binding<[CGPoint]>, colour: Color) -> some View {
        GeometryReader { geo in
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    // While a corner is held, the other three stop being painted - the
                    // screen is tight enough. Their targets, labels and hit testing stay.
                    .stroke(held == nil || held == i ? colour : Color.clear,
                            lineWidth: Token.Size.ruleStrong)
                    .frame(width: Token.Size.touchMin, height: Token.Size.touchMin)
                    .contentShape(Circle())
                    .position(x: points.wrappedValue[i].x * geo.size.width,
                              y: points.wrappedValue[i].y * geo.size.height)
                    .gesture(DragGesture().onChanged { move in
                        held = i
                        points.wrappedValue[i] = CGPoint(x: move.location.x / geo.size.width,
                                                         y: move.location.y / geo.size.height)
                    }.onEnded { _ in held = nil })
                    .accessibilityLabel(Self.cornerNames[i])
                    .accessibilityHint("Swipe up or down to move it.")
            }
            // Over the handles, because it is the thing being read while one is held.
            if let held, refusal == nil, suggestion != nil {
                magnifier(at: points.wrappedValue[held], in: geo.size)
            }
        }
    }

    /// The picture under the held corner, blown up on the far side of the picture from
    /// the finger, with a crosshair on the corner itself - a handle sits under the
    /// fingertip that drags it, so without this the user aims at what he cannot see. One
    /// accent rule runs level from under the fingertip into the disc and stops at the rim,
    /// the way a leader line in a printed diagram says "this circle is that spot".
    /// Julian's decision, 2026-08-16, after using it on the phone: the loupe sat right
    /// next to the thumb and the screen felt crowded.
    ///
    /// It is the same file the picture draws, drawn again at the same size and scaled
    /// about the corner, so it can never disagree with what is underneath. It is
    /// decoration: it takes no touch and a screen reader never announces it, and the four
    /// corner names stay the way a corner is moved without sight.
    private func magnifier(at corner: CGPoint, in size: CGSize) -> some View {
        let at = CGPoint(x: corner.x * size.width, y: corner.y * size.height)
        let zoom = Token.Number.magnifierZoom
        let radius = Token.Size.magnifier / 2
        // The disc is inset one step from the picture's edge, so it clears the rounded
        // corner; its centre is therefore that step plus its radius.
        let padR = Token.Size.space2 + radius
        let padCross = Token.Size.space2 + Token.Size.magnifierCross
        // The dock is a place, not a distance: the far edge from the hand, at the
        // finger's own height. A finger exactly on the middle docks left, so it never
        // flickers.
        let farRight = at.x < size.width / 2
        let cx = farRight ? size.width - padR : padR
        // The disc is clamped so the circle never leaves the picture; the magnified point
        // rides a far looser clamp, so near the top or bottom the disc slides inward while
        // the leader stays dead level and still lands on the cross.
        let cy = min(max(at.y, padR), max(padR, size.height - padR))
        let ay = min(max(at.y, padCross), max(padCross, size.height - padCross))
        return ZStack {
            // The leader, drawn first so the magnified copy paints over its far end and
            // the line visibly runs into the circle. It carries a hairline of paper, the
            // trick the grips use, so an accent rule survives a dark photo.
            Rectangle()
                .fill(Token.Palette.accent)
                .frame(width: abs(cx - at.x), height: Token.Size.ruleStrong)
                .padding(Token.Size.hairlineW)
                .background(Token.Palette.paper)
                .position(x: (at.x + cx) / 2, y: ay)
            Circle()
                .fill(Token.Palette.paper)
                .overlay {
                    PageImage(url: drawn)
                        .frame(width: size.width, height: size.height)
                        .scaleEffect(zoom)
                        .offset(x: (size.width / 2 - at.x) * zoom,
                                y: (size.height / 2 - at.y) * zoom + ay - cy)
                }
                .clipShape(Circle())
                .overlay(Circle().stroke(Token.Palette.divider,
                                         lineWidth: Token.Size.hairlineW))
                .frame(width: Token.Size.magnifier, height: Token.Size.magnifier)
                .position(x: cx, y: cy)
            // The crosshair sits on the magnified point, not on the disc's geometric
            // centre - which is why it rides ay and not cy.
            Group {
                Rectangle().frame(width: Token.Size.magnifierCross,
                                  height: Token.Size.ruleStrong)
                Rectangle().frame(width: Token.Size.ruleStrong,
                                  height: Token.Size.magnifierCross)
            }
            .foregroundStyle(Token.Palette.accent)
            .position(x: cx, y: ay)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private static let cornerNames = ["Top left corner", "Top right corner",
                                      "Bottom right corner", "Bottom left corner"]

    // MARK: - The tools

    private var strip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Token.Size.space2) {
                ForEach(Tool.allCases, id: \.self) { one in
                    let chosen = one == tool
                    Button(one.rawValue) { tool = one }
                        .font(Token.Face.heading(Token.Size.textControl))
                        .tracking(Token.Size.textControl * Token.Number.trackingHeading)
                        .padding(.horizontal, Token.Size.buttonPaddingX)
                        .frame(minHeight: Token.Size.touchMin)
                        .background(chosen ? Token.Palette.accent : Token.Palette.bg,
                                    in: RoundedRectangle(cornerRadius: Token.Size.radiusMd))
                        .overlay(RoundedRectangle(cornerRadius: Token.Size.radiusMd)
                            .stroke(Token.Palette.divider, lineWidth: Token.Size.hairlineW))
                        .foregroundStyle(chosen ? Token.Palette.onAccent : Token.Palette.text)
                        .accessibilityAddTraits(chosen ? [.isSelected] : [])
                }
            }
        }
    }

    @ViewBuilder
    private var controls: some View {
        VStack(alignment: .leading, spacing: Token.Size.space2) {
            Text(tool.rawValue)
                .font(Token.Face.heading(Token.Size.textH6))
                .tracking(Token.Size.textH6 * Token.Number.trackingH6)
                .foregroundStyle(Token.Palette.text)
            switch tool {
            case .edges:
                toggle("Pull the sheet flat", $pullFlat,
                       hint: "Straightens the sheet as if it were lying flat.")
                reset(.edges)
            case .straighten:
                slider("Straighten", $angle, in: -10...10, step: 0.1,
                       reading: String(format: "%.1f°", angle), low: "−10", high: "+10")
                reset(.straighten)
            case .brightness:
                // The two cannot meet: the engine divides by white minus black, and a
                // black point at or past the white one writes a solid black page.
                slider("Black point", $black, in: 0...(white - 1), step: 1,
                       reading: "\(Int(black)) %")
                slider("White point", $white, in: (black + 1)...100, step: 1,
                       reading: "\(Int(white)) %")
                toggle("Adjust the tones", $tones, hint: "Stretches the page's tones again.")
                reset(.brightness)
            case .sharpen:
                // Zero is the reading the copy table gives a word to, because zero means
                // the client skips the call rather than sharpening by nothing.
                slider("Sharpen", $sharpen, in: 0...20, step: 0.1,
                       reading: sharpen == 0 ? "None" : String(format: "%.1f", sharpen))
                reset(.sharpen)
            case .crop:
                reset(.crop)
            case .turn:
                Button { turns = (turns + 1) % 4 } label: {
                    Image(systemName: "rotate.right")
                        .font(.system(size: Token.Size.iconRow))
                        .frame(width: Token.Size.touchMin, height: Token.Size.touchMin)
                        .overlay(RoundedRectangle(cornerRadius: Token.Size.radiusMd)
                            .stroke(Token.Palette.divider, lineWidth: Token.Size.hairlineW))
                }
                .accessibilityLabel("A quarter turn clockwise")
                .accessibilityValue("Page \(position), turned \(turns) quarter turns clockwise.")
                reset(.turn)
            }
        }
    }

    private func toggle(_ title: String, _ on: Binding<Bool>, hint: String) -> some View {
        Toggle(isOn: on) {
            Text(title)
                .font(Token.Face.heading(Token.Size.textControl))
                .tracking(Token.Size.textControl * Token.Number.trackingHeading)
                .foregroundStyle(Token.Palette.text)
        }
        .toggleStyle(.switch)
        .tint(Token.Palette.accent)
        .frame(minHeight: Token.Size.touchMin)
        .accessibilityHint(hint)
    }

    private func slider(_ title: String, _ value: Binding<Double>,
                        in range: ClosedRange<Double>, step: Double,
                        reading: String, low: String? = nil, high: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: Token.Size.space2) {
            HStack {
                Text(title)
                Spacer()
                Text(reading).monospacedDigit()
            }
            .font(Token.Face.heading(Token.Size.textControl))
            .tracking(Token.Size.textControl * Token.Number.trackingHeading)
            .foregroundStyle(Token.Palette.text)
            Slider(value: value, in: range, step: step) {
                Text(title)
            } minimumValueLabel: {
                end(low ?? "")
            } maximumValueLabel: {
                end(high ?? "")
            }
            .accessibilityValue(reading)
        }
    }

    private func end(_ text: String) -> some View {
        Text(text)
            .font(Token.Face.body(Token.Size.textMeta))
            .foregroundStyle(Token.Palette.textMuted)
    }

    /// A line under the picture that is not a failure - the Edges note the engine feeds.
    private func note(_ sentence: String) -> some View {
        Text(sentence)
            .font(Token.Face.body(Token.Size.textMeta))
            .lineSpacing(Token.Size.textMeta * (Token.Number.leadingBody - 1))
            .foregroundStyle(Token.Palette.textMuted)
    }

    /// The ghost reset. It is on every tool, and it puts this tool's controls back on the
    /// engine's own answer.
    private func reset(_ tool: Tool) -> some View {
        Button("Back to the suggestion") { seed(tool) }
            .font(Token.Face.heading(Token.Size.textControl))
            .tracking(Token.Size.textControl * Token.Number.trackingHeading)
            .foregroundStyle(Token.Palette.accent)
            .frame(minHeight: Token.Size.touchMin)
    }

    // MARK: - The footer

    private var footer: some View {
        toggle("Apply to all pages", $allPages,
               hint: "Rewrites every page of this scan from its own photo.")
            .padding(Token.Size.screenPadding)
    }

    // MARK: - The suggestion

    /// Puts the engine's answer on the controls - all of them when the screen opens,
    /// one tool's worth when "Back to the suggestion" is tapped.
    ///
    /// Pixels become fractions here, the one way round from `values` below: the corners
    /// against the photo, 0…255 back into the sliders' percent.
    private func seed(_ only: Tool?, from stored: Engine.Adjustments? = nil) {
        guard let s = suggestion else { return }
        // The engine seeds a page once. After that the screen opens on what was last
        // applied, which is what `state/NNNN.txt` is for - "Back to the suggestion"
        // passes nothing here and is the one way back to the engine's own answer.
        let all = stored ?? s.values
        if only == nil || only == .edges {
            // The corners of a stored line were measured on this same photo, which
            // never changes, so they need no second opinion from the engine.
            let measured = (stored != nil || s.foundASheet)
                && photoSize.width > 0 && photoSize.height > 0
            sheet = measured
                ? stride(from: 0, to: 8, by: 2).map {
                      CGPoint(x: Double(all.corners[$0]) / photoSize.width,
                              y: Double(all.corners[$0 + 1]) / photoSize.height)
                  }
                : Self.wholePicture
            // The switch needs the same guard as the corners: armed over the whole
            // picture it would send four corners the engine refuses, every time.
            pullFlat = all.pullTheSheetFlat && measured
        }
        if only == nil || only == .straighten { angle = Double(all.straightenDegrees) }
        if only == nil || only == .brightness {
            black = Self.percent(all.black)
            white = Self.percent(all.white)
            tones = all.adjustTheTones
        }
        if only == nil || only == .sharpen { sharpen = Double(all.sharpenRadius) }
        if only == nil || only == .crop {
            // The box opens on the whole picture even where one is stored: the page on
            // screen is already the last cut, so there is no *further* cut yet, and the
            // engine's crop space is neither the photo nor the page. `ScanFlow` composes
            // this drag onto the stored one at Apply.
            box = Self.wholePicture
        }
        if only == nil || only == .turn { turns = Int(all.quarterTurns) }
        // Only a full seed. On open the screen has to show what was last applied without
        // spending an engine pass or overwriting the stored numbers. "Back to the
        // suggestion" on Straighten or Brightness puts back numbers that are already the
        // engine's answer for the sheet on screen, so it needs no forced re-measure; on
        // Edges it moves `sheet` and leaves this behind, which fires one by itself.
        if only == nil { measuredFor = (sheet, pullFlat) }
    }

    // MARK: - The values

    /// The screen as one struct for the engine. Only the corners become pixels here,
    /// against the photo; the crop is already the fraction the engine wants, held
    /// inside the picture so a box dragged past the edge cuts the edge.
    private var values: Engine.Adjustments {
        let levels = shiftedLevels
        var crop = (x: Float(0), y: Float(0), w: Float(0), h: Float(0))
        if box != Self.wholePicture {
            let xs = box.map { min(max($0.x, 0), 1) }, ys = box.map { min(max($0.y, 0), 1) }
            crop = (Float(xs.min()!), Float(ys.min()!),
                    Float(xs.max()! - xs.min()!), Float(ys.max()! - ys.min()!))
        }
        return Engine.Adjustments(
            corners: sheet.flatMap { [Float($0.x * photoSize.width),
                                      Float($0.y * photoSize.height)] },
            pullTheSheetFlat: pullFlat,
            straightenDegrees: Float(angle),
            black: levels.black,
            white: levels.white,
            adjustTheTones: tones,
            sharpenRadius: Float(sharpen),
            cropX: crop.x, cropY: crop.y, cropWidth: crop.w, cropHeight: crop.h,
            quarterTurns: UInt32(turns),
            grey: grey)
    }

    /// The suggestion's three channels moved by what the two sliders were moved by.
    ///
    /// The screen shows one black point and one white point, the engine takes R, G and
    /// B apart, and that difference between the channels is what takes the colour cast
    /// out. So the slider is read as a shift of all three, not as a value replacing
    /// them: at the suggestion it changes nothing, and moved it moves every channel by
    /// the same amount. A channel is never let past its other end, whatever the shift.
    private var shiftedLevels: (black: [UInt8], white: [UInt8]) {
        guard let all = suggestion?.values else { return (black: [0, 0, 0], white: [255, 255, 255]) }
        let low = Self.moved(all.black, by: black - Self.percent(all.black), highest: 254)
        let high = Self.moved(all.white, by: white - Self.percent(all.white), highest: 255)
        return (black: low, white: zip(low, high).map { max($1, $0 + 1) })
    }

    /// Where the three channels sit on a 0…100 slider: their average, because one
    /// slider cannot show three numbers.
    private static func percent(_ channels: [UInt8]) -> Double {
        channels.reduce(0.0) { $0 + Double($1) } / 3 / 255 * 100
    }

    private static func moved(_ channels: [UInt8], by percent: Double, highest: Double) -> [UInt8] {
        channels.map { UInt8(min(highest, max(0, (Double($0) + percent / 100 * 255).rounded()))) }
    }

    /// What a picture measures **upright** - the stored frame with its orientation tag
    /// applied. The tag cannot be ignored: the engine reads the photo upright and gives
    /// its corners in that space, so a portrait photo stored 4032x3024 measures
    /// 3024x4032 here. Tags 5 to 8 are the quarter turned ones, and they swap the two.
    private static func pixels(_ url: URL) -> CGSize {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let all = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let wide = all[kCGImagePropertyPixelWidth] as? Int,
              let tall = all[kCGImagePropertyPixelHeight] as? Int
        else { return .zero }
        let turned = (all[kCGImagePropertyOrientation] as? Int ?? 1) >= 5
        return CGSize(width: turned ? tall : wide, height: turned ? wide : tall)
    }
}
