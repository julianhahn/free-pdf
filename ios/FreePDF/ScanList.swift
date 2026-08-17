//  ScanList.swift - the landing screen: every scan, newest first.
//
//  Every row is read from the files each time it is drawn. Nothing here remembers what
//  a scan was doing, so a scan that was killed halfway through says so by itself.
//
//  Every colour, size and step comes from `Token`, which is generated out of
//  design/system/tokens/*.css. No number is written here.

import SwiftUI

struct ScanList: View {
    /// The navigation stack, so New scan can open the scan it just made, and so a row
    /// can be an ordinary button - which is what lets it draw its own chevron and its
    /// own pressed state instead of the system's.
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
                ErrorLine(sentence: message)
                    .padding(Token.Size.screenPadding)
                    .padding(.bottom, Token.Size.space4)
            }
            List {
                ForEach(scans, id: \.url) { scan in
                    Button { open = [scan] } label: { row(scan) }
                        .buttonStyle(RowStyle())
                        .listRowInsets(EdgeInsets())
                        .listRowSeparatorTint(Token.Palette.divider)
                        .swipeActions {
                            Button(role: .destructive) { pendingDelete = scan } label: {
                                Text("Delete").font(Token.Face.heading(Token.Size.textControl))
                            }
                            .tint(Token.Palette.destructive)
                            .accessibilityLabel("Delete this scan")
                        }
                }
            }
            .listStyle(.plain)
            .overlay { if scans.isEmpty { emptyState } }
        }
        .background(Token.Palette.bg)
        .tint(Token.Palette.accent)
        .navigationTitle("Scans")
        .toolbar {
            Button("New scan", action: newScan)
                .accessibilityHint("Photograph the pages of a new scan.")
        }
        .alert("Delete this scan?", isPresented: confirming, presenting: pendingDelete) { scan in
            Button("Delete scan", role: .destructive) {
                scan.delete()
                reload()
            }
            .accessibilityHint("Deletes the scan, its PDF and its photos.")
            Button("Cancel", role: .cancel) {}
                .accessibilityHint("Keeps the scan.")
        } message: { scan in
            Text(scan.deleteBody)
        }
        .onAppear(perform: reload)
    }

    /// One row: the date, the sentence the files say, and the chevron that promises the
    /// tap goes somewhere.
    private func row(_ scan: Scan) -> some View {
        HStack(spacing: Token.Size.space3) {
            VStack(alignment: .leading, spacing: Token.Size.space1) {
                Text(scan.title)
                    .font(Token.Face.heading(Token.Size.textRowTitle))
                    .tracking(Token.Size.textRowTitle * Token.Number.trackingHeading)
                    .monospacedDigit()
                    .foregroundStyle(Token.Palette.text)
                Text(scan.subtitle)
                    .font(Token.Face.body(Token.Size.textSub))
                    .lineSpacing(Token.Size.textSub * (Token.Number.leadingBody - 1))
                    .monospacedDigit()
                    .foregroundStyle(Token.Palette.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right")
                .font(.system(size: Token.Size.iconRow))
                .foregroundStyle(Token.Palette.accent)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(scan.title). \(scan.subtitle).")
    }

    /// Icon, title, body, and the same New scan the bar carries - the instruction the
    /// sentence just gave, in the place the eye already is.
    private var emptyState: some View {
        VStack(spacing: 0) {
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: Token.Size.iconEmpty))
                .foregroundStyle(Token.Palette.accent)
                .padding(.bottom, Token.Size.space3)
            Text("No scans yet")
                .font(Token.Face.heading(Token.Size.textH4))
                .tracking(Token.Size.textH4 * Token.Number.trackingHeading)
                .foregroundStyle(Token.Palette.text)
                .padding(.bottom, Token.Size.space2)
            Text("Tap New scan and photograph the pages, one after another. "
                 + "You can stop whenever you like.")
                .font(Token.Face.body(Token.Size.textBody))
                .lineSpacing(Token.Size.textBody * (Token.Number.leadingBody - 1))
                .foregroundStyle(Token.Palette.textMuted)
                .multilineTextAlignment(.center)
                .padding(.bottom, Token.Size.space4)
            Button("New scan", action: newScan)
                .buttonStyle(PrimaryStyle())
                .accessibilityHint("Photograph the pages of a new scan.")
        }
        .padding(Token.Size.screenPadding)
        .background(Token.Palette.bg)
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

/// The row's own press treatment: the accent at 14%, full bleed, instead of the system
/// highlight. The padding lives here too, because the row has none of its own - the
/// hairline and the swipe action run to both edges.
private struct RowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, Token.Size.screenPadding)
            .padding(.vertical, Token.Size.space3)
            .frame(minHeight: Token.Size.touchMin)
            .background(configuration.isPressed ? Token.Palette.pressRow : Token.Palette.bg)
    }
}
