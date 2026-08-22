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
    freepdf_scan_page("/no/such/photo.jpg", work.appendingPathComponent("x.jpg").path,
                      nil, error, size)
}
precondition(absent.status != 0, "a missing photo reported success")
precondition(absent.message.contains("/no/such/photo.jpg"),
             "the sentence does not name the file: \(absent.message)")

// 2 - no path at all. A bug in the app, but it has to come back as a sentence.
let nothing = call { error, size in
    freepdf_scan_page(nil, work.appendingPathComponent("x.jpg").path, nil, error, size)
}
precondition(nothing.status != 0 && !nothing.message.isEmpty,
             "a null path gave no sentence: \(nothing.status) \(nothing.message)")

// 3 - a caller that wants the status only. Both shapes of it, because passing NULL
// with a size is the mistake that actually happens.
let page = work.appendingPathComponent("0001.jpg")
precondition(freepdf_scan_page("/no/such/photo.jpg", page.path, nil, nil, 0) != 0,
             "a call with no error buffer did not report the failure")
precondition(freepdf_scan_page("/no/such/photo.jpg", page.path, nil, nil, errorSize) != 0,
             "a call with a null buffer and a size did not report the failure")

// 4 - the real thing. 3200 px in, and the page comes back at the 3000 px cap. The
// rung is nil here, which means Original: the page every one of these calls wrote
// before FreepdfPageQuality existed. That it is that page byte for byte is pinned in
// Rust, where the numbers can be read off the commit that wrote it - the engine test
// `the_default_quality_writes_the_very_same_page_as_before`, and
// `no_rung_at_all_writes_the_same_page_as_the_original_rung` in src/lib.rs. What can
// be seen from here is its size, and its size is the cap.
let photo = work.appendingPathComponent("photo.jpg")
writePhoto(photo, width: 3200, height: 2400)
let scanned = call { error, size in freepdf_scan_page(photo.path, page.path, nil, error, size) }
precondition(scanned.status == 0, "scanning the photo failed: \(scanned.message)")
let size = pixelSize(of: page)
precondition(max(size.width, size.height) == 3000,
             "the page is \(size.width)x\(size.height), so the 3000 px cap did not hold")

// 4a - a rung really crosses: a smaller longest edge gives a page of that size. Both
// numbers at once, which is the rung a user picking "Smallest" gets.
let smallest = work.appendingPathComponent("0009.jpg")
var smallestRung = FreepdfPageQuality(jpeg_quality: 45, longest_edge: 1700)
let atARung = call { error, size in
    freepdf_scan_page(photo.path, smallest.path, &smallestRung, error, size)
}
precondition(atARung.status == 0, "the rung was refused: \(atARung.message)")
let rungSize = pixelSize(of: smallest)
precondition(max(rungSize.width, rungSize.height) == 1700,
             "the page is \(rungSize.width)x\(rungSize.height), so the rung's 1700 px edge did not arrive")

// 4b - the quality on its own, at Original's size. A page shrunk to 1700 px would be
// smaller whatever quality it was written at, so this is the only check that sees the
// quality arrive: same pixels, fewer bytes.
let originalBytes = (try! Data(contentsOf: page)).count
let lessQuality = work.appendingPathComponent("0010.jpg")
var lessQualityRung = FreepdfPageQuality(jpeg_quality: 45, longest_edge: 0)
let atLowQuality = call { error, size in
    freepdf_scan_page(photo.path, lessQuality.path, &lessQualityRung, error, size)
}
precondition(atLowQuality.status == 0, "the low quality was refused: \(atLowQuality.message)")
let lessQualitySize = pixelSize(of: lessQuality)
precondition(max(lessQualitySize.width, lessQualitySize.height) == 3000,
             "a rung that asked for every pixel came out at \(lessQualitySize.width)x\(lessQualitySize.height)")
let lessQualityBytes = (try! Data(contentsOf: lessQuality)).count
precondition(lessQualityBytes < originalBytes,
             "quality 45 wrote \(lessQualityBytes) bytes against Original's \(originalBytes), so the quality did not arrive")

// 4c - a quality no encoder counts in is refused in a sentence, and no page is left
// behind. It is not pulled back into range: a page quietly written at another quality
// than the user picked makes the whole setting look like it does nothing.
let refusedPage = work.appendingPathComponent("0011.jpg")
var noQuality = FreepdfPageQuality(jpeg_quality: 0, longest_edge: 0)
let refused = call { error, size in
    freepdf_scan_page(photo.path, refusedPage.path, &noQuality, error, size)
}
precondition(refused.status != 0, "a page quality of 0 was accepted")
precondition(refused.message.contains("quality") && refused.message.contains("100"),
             "the sentence does not say what a quality may be: \(refused.message)")
precondition(!FileManager.default.fileExists(atPath: refusedPage.path),
             "a refused page was written anyway: \(refusedPage.path)")

