//  Engine.swift - the engine, and the only way the app reaches it.
//
//  Two C functions, nothing else: no image work and no PDF work belongs on this side
//  of the boundary. What crosses it is C strings, a size and an int32
//  (`../../ffi/AGENTS.md`).

import Foundation

enum Engine {
    /// What the engine said went wrong, in the sentence it wrote. The app shows it
    /// unchanged, because a finished English sentence is what the engine promises to
    /// return (`../../AGENTS.md`).
    struct Failed: Error, LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    /// One photo in, one finished page file out - deskewed, straightened, brightened,
    /// capped and sharpened, in that order.
    ///
    /// It either writes the whole page or nothing at all: the file wears its real name
    /// only after a complete write, which is what makes "page 7 exists" mean "page 7 is
    /// done" after a kill.
    static func scanPage(_ photo: URL, into page: URL) throws {
        try call { error, size in freepdf_scan_page(photo.path, page.path, error, size) }
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
