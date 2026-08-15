//  AdjustView.swift - the six tools, one at a time, on one page.
//
//  Reached from the Page menu only. It shows the page **as it stands now**: there is no
//  live preview anywhere, and dragging a handle moves the handle, not the picture. Apply
//  re-runs the recipe from `photo/NNNN.jpg` with the values below and replaces the page
//  file whole ([`../../user-flows.md`](../../user-flows.md) section 7).
//
//  Every control opens on what the engine would have done by itself
//  (`freepdf_suggest_adjustments`), and "Back to the suggestion" puts exactly that back:
//  suggest, then apply. A photo the engine cannot read means the page cannot be adjusted
//  at all, and the screen says so instead of opening on zeros.
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
    /// The scan's Grey switch, carried through: applying without it would quietly
    /// un-grey the page.
    let grey: Bool
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

    private static let wholePicture = [CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 0),
                                       CGPoint(x: 1, y: 1), CGPoint(x: 0, y: 1)]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Token.Size.space4) {
                    if let said = refusal ?? message { ErrorLine(sentence: said) }
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
                seed(nil)
            } catch {
                refusal = error.localizedDescription
            }
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
                .disabled(applying || suggestion == nil)
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
            PageImage(url: tool == .edges ? photo : page, grey: grey)
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

    /// How far the picture on screen is turned. Edges draws the photo, which the turn does
    /// not touch.
    private var quarter: Int { tool == .edges ? 0 : turns }

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

    /// Four draggable corners over the picture.
    private func handles(_ points: Binding<[CGPoint]>, colour: Color) -> some View {
        GeometryReader { geo in
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .stroke(colour, lineWidth: Token.Size.ruleStrong)
                    .frame(width: Token.Size.touchMin, height: Token.Size.touchMin)
                    .contentShape(Circle())
                    .position(x: points.wrappedValue[i].x * geo.size.width,
                              y: points.wrappedValue[i].y * geo.size.height)
                    .gesture(DragGesture().onChanged { move in
                        points.wrappedValue[i] = CGPoint(x: move.location.x / geo.size.width,
                                                         y: move.location.y / geo.size.height)
                    })
                    .accessibilityLabel(Self.cornerNames[i])
                    .accessibilityHint("Swipe up or down to move it.")
            }
        }
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
    private func seed(_ only: Tool?) {
        guard let s = suggestion else { return }
        let all = s.values
        if only == nil || only == .edges {
            let measured = s.foundASheet && photoSize.width > 0 && photoSize.height > 0
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
        if only == nil || only == .crop { box = Self.wholePicture }
        // The turn the page already has sits in its photo's orientation, so the
        // engine's 0 is the truth here: 0 means no *further* turn.
        if only == nil || only == .turn { turns = Int(all.quarterTurns) }
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
