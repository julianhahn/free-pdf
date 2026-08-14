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

    /// The scan the swipe asked to delete. Nothing is removed until it is confirmed:
    /// there is no trash for a sandbox folder, so the only undo is the question.
    @State private var pendingDelete: Scan?

    var body: some View {
        VStack(spacing: 0) {
            if let message {
                // The system's own sentence, printed unchanged, above the list. It goes
                // at the next reload, because the next tap is the answer to it. It sits
                // outside the List because the empty state covers the List, and S2 of the
                // flows document is exactly the empty list carrying this sentence.
                Text(message)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            List {
            ForEach(scans, id: \.url) { scan in
                NavigationLink(value: scan) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(scan.title)
                        Text(scan.subtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .swipeActions {
                    Button("Delete", role: .destructive) { pendingDelete = scan }
                }
            }
            }
            .overlay {
                if scans.isEmpty {
                    // No action here: New scan lives in the toolbar and nowhere else,
                    // as user-flows.md section 1 draws it.
                    ContentUnavailableView {
                        Label("No scans yet", systemImage: "doc.text.viewfinder")
                    } description: {
                        Text("Tap New scan and photograph the pages, one after another. "
                             + "You can stop whenever you like.")
                    }
                }
            }
        }
        .navigationTitle("Scans")
        .toolbar {
            Button("New scan", action: newScan)
        }
        .alert("Delete this scan?", isPresented: confirming, presenting: pendingDelete) { scan in
            Button("Delete scan", role: .destructive) {
                scan.delete()
                reload()
            }
            Button("Cancel", role: .cancel) {}
        } message: { scan in
            Text(scan.deleteBody)
        }
        .onAppear(perform: reload)
    }

    /// Open while a scan is waiting to be confirmed; dismissing clears it, so the swiped
    /// row goes back to being an ordinary row.
    private var confirming: Binding<Bool> {
        Binding(get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } })
    }

    private func newScan() {
        // Out of storage on the very first tap is the one way this fails, and its
        // sentence is already written for the screen.
        do { open = [try Scan.create()] }
        catch { message = error.localizedDescription }
    }

    private func reload() {
        scans = Scan.all()
        message = nil
    }

}
