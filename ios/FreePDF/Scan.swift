//  Scan.swift - one scan is one directory, and the files in it are the only state.
//
//  Where the user left off, which pages exist, what is still to do: all of it is read
//  back from the disk every time, so a kill cannot leave the app believing something
//  the files disagree with. There is nothing else to disagree with them.
//
//  Foundation only, on purpose: the whole model then compiles and runs without Xcode
//  and without a simulator, which is what `../check/run.sh` does.

import Foundation

/// `1 page`, `8 pages`. Every screen that counts pages says it the same way.
func pageCount(_ number: Int) -> String {
    "\(number) page\(number == 1 ? "" : "s")"
}

/// One scan: a folder of photos, the pages made from them, and the finished PDF.
///
/// `Hashable` because the list screen pushes a scan onto the navigation stack, and it
/// costs nothing: the folder is the identity, and there is no second field to compare.
struct Scan: Hashable {
    /// Where the user is in this scan. Derived, never stored - a stored step is a
    /// second truth, and the kill that matters is the one between writing the file
    /// and writing the step.
    enum State {
        case empty, shooting, scanning, ready, done
    }

    /// Every scan lives under here. Local, never an iCloud container: a synced folder
    /// may evict a file to a placeholder that needs the network to read back, and this
    /// app reads its own input offline. iCloud is where the finished PDF is exported to.
    static let root = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Scans", isDirectory: true)

    /// The scan's own folder. Its name is the sort key, the id and the title at once.
    let url: URL

    // MARK: - Where the files are

    var photoDirectory: URL { url.appendingPathComponent("photo", isDirectory: true) }
    var pageDirectory: URL { url.appendingPathComponent("page", isDirectory: true) }

    /// Its existence is the whole definition of "finished", so it arrives by rename
    /// only - a half-written PDF is called `scan.part` and the sweep deletes it.
    var pdf: URL { url.appendingPathComponent("scan.pdf") }

    func photoURL(_ number: Int) -> URL {
        photoDirectory.appendingPathComponent(Self.fileName(number))
    }

    func pageURL(_ number: Int) -> URL {
        pageDirectory.appendingPathComponent(Self.fileName(number))
    }

