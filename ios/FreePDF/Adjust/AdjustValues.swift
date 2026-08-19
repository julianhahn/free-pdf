//  AdjustValues.swift - everything this screen says to the engine.
//
//  One of `AdjustView`'s four files: the debounced run that shows what the current values
//  would do, the re-measure a moved corner forces, seeding the controls from the engine's
//  own answer, and turning the screen into one `Engine.Adjustments` for Apply to send.
//
//  The state all of this reads and writes is declared in
//  [`AdjustView.swift`](./AdjustView.swift), which is also where the one call that is not
//  here lives - the first `suggest` on open, in the screen's own `.task`.

import SwiftUI

extension AdjustView {
    // MARK: - What it would do

    /// The picture becomes the page the current values would produce.
    ///
    /// It is a real run of the engine's recipe, not an approximation drawn here, so what
    /// is on screen is what Apply writes. It goes to its own file under the system's
    /// temporary directory - never `photo/`, `page/`, `state/` or `scan.pdf`, so `sweep()`
    /// never sees it and a kill mid-run leaves nothing new in the scan folder. Each run
    /// writes its own file and the one before it is deleted only once the new one has
    /// landed, so a superseded run can never take the picture that is up.
    func showWhatItWouldDo() async {
        guard suggestion != nil else { return }
        try? await Task.sleep(for: .milliseconds(Self.settle))
        guard !Task.isCancelled else { return }
        if measuredForAnotherSheet {
            let before = previewValues
            await measureAgain()
            // A new number re-keys `task(id:)` and that run draws the picture. If it came
            // back the same number nothing was re-keyed, so this run draws it instead. A
            // settled drag costs two engine passes at most, never one per frame.
            if previewValues != before { return }
        }
        let asked = previewValues, source = photo
        let scratch = FileManager.default.temporaryDirectory
            .appendingPathComponent("adjust-preview-\(UUID().uuidString).jpg")
        do {
            try await Task.detached(priority: .userInitiated) {
                try Engine.adjustPage(source, into: scratch, asked)
            }.value
            guard !Task.isCancelled else {
                try? FileManager.default.removeItem(at: scratch)
                return
            }
            let stale = previewFile
            previewFile = scratch
            // The preview carries the turn and the cut, so it is the file the block's
            // shape now comes from.
            pageSize = Self.pixels(scratch)
            previewFailure = nil
            if let stale { try? FileManager.default.removeItem(at: stale) }
        } catch {
            try? FileManager.default.removeItem(at: scratch)
            // The engine's sentence, unchanged, exactly as Apply shows it. The last good
            // picture stays up.
            previewFailure = error.localizedDescription
        }
    }

    /// What the engine measures for itself, measured again against the corners now on
    /// screen: the straightening angle and the two tone points.
    ///
    /// Julian found this on a real phone: the common case is that find-page cut his page
    /// off, so he opens Adjust on Edges, puts the four crosshairs on the real corners and
    /// taps Apply without ever seeing another tab. Apply has to give him the page the
    /// automatic run would have made if find-page had found those corners itself - so
    /// every number the engine measures for itself is measured again. The angle was read
    /// off the engine's own frame; the black and white points were read off the pixels
    /// inside that frame, which caught the desk. Both describe a picture the app no
    /// longer makes.
    ///
    /// This replaces the numbers whether the engine put them there or the user nudged
    /// them (Julian, 2026-08-16). A number set by hand against corners he then moved is
    /// not his any more. From here he is back to nudging.
    private func measureAgain() async {
        let source = photo, asked = values
        do {
            let fresh = try await Task.detached(priority: .userInitiated) {
                try Engine.suggest(source, for: asked)
            }.value
            guard !Task.isCancelled else { return }
            // The whole answer, not a piece of it. Asked about the user's sheet the
            // engine hands back its own found corners, its own switch and its three
            // notes unchanged - only the angle, the two tone points and the tones
            // switch are measured against what it was given. So this is still the
            // engine's own answer, now about the sheet on screen, and "Back to the
            // suggestion" reads exactly the same corners it read before.
            suggestion = fresh
            angle = Double(fresh.values.straightenDegrees)
            black = Self.percent(fresh.values.black)
            white = Self.percent(fresh.values.white)
            tones = fresh.values.adjustTheTones
        } catch {
            // The engine's sentence, exactly as a failed preview shows it, last good
            // picture up.
            previewFailure = error.localizedDescription
        }
        // Set whether it worked or not: a photo the engine refuses must not leave Apply
        // dead forever, and Apply would show the same sentence anyway.
        measuredFor = (sheet, pullFlat)
    }

