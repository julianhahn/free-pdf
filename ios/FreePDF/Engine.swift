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
