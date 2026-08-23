//  MetaLine.swift - the quiet grey sentence under something, printed unchanged.
//
//  Six places said the same three lines - the body face at meta size, the body leading for
//  text that wraps, and the muted ink: the done screen's size line and its warning about
//  the photos, the check screen's "not right?" and the line under its switch, the drain's
//  note, and the Edges note in Adjust. Six copies of a style is six chances for one screen
//  to end up saying it a shade differently, which is what this theme's tables exist to
//  prevent. It lives here for the same reason [`ErrorLine`](./ErrorLine.swift) does.
//
//  Not every grey sentence is one of these. A label that cannot wrap - "Name for the
//  shared copy", "Keep the app open.", a slider's end, the number under a thumbnail -
//  carries no `lineSpacing`, because leading between lines of a single line is nothing,
//  and adding it here would change four screens for no reason. The camera's "no camera"
//  sentence is on the dark viewfinder and uses `onDarkMuted`, so it is a different thing
//  again. This is the wrapping paragraph in muted ink, and nothing else.
//
//  Every colour, size and step comes from `Token`. No number is written here.

import SwiftUI

struct MetaLine: View {
    let sentence: String

    var body: some View {
        Text(sentence)
            .font(Token.Face.body(Token.Size.textMeta))
            .lineSpacing(Token.Size.textMeta * (Token.Number.leadingBody - 1))
            .foregroundStyle(Token.Palette.textMuted)
    }
}
