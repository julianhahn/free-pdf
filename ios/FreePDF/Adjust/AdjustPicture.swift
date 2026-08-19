//  AdjustPicture.swift - the page as it stands, with the active tool's handles over it.
//
//  One of `AdjustView`'s four files, and the half the user looks at: which of the two
//  files is drawn, how far it is turned, the shape the block takes so a handle sits
//  where it is dragged, the four corners themselves, and the magnifier that makes a
//  corner aimable under the fingertip that hides it. `pixels` is here too, because what
//  a picture measures upright is a fact about the file being drawn.
//
//  The screen, and every value these handles move, is in
//  [`AdjustView.swift`](./AdjustView.swift).

import ImageIO
import SwiftUI

extension AdjustView {
    // MARK: - The page

    /// The page as it stands now, with the handles of the active tool over it. The block
    /// keeps its own shape, so a handle sits where it is dragged.
    ///
    /// Edges shows the **photo** instead: its handles are the sheet's corners, which the
    /// engine takes in photo pixels, and drawing them over the page would put them in a
    /// space nothing maps back to. Crop stays on the page, because the fraction the user
    /// drags there is the fraction the engine cuts.
    var picture: some View {
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

    /// Four draggable corners over the picture, and while one is touched, the magnifier
    /// that makes it aimable.
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
                    // One gesture, doing both jobs. It was two for a while - a
                    // `minimumDistance: 0` one to raise the loupe on touch down and a
                    // travelling one to move the corner - and the corner then stopped moving
                    // at all (Julian, on the phone): two drags on one view are exclusive, so
                    // the zero-distance one recognises first and the other never fires.
                    //
                    // `minimumDistance: 0` is what the loupe needs, because a loupe that
                    // appears only after the finger has already travelled shows up too late
                    // to aim with. It costs the enclosing `ScrollView` its pan on these four
                    // 44 point circles, which is the cheap half of the trade: nobody scrolls
                    // the screen by putting a thumb exactly on a corner handle.
                    //
                    // The corner moves *from where it was* by the distance travelled, never
                    // to `move.location`: a touch that lands 20 points off centre inside the
                    // target would otherwise shift the sheet by 20 points before the user has
                    // dragged anything at all. A stationary touch has no translation, so it
                    // raises the loupe and moves nothing.
                    .gesture(DragGesture(minimumDistance: 0).onChanged { move in
                        held = i
                        let from = grabbed?.corner == i
                            ? grabbed!.at
                            : points.wrappedValue[i]
                        grabbed = (i, from)
                        points.wrappedValue[i] = CGPoint(
                            x: from.x + move.translation.width / geo.size.width,
                            y: from.y + move.translation.height / geo.size.height)
                    }.onEnded { _ in letGo() })
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

    /// The finger is off the corner: no magnifier, and the next touch grabs afresh from
    /// wherever the corner ended up.
    private func letGo() {
        held = nil
        grabbed = nil
    }

    private static let cornerNames = ["Top left corner", "Top right corner",
                                      "Bottom right corner", "Bottom left corner"]

    /// What a picture measures **upright** - the stored frame with its orientation tag
    /// applied. The tag cannot be ignored: the engine reads the photo upright and gives
    /// its corners in that space, so a portrait photo stored 4032x3024 measures
    /// 3024x4032 here. Tags 5 to 8 are the quarter turned ones, and they swap the two.
    static func pixels(_ url: URL) -> CGSize {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let all = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let wide = all[kCGImagePropertyPixelWidth] as? Int,
              let tall = all[kCGImagePropertyPixelHeight] as? Int
        else { return .zero }
        let turned = (all[kCGImagePropertyOrientation] as? Int ?? 1) >= 5
        return CGSize(width: turned ? tall : wide, height: turned ? wide : tall)
    }
}
