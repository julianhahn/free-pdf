//  ErrorLine.swift - one failure sentence, printed unchanged.
//
//  The rule on its left is the point: this theme never marks anything by colour alone.
//  Three screens show it - the list, the camera and the drain - so it lives here rather
//  than three times over.

import SwiftUI

struct ErrorLine: View {
    let sentence: String

    var body: some View {
        HStack(spacing: Token.Size.space2) {
            Rectangle()
                .fill(Token.Palette.destructive)
                .frame(width: Token.Size.ruleStrong)
            Text(sentence)
                .font(Token.Face.body(Token.Size.textSub))
                .lineSpacing(Token.Size.textSub * (Token.Number.leadingBody - 1))
                .foregroundStyle(Token.Palette.destructive)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
