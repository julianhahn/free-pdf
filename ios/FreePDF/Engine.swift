//  Engine.swift - what the engine says, in Swift's own types.
//
//  Only the types live here, and only Foundation is imported, so `Scan.swift` can store
//  a page's values and `../check/run.sh` can read them back with no bridging header, no
//  library and no simulator. The four calls that cross the C boundary are next door in
//  [`EngineCalls.swift`](./EngineCalls.swift), and there is no other way to the engine.

import Foundation

enum Engine {
    /// What the engine said went wrong, in the sentence it wrote. The app shows it
    /// unchanged, because a finished English sentence is what the engine promises to
    /// return (`../../AGENTS.md`).
    struct Failed: Error, LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    /// How small a written page is: one rung of the page size setting, and the whole of
    /// what the app decides about it.
    ///
    /// Two rungs reach the user, and a switch is the honest control for two: `.small` is
    /// the default every scan is written at, and `.original` is the page the engine has
    /// always written, for the scan where `.small` does not look good enough. The rung
    /// names live here and not in C, because how many rungs there are and what they
    /// promise is the app's decision ([`../../ffi/AGENTS.md`](../../ffi/AGENTS.md)).
    ///
    /// Measured on 2026-08-23 over thirteen real photographed sheets: `.small` takes
    /// **about 45% off** what `.original` writes - 40 to 68% across the thirteen - and is
    /// invisible at 100% zoom, fine print and long digit strings included. One page's
    /// bytes, near the middle: 996,409 at `.original`, 526,077 at `.small`. The engine has
    /// a third rung, a 1700 px longest edge, which takes about 81% off and is visibly
    /// softer. It is deliberately not offered: 1700 px across A4 is about 150 dpi, and
    /// reading the text back out of the page later wants about 300.
    ///
    /// `Equatable` so a screen can key its preview on the rung itself - a flip is a new
    /// run - and `Sendable` because that run is a detached task.
    struct PageQuality: Sendable, Equatable {
        /// 1 to 100. Higher is a bigger, better looking page.
        let jpegQuality: Int32
        /// The longest edge the page may keep, in pixels, or 0 to keep every pixel. Only
        /// 0 ever crosses today: both rungs the app offers keep every pixel, and the one
        /// that does not is the 1700 px rung above.
        let longestEdge: Int32

        /// The default, and what a scan is written at unless the user says otherwise.
        static let small = PageQuality(jpegQuality: 45, longestEdge: 0)
        /// Full quality: the engine's own `PageQuality::UNCHANGED`, which is byte for byte
        /// the page this engine wrote before there was anything to choose.
        static let original = PageQuality(jpegQuality: 85, longestEdge: 0)
    }

    /// Every value the Adjust screen can move, in Swift's own types.
    ///
    /// It exists rather than passing `FreepdfAdjustments` around because the C struct
    /// carries fixed-size arrays as tuples and is not `Sendable`, and applying runs in a
    /// detached task. The struct is filled in one place, in `EngineCalls.swift`.
    ///
    /// Every field is filled by the screen or by the suggestion below, so none carries a
    /// default: a default here would be a second opinion about what "change nothing" is.
    ///
    /// `Equatable` so the Adjust screen can key its preview on the values themselves: a
    /// change is a new run, and an unchanged struct is not a second run of the same work.
    struct Adjustments: Sendable, Equatable {
        /// The four sheet corners as x, y pairs in photo pixels - the photo upright, at
        /// full size. Only read when `pullTheSheetFlat` is on.
        var corners: [Float]
        var pullTheSheetFlat: Bool
        var straightenDegrees: Float
        /// R, G and B kept apart, three values each. That is what takes the colour
        /// cast out: the engine stretches every channel by its own amount, and one
        /// value copied onto all three would put the cast back.
        var black: [UInt8]
        var white: [UInt8]
        var adjustTheTones: Bool
        var sharpenRadius: Float
        /// The cut, as fractions 0…1 of the image the engine holds right before
        /// cropping. That image only exists inside the engine, so the app never
        /// measures anything for this. Width or height 0 cuts nothing.
        var cropX: Float
        var cropY: Float
        var cropWidth: Float
        var cropHeight: Float
        var quarterTurns: UInt32
        var grey: Bool

        /// This drag laid **inside** the cut that is already stored, rather than
        /// replacing it.
        ///
        /// The crop is a fraction of an image that exists only mid-recipe - after the
        /// corners, the straightening, the 3000 px cap and the turn - so it is neither the
        /// photo nor the page ([`../../core_engine/AGENTS.md`](../../core_engine/AGENTS.md),
        /// "Every step has its own space"). The screen therefore opens the box on the whole
        /// picture, which is honest, because the page it draws is already the last cut and
        /// there is no *further* cut yet. Apply composes the two.
        ///
        /// A turn changes the space the stored box was written in, so it is turned with it
        /// first: one quarter clockwise maps `(x, y, w, h)` to `(1 - y - h, x, h, w)`.
        ///
        /// ponytail: composing means the user can only ever cut tighter, never widen.
        /// Ceiling: widening is "Scan this page again", which is the undo for everything
        /// else on the Adjust screen.
        func composed(onto stored: Adjustments?) -> Adjustments {
            guard let stored, stored.cropWidth > 0, stored.cropHeight > 0 else { return self }
            var old = (x: stored.cropX, y: stored.cropY, w: stored.cropWidth, h: stored.cropHeight)
            let quarters = (Int(quarterTurns) - Int(stored.quarterTurns) + 4) % 4
            for _ in 0..<quarters { old = (1 - old.y - old.h, old.x, old.h, old.w) }
            var mine = self
            if cropWidth > 0, cropHeight > 0 {
                mine.cropX = old.x + cropX * old.w
                mine.cropY = old.y + cropY * old.h
                mine.cropWidth = old.w * cropWidth
                mine.cropHeight = old.h * cropHeight
            } else {
                (mine.cropX, mine.cropY, mine.cropWidth, mine.cropHeight) = old
            }
            return mine
        }
    }

    /// What the engine would have done to this photo on its own, so every control on the
    /// Adjust screen opens on the engine's own answer the first time a page is adjusted
    /// ("suggest, then apply", [`../../user-flows.md`](../../user-flows.md) section 7).
    struct Suggestion: Sendable {
        var values: Adjustments
        var foundASheet: Bool
        /// The sheet fills the frame, so there is nothing to cut away.
        var fillsTheWholePhoto: Bool
        /// The sheet leaves the frame.
        var runsOffThePicture: Bool
    }
}
