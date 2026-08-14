//  Tokens.swift — GENERATED. Do not edit.
//
//  Written by design/system/tokens/build-tokens.mjs out of design/system/tokens/*.css,
//  which is where a colour, a step or a size is changed. Run the script after changing
//  one; `--check` in CI fails when this file is behind.
//
//  What is not here: the two shadows and the .fp-on-dark override, because nothing on
//  the phone draws them yet. Add them to the script, not to this file.

import SwiftUI
import UIKit

extension Color {
    /// One value per theme, resolved by the view's own trait collection.
    init(light: UIColor, dark: UIColor) {
        self.init(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }
}

enum Token {
    enum Palette {
        /// --neutral-100
        static let neutral100 = Color(light: UIColor(red: 0.9725, green: 0.9569, blue: 0.9569, alpha: 1),
                             dark: UIColor(red: 0.9725, green: 0.9569, blue: 0.9569, alpha: 1))
        /// --neutral-200
        static let neutral200 = Color(light: UIColor(red: 0.9176, green: 0.9059, blue: 0.9059, alpha: 1),
                             dark: UIColor(red: 0.9176, green: 0.9059, blue: 0.9059, alpha: 1))
        /// --neutral-300
        static let neutral300 = Color(light: UIColor(red: 0.8431, green: 0.8275, blue: 0.8275, alpha: 1),
                             dark: UIColor(red: 0.8431, green: 0.8275, blue: 0.8275, alpha: 1))
        /// --neutral-400
        static let neutral400 = Color(light: UIColor(red: 0.7294, green: 0.7137, blue: 0.7137, alpha: 1),
                             dark: UIColor(red: 0.7294, green: 0.7137, blue: 0.7137, alpha: 1))
        /// --neutral-500
        static let neutral500 = Color(light: UIColor(red: 0.6078, green: 0.5922, blue: 0.5922, alpha: 1),
                             dark: UIColor(red: 0.6078, green: 0.5922, blue: 0.5922, alpha: 1))
        /// --neutral-600
        static let neutral600 = Color(light: UIColor(red: 0.4902, green: 0.4745, blue: 0.4745, alpha: 1),
                             dark: UIColor(red: 0.4902, green: 0.4745, blue: 0.4745, alpha: 1))
        /// --neutral-700
        static let neutral700 = Color(light: UIColor(red: 0.3765, green: 0.3647, blue: 0.3647, alpha: 1),
                             dark: UIColor(red: 0.3765, green: 0.3647, blue: 0.3647, alpha: 1))
        /// --neutral-800
        static let neutral800 = Color(light: UIColor(red: 0.2667, green: 0.2549, blue: 0.2549, alpha: 1),
                             dark: UIColor(red: 0.2667, green: 0.2549, blue: 0.2549, alpha: 1))
        /// --neutral-900
        static let neutral900 = Color(light: UIColor(red: 0.1765, green: 0.1686, blue: 0.1686, alpha: 1),
                             dark: UIColor(red: 0.1765, green: 0.1686, blue: 0.1686, alpha: 1))
        /// --accent-100
        static let accent100 = Color(light: UIColor(red: 1, green: 0.9529, blue: 0.8941, alpha: 1),
                            dark: UIColor(red: 1, green: 0.9529, blue: 0.8941, alpha: 1))
        /// --accent-200
        static let accent200 = Color(light: UIColor(red: 1, green: 0.8902, blue: 0.749, alpha: 1),
                            dark: UIColor(red: 1, green: 0.8902, blue: 0.749, alpha: 1))
        /// --accent-300
        static let accent300 = Color(light: UIColor(red: 0.9804, green: 0.7961, blue: 0.5529, alpha: 1),
                            dark: UIColor(red: 0.9804, green: 0.7961, blue: 0.5529, alpha: 1))
        /// --accent-400
        static let accent400 = Color(light: UIColor(red: 0.8824, green: 0.6784, blue: 0.4, alpha: 1),
                            dark: UIColor(red: 0.8824, green: 0.6784, blue: 0.4, alpha: 1))
        /// --accent-500
        static let accent500 = Color(light: UIColor(red: 0.7608, green: 0.5529, blue: 0.2549, alpha: 1),
                            dark: UIColor(red: 0.7608, green: 0.5529, blue: 0.2549, alpha: 1))
        /// --accent-600
        static let accent600 = Color(light: UIColor(red: 0.6275, green: 0.4353, blue: 0.1412, alpha: 1),
                            dark: UIColor(red: 0.6275, green: 0.4353, blue: 0.1412, alpha: 1))
        /// --accent-700
        static let accent700 = Color(light: UIColor(red: 0.4902, green: 0.3294, blue: 0.0667, alpha: 1),
                            dark: UIColor(red: 0.4902, green: 0.3294, blue: 0.0667, alpha: 1))
        /// --accent-800
        static let accent800 = Color(light: UIColor(red: 0.3529, green: 0.2314, blue: 0.0392, alpha: 1),
                            dark: UIColor(red: 0.3529, green: 0.2314, blue: 0.0392, alpha: 1))
        /// --accent-900
        static let accent900 = Color(light: UIColor(red: 0.2275, green: 0.1529, blue: 0.051, alpha: 1),
                            dark: UIColor(red: 0.2275, green: 0.1529, blue: 0.051, alpha: 1))
        /// --surface
        static let surface = Color(light: UIColor(red: 0.9176, green: 0.9137, blue: 0.9137, alpha: 1),
                          dark: UIColor(red: 0.2667, green: 0.2549, blue: 0.2549, alpha: 1))
        /// --text
        static let text = Color(light: UIColor(red: 0.1255, green: 0.1216, blue: 0.1137, alpha: 1),
                       dark: UIColor(red: 0.9725, green: 0.9569, blue: 0.9569, alpha: 1))
        /// --accent
        static let accent = Color(light: UIColor(red: 0.7137, green: 0.5098, blue: 0.2078, alpha: 1),
                         dark: UIColor(red: 0.8824, green: 0.6784, blue: 0.4, alpha: 1))
        /// --divider
        static let divider = Color(light: UIColor(red: 0.1255, green: 0.1216, blue: 0.1137, alpha: 0.16),
                          dark: UIColor(red: 0.9725, green: 0.9569, blue: 0.9569, alpha: 0.22))
        /// --text-muted
        static let textMuted = Color(light: UIColor(red: 0.1255, green: 0.1216, blue: 0.1137, alpha: 0.58),
                            dark: UIColor(red: 0.9725, green: 0.9569, blue: 0.9569, alpha: 0.58))
        /// --divider-strong
        static let dividerStrong = Color(light: UIColor(red: 0.1255, green: 0.1216, blue: 0.1137, alpha: 0.32),
                                dark: UIColor(red: 0.9725, green: 0.9569, blue: 0.9569, alpha: 0.38))
        /// --destructive
        static let destructive = Color(light: UIColor(red: 0.4902, green: 0.3294, blue: 0.0667, alpha: 1),
                              dark: UIColor(red: 0.9804, green: 0.7961, blue: 0.5529, alpha: 1))
        /// --on-accent
        static let onAccent = Color(light: UIColor(red: 0.9725, green: 0.9569, blue: 0.9569, alpha: 1),
                           dark: UIColor(red: 0.1765, green: 0.1686, blue: 0.1686, alpha: 1))
        /// --paper
        static let paper = Color(light: UIColor(red: 0.9922, green: 0.9882, blue: 0.9804, alpha: 1),
                        dark: UIColor(red: 0.9137, green: 0.898, blue: 0.8784, alpha: 1))
        /// --viewfinder
        static let viewfinder = Color(light: UIColor(red: 0.1059, green: 0.102, blue: 0.098, alpha: 1),
                             dark: UIColor(red: 0.0745, green: 0.0706, blue: 0.0667, alpha: 1))
        /// --hover-accent
        static let hoverAccent = Color(light: UIColor(red: 0.7137, green: 0.5098, blue: 0.2078, alpha: 0.12),
                              dark: UIColor(red: 0.8824, green: 0.6784, blue: 0.4, alpha: 0.12))
        /// --press-accent
        static let pressAccent = Color(light: UIColor(red: 0.7137, green: 0.5098, blue: 0.2078, alpha: 0.22),
                              dark: UIColor(red: 0.8824, green: 0.6784, blue: 0.4, alpha: 0.26))
        /// --hover-neutral
        static let hoverNeutral = Color(light: UIColor(red: 0.1255, green: 0.1216, blue: 0.1137, alpha: 0.07),
                               dark: UIColor(red: 0.9725, green: 0.9569, blue: 0.9569, alpha: 0.07))
        /// --press-neutral
        static let pressNeutral = Color(light: UIColor(red: 0.1255, green: 0.1216, blue: 0.1137, alpha: 0.14),
                               dark: UIColor(red: 0.9725, green: 0.9569, blue: 0.9569, alpha: 0.14))
        /// --press-row
        static let pressRow = Color(light: UIColor(red: 0.7137, green: 0.5098, blue: 0.2078, alpha: 0.14),
                           dark: UIColor(red: 0.8824, green: 0.6784, blue: 0.4, alpha: 0.14))
        /// --focus-ring
        static let focusRing = Color(light: UIColor(red: 0.7137, green: 0.5098, blue: 0.2078, alpha: 1),
                            dark: UIColor(red: 0.8824, green: 0.6784, blue: 0.4, alpha: 1))
        /// --disabled-text
        static let disabledText = Color(light: UIColor(red: 0.3765, green: 0.3647, blue: 0.3647, alpha: 1),
                               dark: UIColor(red: 0.7294, green: 0.7137, blue: 0.7137, alpha: 1))
        /// --disabled-surface
        static let disabledSurface = Color(light: UIColor(red: 0, green: 0, blue: 0, alpha: 0),
                                  dark: UIColor(red: 0, green: 0, blue: 0, alpha: 0))
    }

