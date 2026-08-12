//  ScanList.swift - the landing screen: every scan, newest first.
//
//  Every row is read from the files each time it is drawn. Nothing here remembers what
//  a scan was doing, so a scan that was killed halfway through says so by itself.

import SwiftUI

struct ScanList: View {
    /// The navigation stack, so New scan can open the scan it just made.
    @Binding var open: [Scan]

    @State private var scans: [Scan] = []
    @State private var message: String?

    var body: some View {
        List {
            if let message {
                Text(message).foregroundStyle(.red)
            }
            ForEach(scans, id: \.url) { scan in
                NavigationLink(value: scan) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(scan.title)
                        Text(subtitle(scan))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete { rows in
                rows.map { scans[$0] }.forEach { $0.delete() }
                reload()
            }
        }
        .overlay {
            if scans.isEmpty {
                ContentUnavailableView(
                    "No scans yet",
                    systemImage: "doc.text.viewfinder",
                    description: Text("Tap New scan and photograph the pages, one after "
                                      + "another. You can stop whenever you like."))
            }
        }
        .navigationTitle("Scans")
        .toolbar {
            Button("New scan") {
                // Out of storage on the very first tap is the one way this fails, and
                // its sentence is already written for the screen.
                do { open = [try Scan.create()] }
                catch { message = error.localizedDescription }
            }
        }
        .onAppear(perform: reload)
    }

    private func reload() {
        scans = Scan.all()
        message = nil
    }

    /// What the row says under the date. Five states, and each one tells the user where
    /// tapping it will land him.
    private func subtitle(_ scan: Scan) -> String {
        let photos = scan.photos.count
        let pages = scan.pages.count
        switch scan.state {
        case .empty:    return "No pages yet"
        case .shooting: return "\(pageCount(photos)) - keep shooting"
        case .scanning: return "\(pages) of \(pageCount(photos)) scanned"
        case .ready:    return "\(pageCount(pages)) - ready to check"
        case .done:     return "\(pageCount(pages)) - PDF ready"
                               + (photos == 0 ? ", photos deleted" : "")
        }
    }
}

/// `1 page`, `8 pages`. Every screen that counts pages says it the same way.
func pageCount(_ number: Int) -> String {
    "\(number) page\(number == 1 ? "" : "s")"
}