    /// What the user reads on the row: `11 Aug 2026, 20:14`. The folder name is the
    /// title, which is why there is no title field and nothing to rename - see `create`.
    ///
    /// A folder whose name does not parse is shown as it is. That is not a scan this app
    /// made, and hiding it would be worse than an ugly row.
    var title: String {
        // Built here rather than kept as a `static let`, because `DateFormatter` is not
        // Sendable and one row is far cheaper than making the model thread-unsafe.
        let reader = DateFormatter()
        reader.locale = Locale(identifier: "en_US_POSIX")    // Gregorian, like the name
        reader.dateFormat = "yyyy-MM-dd_HHmmss"
        let name = url.lastPathComponent
        guard let date = reader.date(from: String(name.prefix(17))) else { return name }
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    // MARK: - What the disk says

    /// The photos that have been taken, in page order. Gaps are normal: a deleted page
    /// leaves one, and nothing is ever renumbered.
    var photos: [Int] { Self.numbers(in: photoDirectory) }

    /// The photos that have been turned into pages.
    var pages: [Int] { Self.numbers(in: pageDirectory) }

    /// What the drain still has to do. A photo with no page file, and nothing else.
    ///
    /// Not `pages.count == photos.count`: one orphan page file - a page whose photo was
    /// deleted - would wedge the scan in `.scanning` for ever, with nothing left to scan.
    var unscanned: [Int] {
        let done = Set(pages)
        return photos.filter { !done.contains($0) }
    }

    /// The number the next shot gets. It counts both directories, so a number the disk
    /// has ever seen is never handed out twice - a reused number would put a page from
    /// another sheet into the PDF.
    var nextPage: Int { ((photos + pages).max() ?? 0) + 1 }

    var state: State {
        if FileManager.default.fileExists(atPath: pdf.path) { return .done }
        // Both empty, not just the photos. Deleting the photos on the done screen and then
        // asking to change the pages leaves forty pages and no photo, and that scan is
        // ready to check - the pages are the work, the photos are only the raw material.
        if photos.isEmpty && pages.isEmpty { return .empty }
        // No pages at all means he was still shooting, so reopening lands him on the
        // viewfinder. Some pages plus leftovers means the scanning was cut off, so he
        // gets the progress line instead.
        if pages.isEmpty { return .shooting }
        return unscanned.isEmpty ? .ready : .scanning
    }

    /// What the row says under the date. Five states - seven sentences, because a scan of
    /// one page and a finished scan without its photos each read differently - and every
    /// one of them tells the user where tapping it will land him.
    ///
    /// It lives here rather than on the screen so that `check/run.sh` can read it back:
    /// the plurals and the seventh sentence are the parts that break silently.
    var subtitle: String {
        let photos = photos.count
        let pages = pages.count
        switch state {
        case .empty:    return "No pages yet"
        case .shooting: return "\(pageCount(photos)) — keep shooting"
        case .scanning: return "\(pages) of \(pageCount(photos)) scanned"
        case .ready:    return "\(pageCount(pages)) — ready to check"
        case .done:     return "\(pageCount(pages)) — PDF ready"
                               + (photos == 0 ? ", photos deleted" : "")
        }
    }

    /// What the delete dialog says under its question. It counts off the disk, so the
    /// question is about this scan and not about scans in general.
    var deleteBody: String {
        let photos = photos.count
        return "\(pageCount(pages.count)), the PDF and "
             + "\(photos) photo\(photos == 1 ? "" : "s") go. This cannot be undone."
    }

    // MARK: - Making and finding scans

    /// A new, empty scan.
    ///
    /// The folder name is `<yyyy-MM-dd>_<HHmmss>_<4 hex>`: a reverse lexicographic sort
    /// over those names is newest first without reading a single file attribute, and the
    /// hex tail is what survives a double tap on New scan inside one second. The
    /// formatted date is also the title the user sees, so there is no title field.
    ///
    /// - Returns: the scan, or throws if the folders cannot be made - out of storage on
    ///   the very first tap, whose `localizedDescription` is a sentence for the screen.
    static func create(in root: URL = Scan.root, at date: Date = Date()) throws -> Scan {
        // Gregorian, not `Calendar.current`: the name is a machine key. A phone set to the
        // Buddhist calendar - the default in Thailand - writes 2569 for 2026, and the
        // Japanese era year reset to 1 in 2019, which would put every scan made afterwards
        // below every scan made before it. The key is only newest-first while every name
        // in the folder comes from one calendar.
        //
        // ponytail: local wall-clock time, so flying west, or the hour that repeats when
        // summer time ends, can list a newer scan below an older one for a few hours. It
        // costs the order of two rows and no data, and it is what lets the name also be
        // the title. Build it in `.gmt` and convert at display time if it ever matters.
        let calendar = Calendar(identifier: .gregorian)
        let name = String(
            format: "%04d-%02d-%02d_%02d%02d%02d_%04X",
            calendar.component(.year, from: date), calendar.component(.month, from: date),
            calendar.component(.day, from: date), calendar.component(.hour, from: date),
            calendar.component(.minute, from: date), calendar.component(.second, from: date),
            Int.random(in: 0...0xFFFF))

        let scan = Scan(url: root.appendingPathComponent(name, isDirectory: true))
        // Both now, so no writer has to remember to make one. `withIntermediateDirectories`
        // also makes `Scans/` itself on the very first launch.
        for directory in [scan.photoDirectory, scan.pageDirectory] {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return scan
    }

    /// Every scan, newest first, straight from the folder names.
    ///
    /// ponytail: O(scans) per call, and the list screen calls it on every appearance.
    /// Cache it in memory if a few hundred scans ever make the launch feel slow.
    static func all(in root: URL = Scan.root) -> [Scan] {
        let manager = FileManager.default
        let names = (try? manager.contentsOfDirectory(atPath: root.path)) ?? []
        return names.sorted(by: >).compactMap { name in
            var isDirectory: ObjCBool = false
            let url = root.appendingPathComponent(name, isDirectory: true)
            guard manager.fileExists(atPath: url.path, isDirectory: &isDirectory),
                  isDirectory.boolValue
            else { return nil }         // a stray file is not a scan
            return Scan(url: url)
        }
    }

    /// The launch repair pass: puts back a directory that is missing, then deletes
    /// everything the app did not write itself - the `.part` file a kill left behind,
    /// Foundation's own aux files, anything hand-copied in. Call it on every scan at
    /// launch, before the list is shown.
    ///
    /// A missing directory is the half of this that is not cosmetic. `create` makes
    /// `photo/` and `page/` in two syscalls, so a kill between them leaves a scan that
    /// reads as perfectly healthy and whose every page write then fails for ever, because
    /// the engine's `save_page` does not make the folder it writes into. Nothing else ever
    /// puts it back, and there is no way out of it from inside the app.
    ///
    /// The debris half only takes the space back, since every reader already ignores it -
    /// which is why a failure there is not worth a sentence on screen.
    func sweep() {
        let manager = FileManager.default
        for directory in [photoDirectory, pageDirectory] {
            try? manager.createDirectory(at: directory, withIntermediateDirectories: true)
            for name in (try? manager.contentsOfDirectory(atPath: directory.path)) ?? []
            where Self.pageNumber(name) == nil {
                try? manager.removeItem(at: directory.appendingPathComponent(name))
            }
        }
        for name in (try? manager.contentsOfDirectory(atPath: url.path)) ?? []
        where !["photo", "page", "scan.pdf"].contains(name) {
            try? manager.removeItem(at: url.appendingPathComponent(name))
        }
    }

    /// What the photos cost, for the sentence on the button that deletes them. Zero when
    /// they are gone, which is also how the screen knows not to offer it twice.
    var photoBytes: Int {
        photos.reduce(0) { total, number in
            let attributes = try? FileManager.default
                .attributesOfItem(atPath: photoURL(number).path)
            return total + (attributes?[.size] as? Int ?? 0)
        }
    }

    /// Deletes the photos and keeps everything else - the pages, the PDF, and `photo/`
    /// itself.
    ///
    /// The directory stays because every writer assumes it is there; `sweep()` would put
    /// it back, but only at the next launch, and a shot taken before that would fail. What
    /// is left is a scan with pages and no raw material, which `state` reads as finished
    /// and `Change pages` can still work on - the pages are the work.
    func deletePhotos() {
        for number in photos { try? FileManager.default.removeItem(at: photoURL(number)) }
    }

    /// Throws the whole scan away - photos, pages and PDF.
    ///
    /// Nothing is reported when it fails, because the list is read back from the disk
    /// straight afterwards: a scan that could not be deleted is simply still on it,
    /// which is the only honest report there is. There is no trash for a sandbox
    /// folder, so the screen asks before calling this.
    func delete() {
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Names

    private static func fileName(_ number: Int) -> String {
        String(format: "%04d.jpg", number)      // four digits, so 9999 pages per scan
    }

    /// The page numbers in one directory, in order.
    private static func numbers(in directory: URL) -> [Int] {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        return names.compactMap(pageNumber).sorted()
    }

    /// `0007.jpg` -> 7, and nothing else counts: not `0007.part`, not `0003.jpeg`, not
    /// `IMG_0042.jpg`, not `.dat.nosync4f1a`.
    ///
    /// This is what makes a real name proof of a complete file. Every writer renames into
    /// place after the bytes are down, so a name that gets past here cannot be half a file
    /// - which is what replaces checksums and a validation pass.
    private static func pageNumber(_ fileName: String) -> Int? {
        guard fileName.count == 8, fileName.hasSuffix(".jpg") else { return nil }
        let digits = fileName.prefix(4)
        // ASCII digits only: `Int("-123")` would otherwise make `-123.jpg` a page.
        guard digits.allSatisfy({ $0.isASCII && $0.isNumber }) else { return nil }
        return Int(digits)
    }
}
