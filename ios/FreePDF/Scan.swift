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

    /// The scan's own folder. Its name is the sort key and the id, and the title too until
    /// the user types one of his own.
    let url: URL

    // MARK: - Where the files are

    var photoDirectory: URL { url.appendingPathComponent("photo", isDirectory: true) }
    var pageDirectory: URL { url.appendingPathComponent("page", isDirectory: true) }
    /// What the user last asked for, one small text file per page. Never where the work
    /// got to - see `writeState` below.
    var stateDirectory: URL { url.appendingPathComponent("state", isDirectory: true) }

    /// Its existence is the whole definition of "finished", so it arrives by rename
    /// only - a half-written PDF is called `scan.part` and the sweep deletes it.
    var pdf: URL { url.appendingPathComponent("scan.pdf") }

    /// Whether that file is there, which is what "finished" means. Written once, because
    /// `state` below and the screen's own cache both have to answer it the same way.
    var finished: Bool { FileManager.default.fileExists(atPath: pdf.path) }

    func photoURL(_ number: Int) -> URL {
        photoDirectory.appendingPathComponent(Self.fileName(number))
    }

    func pageURL(_ number: Int) -> URL {
        pageDirectory.appendingPathComponent(Self.fileName(number))
    }

    func stateURL(_ number: Int) -> URL {
        stateDirectory.appendingPathComponent(String(format: "%04d.txt", number))
    }

    /// The name the user typed on the done screen, or `nil` if he typed none. One line of
    /// UTF-8 in `name.txt`, written by `writeName` and swept like everything else.
    ///
    /// No error sentence anywhere, exactly like `readState`: an absent or empty file is a
    /// scan whose title is its date, which is what every scan starts as.
    var name: String? {
        guard let text = try? String(contentsOf: nameURL, encoding: .utf8) else { return nil }
        let typed = Self.sanitised(text)
        return typed.isEmpty ? nil : typed
    }

    /// The name file sits next to `state/` rather than inside it: `state/` is per page and
    /// this is about the whole scan. The folder itself is never renamed - its name is the
    /// date, and every file in the app is found through it.
    var nameURL: URL { url.appendingPathComponent("name.txt") }

    /// Writes the typed name, or deletes the file when what he typed comes to nothing -
    /// clearing the field puts the date back on the row, and an empty name is a normal
    /// case rather than a failure.
    ///
    /// The same earn-your-name rule as `writeState`, and here Foundation keeps it on its own:
    /// `.atomic` writes the bytes under a temporary name and renames that over `name.txt`,
    /// and a rename over a file never leaves the destination absent. So a kill mid-write
    /// leaves the old name or none at all, never half a name and never a lost name - which
    /// `writeState`'s remove-then-move cannot promise, because a kill in that gap would take
    /// the name that was already there with it.
    func writeName(_ typed: String) {
        let wanted = Self.sanitised(typed)
        guard !wanted.isEmpty else {
            try? FileManager.default.removeItem(at: nameURL)
            return
        }
        try? Data(wanted.utf8).write(to: nameURL, options: .atomic)
    }

    /// How small this scan's pages are written - one rung of the page size setting, one
    /// word in `quality.txt`, for the whole scan.
    ///
    /// It sits beside `name.txt` and not in `state/NNNN.txt` for the same reason the name
    /// does: `state/` is per page, and this is one fact about the scan. One fact stored
    /// forty times is a fact that can disagree with itself, and `readState` counts exactly
    /// 25 tokens anyway.
    ///
    /// Absent, empty, unreadable or a word this version does not know reads as
    /// `Engine.PageQuality.small` - never Original. That is not a shrug: `.small` is what
    /// the app promises a scan will cost, so a scan whose one small file was lost still
    /// comes out the size it promised, and Original stays the choice the user makes on
    /// purpose. No error sentence anywhere, exactly like `name` above.
    ///
    /// The word and not the two numbers, because the numbers behind a rung belong to
    /// `Engine.PageQuality` and nowhere else: a stored `45` would freeze today's number
    /// into every old scan and disagree with the switch the day the rung is retuned.
    var quality: Engine.PageQuality {
        guard let text = try? String(contentsOf: qualityURL, encoding: .utf8) else {
            return .small
        }
        let word = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return word == Self.originalWord ? .original : .small
    }

    /// Beside `name.txt` and swept like it: one word, and the folder is never renamed.
    var qualityURL: URL { url.appendingPathComponent("quality.txt") }

    /// Writes the rung, the same way `writeName` writes the name: `.atomic` puts the bytes
    /// down under a temporary name and renames that over `quality.txt`, and a rename over a
    /// file never leaves the destination absent. So a kill mid-write leaves the old rung or
    /// none at all - and none at all is the default, which is a rung and not a hole.
    ///
    /// The word is always written, never deleted for the default: what the app decided is
    /// then on disk and readable, and the answer is the same either way.
    /// Answers whether the word reached the disk, because the caller rewrites pages
    /// after it. A page written at a rung the disk does not name is the one state the
    /// order of `setQuality` exists to prevent, so a failure here has to stop it rather
    /// than be discarded ([`ScanFlow.swift`](./ScanFlow.swift)).
    @discardableResult
    func writeQuality(_ wanted: Engine.PageQuality) -> Bool {
        let word = wanted == .original ? Self.originalWord : Self.smallWord
        do {
            try Data(word.utf8).write(to: qualityURL, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    /// The two words `quality.txt` can hold. Anything else is the default, so a file
    /// written by a newer version cannot make an older one refuse to open a scan.
    private static let smallWord = "small"
    private static let originalWord = "original"

    /// The one place a typed name is cleaned up, because the name that leaves in the share
    /// sheet and the name on the row are the same string: a name is one path component, so
    /// the two characters that are not allowed in one are replaced, and the ends trimmed.
    ///
    /// Cut to 60 characters, because a path component has a length the file system refuses:
    /// a pasted subject line would still make a title, but the hard link the share sheet
    /// carries could not be made, and the row and the share sheet would then read
    /// differently - which is the one thing this function exists to prevent.
    ///
    /// ponytail: 60 characters, not 255 bytes. The longest character UTF-8 knows is four
    /// bytes, so 60 of them always fit next to `.pdf`; count the bytes if a name ever has
    /// to be longer than a line.
    /// A pasted name can carry a newline or a tab in the middle, which no trim at the ends
    /// takes out - it would wrap the row that is laid out for one line, and the file system
    /// would happily accept it in the shared copy's name. So the whole run of whitespace
    /// becomes one space, which also settles the trimming.
    static func sanitised(_ typed: String) -> String {
        typed.replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .prefix(60)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// What the user reads on the row: the name he typed, or `11 Aug 2026, 20:14` when he
    /// typed none. The folder is never renamed either way - see `create`.
    ///
    /// A folder whose name does not parse is shown as it is. That is not a scan this app
    /// made, and hiding it would be worse than an ugly row.
    var title: String {
        if let name { return name }
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
        if finished { return .done }
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

    // MARK: - What the user asked for

    /// One line per page, holding every value the Adjust screen can move, so a crop, a
    /// turn or a nudged level survives Apply, leaving the screen and a kill.
    ///
    /// This is not the manifest the table above buried. It is never an input to `state`,
    /// `photos`, `pages`, `unscanned` or `nextPage` - the step is still read off the two
    /// directories every time - and it holds what the user asked for, never where the
    /// work got to. So it cannot lag the files into a wrong screen: the worst a missing
    /// or stale line costs is one nudge the user makes again.
    ///
    /// The format is one ASCII line: `1`, the version, then 24 numbers -
    /// `c0x c0y c1x c1y c2x c2y c3x c3y flat angle bR bG bB wR wG wB tones sharpen
    /// cx cy cw ch turns grey`. The corners are the photo pixels `Adjustments` carries;
    /// everything else is exactly what crosses to the engine.
    func writeState(_ number: Int, _ values: Engine.Adjustments) {
        var fields = values.corners.map { String(format: "%.4f", $0) }
        fields.append(values.pullTheSheetFlat ? "1" : "0")
        fields.append(String(format: "%.1f", values.straightenDegrees))
        fields += (values.black + values.white).map(String.init)
        fields.append(values.adjustTheTones ? "1" : "0")
        fields.append(String(format: "%.1f", values.sharpenRadius))
        fields += [values.cropX, values.cropY, values.cropWidth, values.cropHeight]
            .map { String(format: "%.4f", $0) }
        fields.append(String(values.quarterTurns))
        fields.append(values.grey ? "1" : "0")

        let manager = FileManager.default
        try? manager.createDirectory(at: stateDirectory, withIntermediateDirectories: true)
        // The same earn-your-name rule the engine keeps: the bytes go down under a name
        // no reader accepts, and the file becomes `NNNN.txt` only once they are all
        // there. A kill in between leaves a `.part` the sweep takes, and no state at
        // all, which is a normal case rather than a failure.
        let part = stateDirectory.appendingPathComponent(String(format: "%04d.part", number))
        let line = (["1"] + fields).joined(separator: " ") + "\n"
        guard (try? Data(line.utf8).write(to: part, options: .atomic)) != nil else { return }
        try? manager.removeItem(at: stateURL(number))
        try? manager.moveItem(at: part, to: stateURL(number))
    }

    /// What the user last asked for on this page, or `nil` if there is nothing to read.
    ///
    /// No error sentence anywhere: an absent, truncated or unreadable line is a page that
    /// opens on the engine's suggestion, which is what the first open does anyway.
    func readState(_ number: Int) -> Engine.Adjustments? {
        guard let text = try? String(contentsOf: stateURL(number), encoding: .utf8) else {
            return nil
        }
        let tokens = text.split(whereSeparator: \.isWhitespace)
        guard tokens.count == 25, tokens[0] == "1" else { return nil }
        let numbers = tokens.dropFirst().compactMap { Double($0) }
        guard numbers.count == 24 else { return nil }
        func byte(_ value: Double) -> UInt8 { UInt8(min(255, max(0, value.rounded()))) }
        return Engine.Adjustments(
            corners: numbers[0..<8].map(Float.init),
            pullTheSheetFlat: numbers[8] != 0,
            straightenDegrees: Float(numbers[9]),
            black: numbers[10..<13].map(byte),
            white: numbers[13..<16].map(byte),
            adjustTheTones: numbers[16] != 0,
            sharpenRadius: Float(numbers[17]),
            cropX: Float(numbers[18]), cropY: Float(numbers[19]),
            cropWidth: Float(numbers[20]), cropHeight: Float(numbers[21]),
            quarterTurns: UInt32(min(3, max(0, numbers[22]))),
            grey: numbers[23] != 0)
    }

    func deleteState(_ number: Int) {
        try? FileManager.default.removeItem(at: stateURL(number))
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
        // The sidecars: `NNNN.txt` and nothing else, and only for a page number the disk
        // still has. A sidecar left behind by a deleted page would otherwise seed the
        // next page that happens to be shot into its number - and numbers are never
        // handed out twice, so that can only happen after a retake, which is exactly
        // what `deleteState` covers.
        try? manager.createDirectory(at: stateDirectory, withIntermediateDirectories: true)
        let known = Set(photos + pages)
        for name in (try? manager.contentsOfDirectory(atPath: stateDirectory.path)) ?? [] {
            let number = Self.number(name, suffix: ".txt")
            if number == nil || !known.contains(number!) {
                try? manager.removeItem(at: stateDirectory.appendingPathComponent(name))
            }
        }
        // The scan's own files, and the page size setting is one of them now. A name
        // missing from this list is deleted at the next launch, so leaving `quality.txt`
        // out would put every scan quietly back on the default rung.
        let kept = ["photo", "page", "state", "scan.pdf", "name.txt", "quality.txt"]
        for name in (try? manager.contentsOfDirectory(atPath: url.path)) ?? []
        where !kept.contains(name) {
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

    /// What the finished PDF costs, for the one line the done screen prints. Zero before
    /// there is one, and read the same way the photos are.
    ///
    /// It is the real file and never an estimate of what the other rung would weigh: the
    /// engine cannot answer that without encoding every page again, and a formula would be
    /// the guess its own rules forbid
    /// ([`../../core_engine/AGENTS.md`](../../core_engine/AGENTS.md)).
    var pdfBytes: Int {
        let attributes = try? FileManager.default.attributesOfItem(atPath: pdf.path)
        return attributes?[.size] as? Int ?? 0
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

    /// Deletes the PDF and keeps everything else - the photos, the pages and their state.
    ///
    /// The PDF is derived from the pages, so anything that touches a page makes it wrong:
    /// Apply, the Grey switch, Shoot another page and Change pages all call this, and each
    /// of them calls it first. A kill after it costs a rebuild of two seconds; a kill
    /// before it would leave a PDF holding a page the user has already replaced.
    func deletePDF() {
        try? FileManager.default.removeItem(at: pdf)
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
        number(fileName, suffix: ".jpg")
    }

    /// The same rule for the sidecars, whose suffix is `.txt`.
    private static func number(_ fileName: String, suffix: String) -> Int? {
        guard fileName.count == 8, fileName.hasSuffix(suffix) else { return nil }
        let digits = fileName.prefix(4)
        // ASCII digits only: `Int("-123")` would otherwise make `-123.jpg` a page.
        guard digits.allSatisfy({ $0.isASCII && $0.isNumber }) else { return nil }
        return Int(digits)
    }
}
