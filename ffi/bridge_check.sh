#!/usr/bin/env bash
# The check for milestone 2: is the C surface really callable from Swift, and does a
# photo come out of it as a page and a PDF?
#
# Host architecture on purpose. The boundary a phone crosses is the same one this
# crosses, so no simulator and no Xcode are needed to see it work - and the Swift
# side is compiled with -import-objc-header, which is the same mechanism as Xcode's
# bridging header setting.
set -euo pipefail
cd "$(dirname "$0")/.."

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# The panic branch of guard() has no input that reaches it, so it is checked in Rust
# rather than through Swift (see ffi/src/lib.rs). Release, so it shares the build
# below instead of asking for a second one.
cargo test -p core_engine_ffi --release --quiet
cargo build -p core_engine_ffi --release --quiet

cat > "$work/check.swift" <<'SWIFT'
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// precondition, never assert: assert() is compiled out under -O, which would leave a
// check that passes without checking anything.

let work = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let errorSize = 512

/// One call across the boundary, exactly as the app will make it: a status, and a
/// sentence read out of a buffer the caller owns.
func call(_ body: (UnsafeMutablePointer<CChar>?, Int) -> Int32) -> (status: Int32, message: String) {
    var error = [CChar](repeating: 0, count: errorSize)
    let status = body(&error, errorSize)
    return (status, error.withUnsafeBufferPointer { String(cString: $0.baseAddress!) })
}

func pixelSize(of file: URL) -> (width: Int, height: Int) {
    guard let source = CGImageSourceCreateWithURL(file as CFURL, nil),
          let shape = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
          let width = shape[kCGImagePropertyPixelWidth] as? Int,
          let height = shape[kCGImagePropertyPixelHeight] as? Int
    else { fatalError("\(file.path) cannot be read as an image") }
    return (width, height)   // read from the header, so the page is not decoded here
}

/// A photograph-like page: light paper filling the frame, with lines of writing on
/// it. Written here rather than kept in the repository, because the one real photo
/// there is a private letter.
func writePhoto(_ file: URL, width: Int, height: Int) {
    guard let canvas = CGContext(data: nil, width: width, height: height,
                                 bitsPerComponent: 8, bytesPerRow: 0,
                                 space: CGColorSpaceCreateDeviceRGB(),
                                 bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
    else { fatalError("no drawing context") }

    canvas.setFillColor(CGColor(red: 0.90, green: 0.89, blue: 0.86, alpha: 1))
    canvas.fill(CGRect(x: 0, y: 0, width: width, height: height))
    canvas.setFillColor(CGColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1))
    var line = Double(height) / 20
    while line < Double(height) - Double(height) / 20 {
        canvas.fill(CGRect(x: Double(width) / 16, y: line,
                           width: Double(width) * 0.78, height: Double(height) / 170))
        line += Double(height) / 25
    }

    guard let image = canvas.makeImage(),
          let destination = CGImageDestinationCreateWithURL(
              file as CFURL, UTType.jpeg.identifier as CFString, 1, nil)
    else { fatalError("no image") }
    CGImageDestinationAddImage(
        destination, image, [kCGImageDestinationLossyCompressionQuality: 0.9] as CFDictionary)
    precondition(CGImageDestinationFinalize(destination), "could not write \(file.path)")
}

// 1 - a photo that is not there: a failure, and a sentence naming the file, because
// that name is the only clue the user gets.
let absent = call { error, size in
    freepdf_scan_page("/no/such/photo.jpg", work.appendingPathComponent("x.jpg").path, error, size)
}
precondition(absent.status != 0, "a missing photo reported success")
precondition(absent.message.contains("/no/such/photo.jpg"),
             "the sentence does not name the file: \(absent.message)")

// 2 - no path at all. A bug in the app, but it has to come back as a sentence.
let nothing = call { error, size in
    freepdf_scan_page(nil, work.appendingPathComponent("x.jpg").path, error, size)
}
precondition(nothing.status != 0 && !nothing.message.isEmpty,
             "a null path gave no sentence: \(nothing.status) \(nothing.message)")

// 3 - a caller that wants the status only. Both shapes of it, because passing NULL
// with a size is the mistake that actually happens.
let page = work.appendingPathComponent("0001.jpg")
precondition(freepdf_scan_page("/no/such/photo.jpg", page.path, nil, 0) != 0,
             "a call with no error buffer did not report the failure")
precondition(freepdf_scan_page("/no/such/photo.jpg", page.path, nil, errorSize) != 0,
             "a call with a null buffer and a size did not report the failure")

// 4 - the real thing. 3200 px in, and the page comes back at the 3000 px cap.
let photo = work.appendingPathComponent("photo.jpg")
writePhoto(photo, width: 3200, height: 2400)
let scanned = call { error, size in freepdf_scan_page(photo.path, page.path, error, size) }
precondition(scanned.status == 0, "scanning the photo failed: \(scanned.message)")
let size = pixelSize(of: page)
precondition(max(size.width, size.height) == 3000,
             "the page is \(size.width)x\(size.height), so the 3000 px cap did not hold")

// 5 - and the pages become a PDF. Two of them, so the array really is walked.
let pdf = work.appendingPathComponent("scan.pdf")
// Written exactly as the app's wrapper has to write it: `strdup(...)!` so the copies
// are not optional, and `UnsafePointer<CChar>` spelled out, because `UnsafePointer($0)`
// alone leaves Swift unable to work out the element type of the array C wants.
let paths: [String] = [page.path, page.path]
let owned = paths.map { strdup($0)! }
defer { owned.forEach { free($0) } }
var pages: [UnsafePointer<CChar>?] = owned.map { UnsafePointer<CChar>($0) }
let built = call { error, size in
    freepdf_pages_to_pdf(&pages, pages.count, pdf.path, error, size)
}
precondition(built.status == 0, "building the PDF failed: \(built.message)")
guard let bytes = try? Data(contentsOf: pdf) else { fatalError("no PDF at \(pdf.path)") }
precondition(String(decoding: bytes.suffix(16), as: UTF8.self).contains("%%EOF"),
             "the PDF does not end in %%EOF")
SWIFT

# No -O: a failing `precondition` prints its sentence only in an unoptimised build,
# and a check that aborts without saying what it saw is half a check. Nothing here is
# slow on the Swift side anyway - every heavy step happens inside the library.
swiftc -import-objc-header ffi/include/freepdf.h \
    -L target/release -lfreepdf \
    -o "$work/check" "$work/check.swift"

"$work/check" "$work"
echo "bridge ok"
