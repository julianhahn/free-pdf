//  FakeShoot.swift - the camera stand-in: a drawn page, and the taps no script can make.
//
//  A simulator has no camera at all - iOS 26.2 on "iPhone 17 Pro" reports zero video
//  devices, only a microphone - so this is what keeps the app usable there. The shutter
//  draws a sheet of paper instead of photographing one, and `-autofake N` presses it N
//  times, which is what lets [`../check/scan_check.sh`](../check/scan_check.sh) drive a
//  whole scan without hands.
//
//  It is not the camera screen and knows nothing about AVFoundation
//  ([`CameraView.swift`](./CameraView.swift) is that). Deleting it costs the only
//  end-to-end check there is, so it stays until something can tap a simulator.

import UIKit

enum FakeShoot {
    /// How many pages `-autofake` should shoot, or nil on every real launch.
    ///
    /// There is no way to tap a simulator from a script: `simctl` has no touch command,
    /// and AppleScript is not allowed near it without a human granting assistive
    /// access. So the two taps that drive a scan - shoot, then "Scan 12 pages" - are
    /// made here instead, and `../check/scan_check.sh` is one command because of it.
    static var pagesWanted: Int? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flag = arguments.firstIndex(of: "-autofake"),
              arguments.indices.contains(flag + 1)
        else { return nil }
        return Int(arguments[flag + 1])
    }

    /// The scan `-autofake` lands on: the newest unfinished one, or a new one.
    ///
    /// Both launches of the check use it. The first finds nothing and makes a scan; the
    /// one after the kill finds the half-scanned scan and opens it, which is the tap the
    /// user would make on the row.
    static func scanToOpen() -> Scan? {
        guard pagesWanted != nil else { return nil }
        return Scan.all().first { $0.state != .done } ?? (try? Scan.create())
    }

    /// A shot that did not land, and which kind it is, so the screen can put it where it
    /// belongs without reading the sentence. Each carries its sentence, written in one
    /// place in `write` below and shown unchanged.
    enum Failure {
        /// A page that missed the disk.
        case notSaved(String)
        /// The one kind that is about the screen rather than about a page: nothing was
        /// photographed and nothing can be, so the screen says so and offers nothing.
        case notDrawn(String)
    }

    /// Draws one page and writes it exactly the way the camera writes a real one.
    ///
    /// - Returns: nil when the file is on disk, or the failure for the screen.
    static func write(page number: Int, into scan: Scan) -> Failure? {
        // A pool per shot: the drawing is a 48 MB bitmap, and twelve of them left to
        // pile up would be the one thing on this screen that could get the app killed.
        guard let jpeg = autoreleasepool(invoking: { draw(page: number) }) else {
            return .notDrawn("Page \(number) could not be drawn.")
        }
        do {
            // `.atomic`, so a kill mid-write leaves an aux file the sweep takes, never
            // half a photo wearing a real name. The camera writes the same way.
            try jpeg.write(to: scan.photoURL(number), options: .atomic)
            return nil
        } catch {
            // Never swallowed. A full disk at page 25 would otherwise keep the shutter
            // clicking and produce a 24 page PDF of a 40 page contract.
            return .notSaved(pageNotSaved(number, error.localizedDescription))
        }
    }

    /// Shoots until the wanted number is on disk, then asks for them to be scanned.
    ///
    /// It stops on the first failure rather than trying for ever, and hands the failure
    /// back for the screen to show.
    ///
    /// - Returns: the failure that stopped it, or nil - which also means "nothing to
    ///   do here", because on a phone `pagesWanted` is nil.
    static func autoShoot(_ scan: Scan, finished: () -> Void) -> Failure? {
        guard let wanted = pagesWanted else { return nil }
        // A scan that already has pages belongs on the progress line, not in the
        // viewfinder. Pressing on from here would hide exactly that bug from the check,
        // which cannot see which screen the app is on - only the files it writes. So it
        // does nothing instead, and the check runs out of pages and says so.
        guard scan.pages.isEmpty else { return nil }
        var failure: Failure?
        // Counted off the disk, so shooting one page too many cannot happen.
        while scan.photos.count < wanted, failure == nil {
            failure = write(page: scan.nextPage, into: scan)
        }
        if failure == nil { finished() }
        return failure
    }

    /// A sheet of paper on a table, drawn rather than photographed, at the size a 12 MP
    /// iPhone photo really is - so what the drain does next is measured against what the
    /// camera will hand it, not against a small picture.
    ///
    /// Grey table under a white sheet, because a white page filling the frame gives
    /// `find_paper` no edge to find and `deskew` would never run. The writing is dead
    /// straight on purpose: a page whose writing is crooked by ten degrees or more
    /// cannot be scanned at all today (the engine bug parked in the README), and it
    /// fails the same way every time, so the drain would retry that photo for ever.
    private static func draw(page number: Int) -> Data? {
        let size = CGSize(width: 3024, height: 4032)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1                  // pixels, not points, or this is nine times bigger
        let photo = UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor(white: 0.35, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let sheet = CGRect(x: 210, y: 280, width: size.width - 420, height: size.height - 560)
            UIColor.white.setFill()
            context.fill(sheet)

            UIColor(white: 0.1, alpha: 1).setFill()
            for line in 0..<24 {
                // Every fourth line is short, so a page looks like paragraphs rather
                // than a barcode - and `suggest_straightening` reads real line ends.
                let width = sheet.width * (line % 4 == 3 ? 0.45 : 0.86)
                context.fill(CGRect(x: sheet.minX + 120,
                                    y: sheet.minY + 540 + CGFloat(line) * 120,
                                    width: width,
                                    height: 26))
            }
            "\(number)".draw(at: CGPoint(x: sheet.minX + 120, y: sheet.minY + 180),
                             withAttributes: [.font: UIFont.systemFont(ofSize: 160),
                                              .foregroundColor: UIColor.black])
        }
        return photo.jpegData(compressionQuality: 0.9)
    }
}
