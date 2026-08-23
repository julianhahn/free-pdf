//  AdjustTools.swift - the six chips, and the controls under whichever one is chosen.
//
//  One of `AdjustView`'s four files. Nothing here holds a value or asks the engine
//  anything: it paints the strip, the toggles, the sliders, the calm note and the ghost
//  reset over the state [`AdjustView.swift`](./AdjustView.swift) owns. The only numbers
//  written here are the ranges the engine itself sets - everything else is a `Token`.

import SwiftUI

extension AdjustView {
    // MARK: - The tools

    var strip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Token.Size.space2) {
                ForEach(Tool.allCases, id: \.self) { one in
                    let chosen = one == tool
                    Button(one.rawValue) { tool = one }
                        .buttonStyle(ChipStyle(chosen: chosen))
                        .accessibilityAddTraits(chosen ? [.isSelected] : [])
                }
            }
        }
    }

    @ViewBuilder
    var controls: some View {
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
                        // The decoration is in the label, which is the half that was
                        // already right, but a frame and a stroke hold no hit region
                        // between them: without this the ring of empty box around the
                        // glyph answers nothing.
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("A quarter turn clockwise")
                .accessibilityValue("Page \(position), turned \(turns) quarter turns clockwise.")
                reset(.turn)
            }
        }
    }

    func toggle(_ title: String, _ on: Binding<Bool>, hint: String) -> some View {
        Toggle(title, isOn: on)
            .toggleStyle(SettingStyle())
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
    func note(_ sentence: String) -> some View {
        Text(sentence)
            .font(Token.Face.body(Token.Size.textMeta))
            .lineSpacing(Token.Size.textMeta * (Token.Number.leadingBody - 1))
            .foregroundStyle(Token.Palette.textMuted)
    }

    /// The ghost reset. It is on every tool, and it puts this tool's controls back on the
    /// engine's own answer.
    private func reset(_ tool: Tool) -> some View {
        Button("Back to the suggestion") { seed(tool) }
            .buttonStyle(GhostStyle())
    }
}

/// One tool chip: the word in a pill, filled in the accent while it is the tool on screen.
///
/// A `ButtonStyle` and not modifiers on the Button, because the pill itself has to answer
/// the tap. Six of these sit in a strip that scrolls, so a touch on the dead padding
/// between two chips is not merely a miss - it pans the strip instead of switching tool.
private struct ChipStyle: ButtonStyle {
    let chosen: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Token.Face.heading(Token.Size.textControl))
            .tracking(Token.Size.textControl * Token.Number.trackingHeading)
            .padding(.horizontal, Token.Size.buttonPaddingX)
            .frame(minHeight: Token.Size.touchMin)
            .background(chosen ? Token.Palette.accent : Token.Palette.bg,
                        in: RoundedRectangle(cornerRadius: Token.Size.radiusMd))
            // The dark veil rather than the accent tint, because it has to show on the
            // chosen chip's accent fill as well as on the plain ground of the other five.
            .background(configuration.isPressed ? Token.Palette.pressNeutral : .clear,
                        in: RoundedRectangle(cornerRadius: Token.Size.radiusMd))
            .overlay(RoundedRectangle(cornerRadius: Token.Size.radiusMd)
                .stroke(Token.Palette.divider, lineWidth: Token.Size.hairlineW))
            .foregroundStyle(chosen ? Token.Palette.onAccent : Token.Palette.text)
    }
}
