//  FreePDFApp.swift - the whole app: a list of scans, and one screen per scan.

import SwiftUI

@main
struct FreePDFApp: App {
    /// Which scan is open. Empty means the list is showing.
    @State private var open: [Scan] = []

    init() {
        // The launch repair pass, on every scan, before the list is shown. It puts back
        // a directory a kill left missing - a scan without `page/` can never be scanned,
        // because the engine does not make the folder it writes into - and takes the
        // debris with it (`Scan.sweep`).
        //
        // Here rather than on the list screen, because the list comes back every time
        // the user leaves a scan, and a sweep at that moment could delete the `.part`
        // file the engine is still writing.
        for scan in Scan.all() { scan.sweep() }
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $open) {
                ScanList(open: $open)
                    .navigationDestination(for: Scan.self) { ScanFlow(scan: $0) }
            }
            // One of the two lines the camera stand-in reaches out of its own file with.
            // It opens the scan the check is about to shoot into, because nothing can
            // tap a row on a simulator ([`FakeShoot.swift`](./FakeShoot.swift)).
            .task { if let scan = FakeShoot.scanToOpen() { open = [scan] } }
        }
    }
}