    /// How long a value has to sit still before the engine is asked, in milliseconds. A
    /// run costs about as much as one scan, so a drag would otherwise queue one per frame.
    private static let settle = 300

    /// What the preview runs - the values Apply would send, composed onto what is stored
    /// by the same call Apply makes.
    ///
    /// Crop is the one difference, and it is not a second code path: the box the user is
    /// dragging is a fraction of the picture **before** the cut, so while that tool is up
    /// the preview shows that picture, which is the page with the stored cut and nothing
    /// further. Every other tool sees the finished page.
    var previewValues: Engine.Adjustments {
        var mine = values
        if tool == .crop {
            (mine.cropX, mine.cropY, mine.cropWidth, mine.cropHeight) = (0, 0, 0, 0)
        }
        return mine.composed(onto: stored)
    }

    // MARK: - The suggestion

    /// Puts the engine's answer on the controls - all of them when the screen opens,
    /// one tool's worth when "Back to the suggestion" is tapped.
    ///
    /// Pixels become fractions here, the one way round from `values` below: the corners
    /// against the photo, 0…255 back into the sliders' percent.
    func seed(_ only: Tool?, from stored: Engine.Adjustments? = nil) {
        guard let s = suggestion else { return }
        // The engine seeds a page once. After that the screen opens on what was last
        // applied, which is what `state/NNNN.txt` is for - "Back to the suggestion"
        // passes nothing here and is the one way back to the engine's own answer.
        let all = stored ?? s.values
        if only == nil || only == .edges {
            // The corners of a stored line were measured on this same photo, which
            // never changes, so they need no second opinion from the engine.
            let measured = (stored != nil || s.foundASheet)
                && photoSize.width > 0 && photoSize.height > 0
            sheet = measured
                ? stride(from: 0, to: 8, by: 2).map {
                      CGPoint(x: Double(all.corners[$0]) / photoSize.width,
                              y: Double(all.corners[$0 + 1]) / photoSize.height)
                  }
                : Self.wholePicture
            // Julian, 2026-08-17: the switch opens on whether corners were measured at
            // all, not on whether the engine approves of them - its veto is true on
            // almost every photo, and the handles are on screen to be dragged before
            // Apply. A stored answer is the user's own and is kept; the guard against
            // arming over the whole picture stays, there are no corners to send.
            pullFlat = stored != nil ? all.pullTheSheetFlat : measured
        }
        if only == nil || only == .straighten { angle = Double(all.straightenDegrees) }
        if only == nil || only == .brightness {
            black = Self.percent(all.black)
            white = Self.percent(all.white)
            tones = all.adjustTheTones
        }
        if only == nil || only == .sharpen { sharpen = Double(all.sharpenRadius) }
        if only == nil || only == .crop {
            // The box opens on the whole picture even where one is stored: the page on
            // screen is already the last cut, so there is no *further* cut yet, and the
            // engine's crop space is neither the photo nor the page. `ScanFlow` composes
            // this drag onto the stored one at Apply.
            box = Self.wholePicture
        }
        if only == nil || only == .turn { turns = Int(all.quarterTurns) }
        // Only a full seed. On open the screen has to show what was last applied without
        // spending an engine pass or overwriting the stored numbers. "Back to the
        // suggestion" on Straighten or Brightness puts back numbers that are already the
        // engine's answer for the sheet on screen, so it needs no forced re-measure; on
        // Edges it moves `sheet` and leaves this behind, which fires one by itself.
        if only == nil { measuredFor = (sheet, pullFlat) }
    }

    // MARK: - The values

    /// The screen as one struct for the engine. Only the corners become pixels here,
    /// against the photo; the crop is already the fraction the engine wants, held
    /// inside the picture so a box dragged past the edge cuts the edge.
    var values: Engine.Adjustments {
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
}
