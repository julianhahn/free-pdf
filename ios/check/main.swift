//  The check for milestone 3: does the model come back correctly after the process
//  dies? Twelve moments - ten where it is killed, and two the user reaches on his own.
//
//  Real files in a temporary directory, because that is the model's only input - and
//  Foundation only, so this runs in about two seconds with no Xcode and no simulator.
//
//  precondition, never assert: `assert` is compiled out under -O, which would leave a
//  check that passes without checking anything.

import Foundation

let workspace = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let scansRoot = workspace.appendingPathComponent("Scans", isDirectory: true)
let shelf = workspace.appendingPathComponent("Order", isDirectory: true)

// MARK: - Putting a scan on disk in the state a kill would have left it in

/// The content is a marker, never a real JPEG: nothing in `Scan` opens a file, and this
/// check is about names and moments.
func write(_ text: String, to url: URL) {
    do { try Data(text.utf8).write(to: url, options: .atomic) }
    catch { fatalError("could not write \(url.path): \(error.localizedDescription)") }
}

func newScan(in root: URL = scansRoot, at date: Date = Date()) -> Scan {
    do { return try Scan.create(in: root, at: date) }
    catch { fatalError("could not create a scan in \(root.path): \(error.localizedDescription)") }
}

func shoot(_ scan: Scan, _ numbers: [Int]) {
    for number in numbers { write("photo \(number)", to: scan.photoURL(number)) }
}

func scanned(_ scan: Scan, _ numbers: [Int]) {
    for number in numbers { write("page \(number)", to: scan.pageURL(number)) }
}

