//  SettingStyle.swift - the one switch every setting in the app is drawn as.
//
//  Three switches were written out longhand before this existed - Grey and Smaller pages in
//  the pages footer, Smaller pages again on the check after the first photo - and all three
//  were the same eight lines: the heading face at control size, the heading's tracking, the
//  accent tint, and a 44 point slot for the thumb. Copied, not shared, so changing one of
//  them changed one screen and left the other saying something else. The design system has
//  one switch, not two ([`../../client-guide-design-system/components.md`](../../client-guide-design-system/components.md)),
//  and this is the one place that draws it.
//
//  A `ToggleStyle` and not a wrapper view, for the reason `ButtonStyle` is used next door in
//  [`ButtonStyles.swift`](./ButtonStyles.swift): the style decorates the label the control
//  itself owns, so the words the user reads and the words the switch is labelled by cannot
//  drift apart, and VoiceOver still sees one control rather than a view holding one.
//
//  Every colour, size and step comes from `Token`. No number is written here.

import SwiftUI

/// The app's switch: a heading-faced label on the left, the system switch on the right, in a
/// slot 44 points tall.
///
/// `off` is the dead look in the `--disabled-*` colour role rather than an opacity, the same
/// trade `PrimaryStyle` makes - the row keeps its full size and only the colour goes quiet.
/// It is set beside `.disabled(...)` and not instead of it: `.disabled` stops the tap,
/// this says so. The pages screen needs it once the photos are deleted, because a page
/// cannot be rewritten without the pixels it came from.
struct SettingStyle: ToggleStyle {
    var off = false

    func makeBody(configuration: Configuration) -> some View {
        Toggle(isOn: configuration.$isOn) {
            configuration.label
                .font(Token.Face.heading(Token.Size.textControl))
                .tracking(Token.Size.textControl * Token.Number.trackingHeading)
                .foregroundStyle(off ? Token.Palette.disabledText : Token.Palette.text)
        }
        .toggleStyle(.switch)
        .tint(Token.Palette.accent)
        .frame(minHeight: Token.Size.touchMin)
    }
}