// 5 - the adjusted case, which is the only place a struct crosses. A quarter turn
// and a crop, so the page cannot come back the shape the automatic run gives it.
let adjusted = work.appendingPathComponent("0002.jpg")
var values = FreepdfAdjustments()
values.straighten_degrees = 2.0
values.sharpen_radius = 1.0
values.crop_x = 0.1
values.crop_y = 0.1
values.crop_width = 0.4
values.crop_height = 0.6
values.quarter_turns = 1
values.grey = 1
let turned = call { error, size in
    freepdf_adjust_page(photo.path, adjusted.path, &values, nil, error, size)
}
precondition(turned.status == 0, "adjusting the photo failed: \(turned.message)")
let turnedSize = pixelSize(of: adjusted)
// A quarter turn first, so the 3000x2250 page becomes 2250x3000, and the crop then takes
// 0.4 of that width and 0.6 of that height.
precondition(turnedSize.width == 900 && turnedSize.height == 1800,
             "the adjusted page is \(turnedSize.width)x\(turnedSize.height), so crop and turn did not happen")

// 5c - the crop is a fraction, not pixels: the same values out of two photos of
// different size have to cut the same relative piece. Pixels would cut a different
// piece out of the smaller one, or be refused by it altogether.
let small = work.appendingPathComponent("small.jpg")
writePhoto(small, width: 1600, height: 1200)
var sameCut = FreepdfAdjustments()
sameCut.crop_x = 0.25
sameCut.crop_y = 0.25
sameCut.crop_width = 0.5
sameCut.crop_height = 0.25
func cutSize(_ from: URL, _ into: String) -> (width: Int, height: Int) {
    let out = work.appendingPathComponent(into)
    let done = call { error, size in
        freepdf_adjust_page(from.path, out.path, &sameCut, nil, error, size)
    }
    precondition(done.status == 0, "the fraction crop was refused: \(done.message)")
    return pixelSize(of: out)
}
let bigCut = cutSize(photo, "0006.jpg")
let smallCut = cutSize(small, "0007.jpg")
precondition(abs(Double(bigCut.width) / Double(bigCut.height)
                 - Double(smallCut.width) / Double(smallCut.height)) < 0.02,
             "the same fraction cut \(bigCut.width)x\(bigCut.height) and \(smallCut.width)x\(smallCut.height), so it is not a fraction of each image")
precondition(bigCut.width > smallCut.width,
             "the bigger photo did not give the bigger cut: \(bigCut.width) vs \(smallCut.width)")

// 5d - a box that reaches the far edge is not refused by rounding. Each edge rounds on
// its own, so 1/3 and 2/3 can add up to one pixel past the image.
var toTheEdge = FreepdfAdjustments()
toTheEdge.crop_x = 1.0 / 3.0
toTheEdge.crop_width = 2.0 / 3.0
toTheEdge.crop_y = 1.0 / 3.0
toTheEdge.crop_height = 2.0 / 3.0
let atTheEdge = call { error, size in
    freepdf_adjust_page(photo.path, work.appendingPathComponent("0008.jpg").path,
                        &toTheEdge, nil, error, size)
}
precondition(atTheEdge.status == 0, "a crop reaching the far edge was refused: \(atTheEdge.message)")

// 5a - the three colours are kept apart. The same photo twice, black points that
// differ only in the green channel: a page that came back byte for byte the same
// would mean the struct carries one value onto all three, which is the copy that
// puts the colour cast back.
let evenly = work.appendingPathComponent("0004.jpg")
let perChannel = work.appendingPathComponent("0005.jpg")
var levels = FreepdfAdjustments()
levels.adjust_the_tones = 1
levels.black = (20, 20, 20)
levels.white = (200, 200, 200)
precondition(call { error, size in
    freepdf_adjust_page(photo.path, evenly.path, &levels, nil, error, size)
}.status == 0, "the even levels were refused")
levels.black = (20, 90, 20)
precondition(call { error, size in
    freepdf_adjust_page(photo.path, perChannel.path, &levels, nil, error, size)
}.status == 0, "the per channel levels were refused")
precondition(try! Data(contentsOf: evenly) != Data(contentsOf: perChannel),
             "one channel's black point changed nothing, so the three colours are not kept apart")

// 5b - the suggestion. The generated photo is a sheet filling the frame, so the
// engine has to say so, and the corners have to land inside the photo it was read
// from - that is the whole claim the header makes about their pixel space.
var suggestion = FreepdfSuggestion()
let suggested = call { error, size in
    freepdf_suggest_adjustments(photo.path, nil, &suggestion, error, size)
}
precondition(suggested.status == 0, "suggesting failed: \(suggested.message)")
precondition(suggestion.found_a_sheet != 0 && suggestion.fills_the_whole_photo != 0,
             "the sheet fills the photo, but the engine did not say so")
