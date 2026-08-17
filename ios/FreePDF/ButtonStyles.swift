//  ButtonStyles.swift - the two button styles more than one screen uses.
//
//  A `Button` hit-tests its label. Every modifier chained onto the Button *value* -
//  padding, a frame, a background, a stroke - decorates the wrapper around that label
//  instead, so it paints a box whose tappable part is still only the words. A trailing
//  `.contentShape` does not rescue it either: it lands on the same wrapper, not on the
//  label the gesture is tested against. Four of those were written in this app and Julian
//  felt every one of them on the phone.
//
//  A `ButtonStyle` decorates `configuration.label`, which is what the tap is tested
//  against, and `.background(colour, in: shape)` puts a real filled shape under the whole
//  box - hit testing is geometry, not alpha, so even a clear fill answers. Painted and
//  tappable become the same rectangle. That is the whole reason these two exist instead of
//  a handful of modifiers at each call site.
//
//  Only what two screens share lives here, the way `ErrorLine` does. `SecondaryStyle`,
//  `RowStyle`, `ShutterStyle`, `ChipStyle` and the done screen's `OutlineStyle` stay
//  private beside the one screen each of them belongs to.
//
//  Every colour, size and step comes from `Token`. No number is written here.

import SwiftUI

/// The filled button: the one accent slab a screen is allowed, on the two screens that
/// have one - Make PDF in the pages footer, New scan in the empty list.
///
/// `wide` is the footer's full width, which the empty state does not want: there the pill
/// hugs its two words in the middle of the screen. `off` is the dead look in the
/// `--disabled-*` colour roles rather than an opacity, so the slab keeps its full size and
/// only the colours go quiet - the same trade `SecondaryStyle` makes.
struct PrimaryStyle: ButtonStyle {
    var wide = false
    var off = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Token.Face.heading(Token.Size.textControl))
            .padding(.vertical, Token.Size.buttonPaddingY)
            .padding(.horizontal, Token.Size.buttonPaddingX)
            .frame(maxWidth: wide ? .infinity : nil, minHeight: Token.Size.touchMin)
            .background(off ? Token.Palette.disabledBorder : Token.Palette.accent,
                        in: RoundedRectangle(cornerRadius: Token.Size.radiusMd))
            // Taking the automatic style away took its label dim with it, and a button that
            // answers a tap without saying so reads as a button that missed. `pressNeutral`
            // is the dark veil, so it shows over the accent fill where `pressAccent` - a
            // tint of the accent itself - would be invisible.
            .background(configuration.isPressed ? Token.Palette.pressNeutral : .clear,
                        in: RoundedRectangle(cornerRadius: Token.Size.radiusMd))
            .foregroundStyle(off ? Token.Palette.disabledText : Token.Palette.onAccent)
    }
}

/// The quiet button: accent words with nothing drawn round them, in a slot 44 points tall
/// so the thumb has that whole height to land in - the page rail's Go to page and Adjust's
/// Back to the suggestion, which paint the same thing in the same place under every tool.
///
/// Nothing is painted at rest, so `contentShape` is what makes the slot real here; neither
/// screen draws a box round these words. It works where the deleted ones did not because it
/// sits on `configuration.label`, inside the style, and not on the Button.
struct GhostStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Token.Face.heading(Token.Size.textControl))
            .tracking(Token.Size.textControl * Token.Number.trackingHeading)
            .frame(minHeight: Token.Size.touchMin)
            .contentShape(Rectangle())
            // Nothing is painted at rest, so the press is the only thing that can say the
            // slot was hit - `pressAccent` behind the words, exactly as the done screen's
            // `OutlineStyle` does it. The `contentShape` above still carries the hit area:
            // it states the whole slot outright rather than leaning on a clear fill.
            .background(configuration.isPressed ? Token.Palette.pressAccent : .clear,
                        in: RoundedRectangle(cornerRadius: Token.Size.radiusMd))
            .foregroundStyle(Token.Palette.accent)
    }
}