func fileNames(in directory: URL) -> [String] {
    ((try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []).sorted()
}

func exists(_ url: URL) -> Bool { FileManager.default.fileExists(atPath: url.path) }

// MARK: - 1. Killed right after New scan

// A folder and nothing in it. The row reads "No pages yet", and the tap lands on the
// viewfinder at page 1 - not on a progress bar, and not on an error.
let fresh = newScan()
precondition(fresh.state == .empty, "a new scan is \(fresh.state), not .empty")
precondition(fresh.nextPage == 1, "a new scan starts at page \(fresh.nextPage)")
precondition(fresh.photos.isEmpty && fresh.pages.isEmpty, "a new scan already has files")

// MARK: - 2. Killed mid-shooting

// Eight photos, nothing scanned yet. He gets the camera back, and the counter shows the
// next number read from the disk.
let shooting = newScan()
shoot(shooting, Array(1...8))
precondition(shooting.state == .shooting, "eight photos and no pages is \(shooting.state)")
precondition(shooting.nextPage == 9, "the counter would say page \(shooting.nextPage)")

// MARK: - 3. Killed while scanning page 7 of 12

// The six finished pages are done for good, and the half-written seventh does not count
// as one. Only what has no page file is scanned again.
let interrupted = newScan()
shoot(interrupted, Array(1...12))
scanned(interrupted, Array(1...6))
write("half a page", to: interrupted.pageDirectory.appendingPathComponent("0007.part"))
precondition(interrupted.state == .scanning, "a cut-off scan is \(interrupted.state)")
precondition(interrupted.unscanned == Array(7...12),
             "the drain would redo \(interrupted.unscanned)")

let finished = Array(1...6).map { (try? Data(contentsOf: interrupted.pageURL($0))) ?? Data() }
interrupted.sweep()
precondition(interrupted.pages == Array(1...6), "the sweep lost a finished page")
precondition(Array(1...6).map({ try? Data(contentsOf: interrupted.pageURL($0)) }) == finished,
             "a finished page was rewritten, so the work was done twice")

// MARK: - 4. Killed after the last page was scanned

// Nothing left to do, so he lands on the carousel with Make PDF, not on a progress bar.
let ready = newScan()
shoot(ready, Array(1...12))
scanned(ready, Array(1...12))
precondition(ready.state == .ready, "all twelve pages scanned is \(ready.state)")
precondition(ready.unscanned.isEmpty, "still to scan: \(ready.unscanned)")

// MARK: - 5. scan.pdf is there and the pages are not

// The PDF existing is the whole definition of finished, so it wins over everything else
// the folder says. Without this, deleting the photos would drop a finished scan back
// into the camera.
let done = newScan()
shoot(done, [1, 2, 3])
write("%PDF-1.7 … %%EOF", to: done.pdf)
precondition(done.state == .done, "a scan with a PDF is \(done.state)")

// And the sweep leaves it alone. It is the one file in the scan folder that is not
// debris, so a sweep that took it would silently unfinish a finished scan.
done.sweep()
precondition(done.state == .done, "the sweep turned a finished scan into \(done.state)")

// MARK: - 6. Debris

// None of it is visible to a reader before the sweep, and none of it survives one.
let messy = newScan()
shoot(messy, [1, 2])
scanned(messy, [1, 2])
write("half a page", to: messy.pageDirectory.appendingPathComponent("0007.part"))
write("aux file", to: messy.pageDirectory.appendingPathComponent(".dat.nosync4f1a"))
write("hand-copied", to: messy.photoDirectory.appendingPathComponent("IMG_0042.jpg"))
write("wrong suffix", to: messy.photoDirectory.appendingPathComponent("0003.jpeg"))
write("a cut-off PDF", to: messy.url.appendingPathComponent("scan.part"))
// One name per guard in `pageNumber`, or the guards are only ever tested together: five
// digits reaches the length, a minus sign reaches the digits-only rule, and four digits
// with the wrong suffix reaches the suffix.
write("five digits", to: messy.photoDirectory.appendingPathComponent("00071.jpg"))
write("a minus sign", to: messy.photoDirectory.appendingPathComponent("-123.jpg"))
write("four digits, wrong suffix", to: messy.photoDirectory.appendingPathComponent("0009.tmp"))

precondition(messy.photos == [1, 2] && messy.pages == [1, 2],
             "debris is visible: photos \(messy.photos), pages \(messy.pages)")
precondition(messy.state == .ready, "debris moved the scan to \(messy.state)")
precondition(messy.nextPage == 3, "debris moved the counter to page \(messy.nextPage)")

messy.sweep()
precondition(fileNames(in: messy.photoDirectory) == ["0001.jpg", "0002.jpg"],
             "photo/ after the sweep: \(fileNames(in: messy.photoDirectory))")
precondition(fileNames(in: messy.pageDirectory) == ["0001.jpg", "0002.jpg"],
             "page/ after the sweep: \(fileNames(in: messy.pageDirectory))")
precondition(fileNames(in: messy.url) == ["page", "photo"],
             "the scan folder after the sweep: \(fileNames(in: messy.url))")

// MARK: - 7. An orphan page file

// A page whose photo was deleted. There is nothing left to scan, so the scan is ready -
// a count comparison would wedge it in .scanning for ever.
let orphan = newScan()
shoot(orphan, [1, 2])
scanned(orphan, [1, 2, 3])
precondition(orphan.unscanned.isEmpty, "still to scan: \(orphan.unscanned)")
precondition(orphan.state == .ready,
             "\(orphan.pages.count) pages against \(orphan.photos.count) photos "
             + "wedged the scan in \(orphan.state)")

// MARK: - 8. A page deleted in the middle

// The gap stays. Nothing is renumbered, so every sheet keeps the number it was shot as.
let gap = newScan()
shoot(gap, [1, 2, 4])
scanned(gap, [1, 2, 4])
precondition(gap.photos == [1, 2, 4], "the gap closed: \(gap.photos)")
precondition(gap.state == .ready, "a scan with a gap is \(gap.state)")
precondition(gap.nextPage == 5, "the next shot would be page \(gap.nextPage)")

// MARK: - 9. The highest number is an orphan page

// The photo of page 4 is gone and its page file is not. Handing 4 out again would put a
// page from another sheet into the PDF, so the counter goes past it.
let highest = newScan()
shoot(highest, [1, 2, 3])
scanned(highest, [1, 2, 3, 4])
precondition(highest.nextPage == 5, "the next shot would reuse page \(highest.nextPage)")

// MARK: - 10. The list is newest first

// From the folder names alone, without reading one file attribute - and a stray file in
// there is not a scan.
//
// The three moments straddle a new year, and the newest falls on a lower day of the month
// than the oldest, so a name that leads with the day cannot pass this. The two on one day
// are a second apart, so the time of day cannot be dropped either.
let oldest = newScan(in: shelf, at: Date(timeIntervalSince1970: 1_766_664_000))  // 25 Dec 2025
let middle = newScan(in: shelf, at: Date(timeIntervalSince1970: 1_799_150_399))  // 5 Jan 2027
let newest = newScan(in: shelf, at: Date(timeIntervalSince1970: 1_799_150_400))  // one second later
write("junk", to: shelf.appendingPathComponent(".DS_Store"))

let listed = Scan.all(in: shelf).map { $0.url.lastPathComponent }
precondition(listed == [newest, middle, oldest].map { $0.url.lastPathComponent },
             "the list reads \(listed)")

// And the date in it is the real date, checked down a path that shares no code with the
// one that wrote it. A POSIX formatter is Gregorian whatever the phone's calendar setting
// says, which is the era the sort key has to be written in: a phone set to the Buddhist
// calendar would write 2569 here, and one Japanese era change resets the year to 1.
let gregorian = DateFormatter()
gregorian.locale = Locale(identifier: "en_US_POSIX")
gregorian.dateFormat = "yyyy-MM-dd_HHmmss"
let expected = gregorian.string(from: Date(timeIntervalSince1970: 1_799_150_400)) + "_"
precondition(newest.url.lastPathComponent.hasPrefix(expected),
             "the folder is named \(newest.url.lastPathComponent), not \(expected)…")

// The name is the sort key, so its shape is a rule and not a formatting choice.
let name = Array(newest.url.lastPathComponent)
precondition(name.count == 22 && name[4] == "-" && name[7] == "-"
             && name[10] == "_" && name[17] == "_"
             && name.allSatisfy({ $0.isASCII && ($0.isHexDigit || $0 == "-" || $0 == "_") }),
             "the folder is named \(String(name)), not <yyyy-MM-dd>_<HHmmss>_<4 hex>")

// MARK: - 11. The photos were deleted, and then he wants to change the pages

// Both are on the done screen, in that order: delete the photos to get the space back,
// then change the pages, which deletes scan.pdf. Forty pages and no photo is what is left
// - and the pages are the work, so it is ready to check, not an empty scan. Nothing was
// killed here; getting this wrong loses a finished scan on two taps.
let photoless = newScan()
scanned(photoless, [1, 2, 3])
precondition(photoless.state == .ready, "3 pages and no photos is \(photoless.state)")
precondition(photoless.unscanned.isEmpty, "still to scan: \(photoless.unscanned)")

// MARK: - 12. Killed between the two folders New scan makes

// `create` makes photo/ and page/ in two syscalls. Killed in between, the scan reads as
// healthy and every page write would fail for ever, because the engine does not make the
// folder it writes into. The sweep is the only thing that can put it back.
let halfMade = Scan(url: scansRoot.appendingPathComponent("2026-08-12_090000_ABCD",
                                                          isDirectory: true))
do {
    try FileManager.default.createDirectory(at: halfMade.photoDirectory,
                                            withIntermediateDirectories: true)
} catch {
    fatalError("could not build the half-made scan: \(error.localizedDescription)")
}
shoot(halfMade, [1])
precondition(!exists(halfMade.pageDirectory),
             "the fixture is wrong: page/ is there before the sweep")

halfMade.sweep()
precondition(exists(halfMade.pageDirectory),
             "page/ is still missing, so this scan can never be scanned")
precondition(halfMade.state == .shooting, "the repaired scan is \(halfMade.state)")
precondition(halfMade.photos == [1], "the sweep took the photo with it: \(halfMade.photos)")

// MARK: - 13. The seven sentences the list rows say

// Five states, seven sentences: one page reads differently from eight, and a pdfDone
// scan whose photos are gone says so. The row is the only thing telling the user where
// tapping lands him, so a wrong sentence sends him to the wrong screen in his head.
func rowReads(_ scan: Scan, _ expected: String) {
    precondition(scan.subtitle == expected,
                 "the row says \"\(scan.subtitle)\", not \"\(expected)\"")
}

let rows = workspace.appendingPathComponent("Rows", isDirectory: true)
rowReads(newScan(in: rows), "No pages yet")

let oneShot = newScan(in: rows)
shoot(oneShot, [1])
rowReads(oneShot, "1 page — keep shooting")

let eightShot = newScan(in: rows)
shoot(eightShot, Array(1...8))
rowReads(eightShot, "8 pages — keep shooting")

let midScan = newScan(in: rows)
shoot(midScan, Array(1...40))
scanned(midScan, Array(1...12))
rowReads(midScan, "12 of 40 pages scanned")

let checkable = newScan(in: rows)
shoot(checkable, Array(1...40))
scanned(checkable, Array(1...40))
rowReads(checkable, "40 pages — ready to check")

let pdfDone = newScan(in: rows)
shoot(pdfDone, Array(1...40))
scanned(pdfDone, Array(1...40))
write("%PDF", to: pdfDone.pdf)
rowReads(pdfDone, "40 pages — PDF ready")

pdfDone.deletePhotos()
rowReads(pdfDone, "40 pages — PDF ready, photos deleted")

// MARK: - 14. What the delete dialog says goes

// The question is the only undo there is - there is no trash for a sandbox folder - so
// it names this scan's own counts, and each count carries its own plural.
precondition(pdfDone.deleteBody == "40 pages, the PDF and 0 photos go. This cannot be undone.",
             "the dialog says \"\(pdfDone.deleteBody)\"")

let single = newScan(in: rows)
shoot(single, [1])
scanned(single, [1])
precondition(single.deleteBody == "1 page, the PDF and 1 photo go. This cannot be undone.",
             "the dialog says \"\(single.deleteBody)\"")

// MARK: - 15. The row title, and what the swipe finally does

// The date on the row is the folder name read back through a formatter, and a folder
// this app did not make is shown as it is rather than hidden.
let titled = newScan(in: rows, at: Date(timeIntervalSince1970: 1_799_150_400))
precondition(!titled.title.isEmpty && titled.title != titled.url.lastPathComponent,
             "the row title is \"\(titled.title)\", which is the folder name")
let foreign = Scan(url: rows.appendingPathComponent("not-a-scan", isDirectory: true))
precondition(foreign.title == "not-a-scan", "an unreadable name reads \"\(foreign.title)\"")

// Confirming takes the whole folder - photos, pages and PDF. There is no trash for a
// sandbox folder, so this is the one moment the files really go.
let doomed = newScan(in: rows)
shoot(doomed, [1, 2])
scanned(doomed, [1])
write("%PDF", to: doomed.pdf)
doomed.delete()
precondition(!exists(doomed.url), "the scan folder is still there after delete()")