let corners = withUnsafeBytes(of: suggestion.values.corners) { Array($0.bindMemory(to: Float.self)) }
for pair in 0..<4 {
    precondition(corners[pair * 2] >= 0 && corners[pair * 2] <= 3200
                 && corners[pair * 2 + 1] >= 0 && corners[pair * 2 + 1] <= 2400,
                 "corner \(pair) is \(corners[pair * 2]),\(corners[pair * 2 + 1]), outside the 3200x2400 photo")
}
// And what it suggests is something freepdf_adjust_page accepts unchanged.
let asSuggested = work.appendingPathComponent("0003.jpg")
let reused = call { error, size in
    freepdf_adjust_page(photo.path, asSuggested.path, &suggestion.values, nil, error, size)
}
precondition(reused.status == 0, "the suggested values were refused: \(reused.message)")

// 5e - the angle AND the two tone points are measured against the sheet it was handed.
// The same photo asked twice: once with NULL, which is the engine's own sheet, and once
// with a sheet turned a few degrees off it. Turned corners mean writing that comes out
// turned, so the two answers cannot be the same number. If they are, the corners handed
// in were ignored, and the app would put an angle on the slider that belongs to a page
// it never makes. The Adjust screen puts the whole answer back on its controls when the
// corners move, so the tone points have to follow the handed-in sheet as well.
var turnedSheet = suggestion.values
turnedSheet.pull_the_sheet_flat = 1
let middle = (x: (corners[0] + corners[2] + corners[4] + corners[6]) / 4,
              y: (corners[1] + corners[3] + corners[5] + corners[7]) / 4)
let byDegrees = Float(6) * .pi / 180
withUnsafeMutableBytes(of: &turnedSheet.corners) { raw in
    let point = raw.bindMemory(to: Float.self)
    for pair in 0..<4 {
        // Pulled in to four fifths first, so six degrees of turn cannot push a corner
        // off a sheet that already fills the frame.
        let dx = (point[pair * 2] - middle.x) * 0.8, dy = (point[pair * 2 + 1] - middle.y) * 0.8
        point[pair * 2] = middle.x + dx * cos(byDegrees) - dy * sin(byDegrees)
        point[pair * 2 + 1] = middle.y + dx * sin(byDegrees) + dy * cos(byDegrees)
    }
}
var forTheirSheet = FreepdfSuggestion()
let asked = call { error, size in
    freepdf_suggest_adjustments(photo.path, &turnedSheet, &forTheirSheet, error, size)
}
precondition(asked.status == 0, "suggesting for the caller's own sheet failed: \(asked.message)")
precondition(forTheirSheet.values.straighten_degrees != suggestion.values.straighten_degrees,
             "a sheet turned six degrees came back with the same straightening angle "
             + "(\(suggestion.values.straighten_degrees)), so the corners handed in were ignored")
// The tone points are read off the picture after that same deskew and that same
// straightening, so a sheet turned six degrees puts different pixels inside the paper
// and cannot come back with both points unchanged. If it does, `suggest_levels` is
// being run before the handed-in corners reach the deskew, and Adjust would send
// Apply a black and a white point measured on the frame the user just corrected.
precondition(forTheirSheet.values.black != suggestion.values.black
             || forTheirSheet.values.white != suggestion.values.white,
             "a sheet turned six degrees came back with the same tone points "
             + "(black \(suggestion.values.black), white \(suggestion.values.white)), "
             + "so the levels were not measured against the corners handed in")
// And the corners handed back stay the engine's own, whichever sheet was asked about:
// that is what "Back to the suggestion" reads.
let theirCorners = withUnsafeBytes(of: forTheirSheet.values.corners) { Array($0.bindMemory(to: Float.self)) }
precondition(theirCorners == corners,
             "the corners handed back changed with the sheet that was asked about")

// 5f - the adjusted case takes a rung as well, on its own pointer. Values that change
// nothing, so the only thing that can shape this page is the rung: 3200 px in, 1700 out.
let adjustedSmall = work.appendingPathComponent("0012.jpg")
var nothingToAdjust = FreepdfAdjustments()
let atARungAdjusted = call { error, size in
    freepdf_adjust_page(photo.path, adjustedSmall.path, &nothingToAdjust, &smallestRung, error, size)
}
precondition(atARungAdjusted.status == 0, "the adjusted rung was refused: \(atARungAdjusted.message)")
let adjustedSmallSize = pixelSize(of: adjustedSmall)
precondition(max(adjustedSmallSize.width, adjustedSmallSize.height) == 1700,
             "the adjusted page is \(adjustedSmallSize.width)x\(adjustedSmallSize.height), so the rung did not reach it")

// 6 - and the pages become a PDF. Two of them, so the array really is walked.
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
