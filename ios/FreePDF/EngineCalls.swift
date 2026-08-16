//  EngineCalls.swift - the four C calls, and the only place the boundary is crossed.
//
//  Split off `Engine.swift` so that the half of the app `../check/run.sh` compiles -
//  `Scan.swift` and the values it stores - stays Foundation only. Everything here needs
//  the bridging header; nothing there does. What crosses the boundary is C strings, a
//  size and an int32 (`../../ffi/AGENTS.md`).

import Foundation

extension Engine {
    /// One photo in, one finished page file out - deskewed, straightened, brightened,
    /// capped and sharpened, in that order.
    ///
    /// It either writes the whole page or nothing at all: the file wears its real name
    /// only after a complete write, which is what makes "page 7 exists" mean "page 7 is
    /// done" after a kill.
    static func scanPage(_ photo: URL, into page: URL) throws {
        try call { error, size in freepdf_scan_page(photo.path, page.path, error, size) }
    }

    /// Asks the engine what it would do by itself. Writes no file. It costs about as much
    /// as one scan, so it belongs in a detached task like the drain's.
    static func suggest(_ photo: URL) throws -> Suggestion {
        var out = FreepdfSuggestion()
        try call { error, size in freepdf_suggest_adjustments(photo.path, &out, error, size) }
        let c = out.values.corners
        return Suggestion(
            values: Adjustments(corners: [c.0, c.1, c.2, c.3, c.4, c.5, c.6, c.7],
                                pullTheSheetFlat: out.values.pull_the_sheet_flat != 0,
                                straightenDegrees: out.values.straighten_degrees,
                                black: [out.values.black.0, out.values.black.1, out.values.black.2],
                                white: [out.values.white.0, out.values.white.1, out.values.white.2],
                                adjustTheTones: out.values.adjust_the_tones != 0,
                                sharpenRadius: out.values.sharpen_radius,
                                cropX: out.values.crop_x, cropY: out.values.crop_y,
                                cropWidth: out.values.crop_width,
                                cropHeight: out.values.crop_height,
                                quarterTurns: out.values.quarter_turns,
                                grey: out.values.grey != 0),
            foundASheet: out.found_a_sheet != 0,
            fillsTheWholePhoto: out.fills_the_whole_photo != 0,
            runsOffThePicture: out.runs_off_the_picture != 0)
    }

    /// The same recipe as `scanPage`, with the user's values, written the same way: the
    /// page file is replaced whole by rename, or nothing is written at all.
    static func adjustPage(_ photo: URL, into page: URL, _ a: Adjustments) throws {
        let c = a.corners
        var values = FreepdfAdjustments(
            corners: (c[0], c[1], c[2], c[3], c[4], c[5], c[6], c[7]),
            pull_the_sheet_flat: a.pullTheSheetFlat ? 1 : 0,
            straighten_degrees: a.straightenDegrees,
            black: (a.black[0], a.black[1], a.black[2]),
            white: (a.white[0], a.white[1], a.white[2]),
            adjust_the_tones: a.adjustTheTones ? 1 : 0,
            sharpen_radius: a.sharpenRadius,
            crop_x: a.cropX, crop_y: a.cropY,
            crop_width: a.cropWidth, crop_height: a.cropHeight,
            quarter_turns: a.quarterTurns,
            grey: a.grey ? 1 : 0)
        try call { error, size in
            freepdf_adjust_page(photo.path, page.path, &values, error, size)
        }
    }

    /// The finished pages as one PDF, in the order given.
    ///
    /// The pages are named, never held: each JPEG goes in untouched and is never
    /// decoded, which is what lets forty pages fit in a phone's memory.
    static func pagesToPDF(_ pages: [URL], out pdf: URL) throws {
        let owned = pages.map { strdup($0.path)! }
        defer { owned.forEach { free($0) } }
        // Both spellings here are load-bearing and were found by the compiler: without
        // `strdup(…)!` and `UnsafePointer<CChar>` written out, Swift cannot work out the
        // element type of the array C is asking for and refuses the whole function.
        var paths: [UnsafePointer<CChar>?] = owned.map { UnsafePointer<CChar>($0) }
        try call { error, size in
            freepdf_pages_to_pdf(&paths, paths.count, pdf.path, error, size)
        }
    }

    /// 0 means it worked. Anything else means nothing was written and the buffer holds
    /// the sentence for the screen.
    ///
    /// The buffer belongs to this side and is copied into. A `freepdf_last_error()`
    /// thread-local would be one function fewer and would break the drain, which awaits
    /// a detached task between the call and reading the error.
    private static func call(_ body: (UnsafeMutablePointer<CChar>, Int) -> Int32) throws {
        var buffer = [CChar](repeating: 0, count: 512)
        guard body(&buffer, buffer.count) != 0 else { return }
        // The pointer overload, because the `[CChar]` one is deprecated in Swift 6.2.
        throw Failed(message: buffer.withUnsafeBufferPointer { String(cString: $0.baseAddress!) })
    }
}
