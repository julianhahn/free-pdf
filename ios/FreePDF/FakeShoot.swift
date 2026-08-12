//  FakeShoot.swift - the camera stand-in, and everything that props it up.
//
//  Milestone 5 replaces this whole file with the real camera. Nothing outside it knows
//  what a fake page looks like, and it reaches out of itself in exactly one place -
//  the `.task` line in `FreePDFApp.swift` - so deleting it is a file and a line.
//
//  The photo it writes is a real 12 MP JPEG through the same atomic write the camera
//  will use, because everything after it - the drain, the memory, the resume - has to
//  meet what the phone will really hand it.

import SwiftUI
import UIKit

struct FakeShoot: View {
    let scan: Scan
    /// The page number a shot lands on. `nil` means the next one, which is what
    /// shooting normally does; a number is a retake of that page.
    let slot: Int?
    /// Called when the user is finished shooting and wants the pages scanned.
    let finished: () -> Void

    @State private var photos: [Int] = []
    @State private var message: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Page \(slot ?? scan.nextPage)")
                .font(.headline)

            RoundedRectangle(cornerRadius: 12)
                .fill(.quaternary)
                .overlay(Text("No camera yet").foregroundStyle(.secondary))

            if let message {
                Text(message).font(.footnote).foregroundStyle(.red)
            }

            Button("Fake shoot", action: shoot)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

            // A retake is one shot, so it takes itself back to the pages afterwards.
            if slot == nil {
                Button(photos.isEmpty ? "Photograph at least one page"
                                      : "Scan \(pageCount(photos.count))") { finished() }
                    .disabled(photos.isEmpty)
            }
        }
        .padding()
        .navigationTitle(scan.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { photos = scan.photos }
        .task { await autoShoot() }
    }

    private func shoot() {
        let number = slot ?? scan.nextPage
        // A pool per shot: the drawing is a 48 MB bitmap, and twelve of them left to
        // pile up would be the one thing on this screen that could get the app killed.
        guard let jpeg = autoreleasepool(invoking: { Self.draw(page: number) }) else {
            message = "Page \(number) could not be drawn."
            return
        }
        do {
            // `.atomic`, so a kill mid-write leaves an aux file the sweep takes, never
            // half a photo wearing a real name. The camera writes the same way.
            try jpeg.write(to: scan.photoURL(number), options: .atomic)
            photos = scan.photos
            if slot != nil { finished() }
        } catch {
            // Never swallowed. A full disk at page 25 would otherwise keep the shutter
            // clicking and produce a 24-page PDF of a 40-page contract.
            message = "Page \(number) was not saved: \(error.localizedDescription) "
                + "Nothing already photographed is lost."
        }
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

// MARK: - The taps the check cannot make

extension FakeShoot {
    /// How many pages `-autofake` should shoot, or nil on every real launch.
    ///
    /// There is no way to tap a simulator from a script: `simctl` has no touch command,
    /// and AppleScript is not allowed near it without a human granting assistive access.
    /// So the two taps that drive a scan - shoot, then "Scan 12 pages" - are made here
    /// instead, and `../check/scan_check.sh` is one command because of it.
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

    /// Shoots until the wanted number is on disk, then asks for them to be scanned.
    ///
    /// It stops on the first failure rather than trying for ever, because `shoot` writes
    /// the sentence into `message` instead of throwing.
    private func autoShoot() async {
        guard let wanted = Self.pagesWanted, slot == nil else { return }
        // A scan that already has pages belongs on the progress line, not in the
        // viewfinder. Pressing on from here would hide exactly that bug from the check,
        // which cannot see which screen the app is on - only the files it writes. So it
        // does nothing instead, and the check runs out of pages and says so.
        guard scan.pages.isEmpty else { return }
        // Counted off the disk, not off the copy above: this runs before the copy is
        // first filled in, and shooting one page too many would be the result.
        while scan.photos.count < wanted, message == nil {
            shoot()
        }
        if message == nil { finished() }
    }
}