    enum Size {
        /// --space-1
        static let space1: CGFloat = 4.6
        /// --space-2
        static let space2: CGFloat = 9.2
        /// --space-3
        static let space3: CGFloat = 13.8
        /// --space-4
        static let space4: CGFloat = 18.4
        /// --space-6
        static let space6: CGFloat = 27.6
        /// --space-8
        static let space8: CGFloat = 36.8
        /// --screen-padding
        static let screenPadding: CGFloat = 18.4
        /// --button-padding-y
        static let buttonPaddingY: CGFloat = 9.2
        /// --button-padding-x
        static let buttonPaddingX: CGFloat = 16.56
        /// --touch-min
        static let touchMin: CGFloat = 44
        /// --radius-sm
        static let radiusSm: CGFloat = 2
        /// --radius-md
        static let radiusMd: CGFloat = 4
        /// --radius-lg
        static let radiusLg: CGFloat = 7
        /// --text-h1
        static let textH1: CGFloat = 42
        /// --text-h2
        static let textH2: CGFloat = 32
        /// --text-h3
        static let textH3: CGFloat = 25
        /// --text-h4
        static let textH4: CGFloat = 20
        /// --text-h5
        static let textH5: CGFloat = 16
        /// --text-h6
        static let textH6: CGFloat = 13
        /// --text-row-title
        static let textRowTitle: CGFloat = 17
        /// --text-body
        static let textBody: CGFloat = 15
        /// --text-control
        static let textControl: CGFloat = 14
        /// --text-sub
        static let textSub: CGFloat = 13
        /// --text-meta
        static let textMeta: CGFloat = 11
        /// --text-kicker
        static let textKicker: CGFloat = 10
    }

    enum Number {
        /// --disabled-opacity
        static let disabledOpacity: CGFloat = 1
        /// --leading-heading
        static let leadingHeading: CGFloat = 1.12
        /// --leading-body
        static let leadingBody: CGFloat = 1.55
        /// --weight-heading
        static let weightHeading: CGFloat = 600
        /// --weight-body
        static let weightBody: CGFloat = 400
    }

    enum Face {
        /// --font-heading. Falls back to the system serif when the family is missing.
        static func heading(_ size: CGFloat) -> Font { .custom("Cormorant Garamond", size: size) }
        /// --font-body
        static func body(_ size: CGFloat) -> Font { .custom("Lora", size: size) }
    }
}
