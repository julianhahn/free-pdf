//  DoneView.swift - the finished PDF: name the copy, read it, share it, or go back to
//  the pages.
//
//  One branch of `ScanFlow`'s switch, reached when `scan.pdf` exists - which is the whole
//  definition of finished. The screen is dumb the way the pages and Adjust screens are:
//  values in, `onChangePages` / `onDeletePhotos` out, and `ScanFlow` owns every file move
//  ([`../AGENTS.md`](../AGENTS.md)). The one file this screen touches itself is the
//  temporary hard link the share sheet carries, which is the share sheet's own business
//  and never leaves the temporary directory.
//
//  Every colour, size and step comes from `Token`. No number is written here.

import PDFKit
import SwiftUI

struct DoneView: View {
    /// The finished file. On disk it is always `scan.pdf` - the name below belongs to the
    /// copy that leaves and to nothing else.
    let pdf: URL
    /// How many photos are left and what they cost. Both come out of `ScanFlow`'s cache of
    /// the files, never read here, which is the rule the pages screen keeps too.
    let photos: Int
    let photoBytes: Int
    /// The name field's focus, and whether it has been taken already. Make PDF always
    /// means a copy is about to leave, so the field is raised with the screen and the
    /// keyboard's first load is paid there rather than on the first tap. Taken once:
    /// `Change pages` destroys this branch and Make PDF builds it again, and a second
    /// raise would throw the keyboard over a screen he came back to read.
    ///
    /// That is why the second half of it is a `Binding` and lives in `ScanFlow`: this
    /// screen is what Change pages destroys, so its own state cannot remember anything
    /// across that round trip.
    @FocusState private var naming: Bool
    @Binding var focusTaken: Bool
    var onChangePages: () -> Void
    var onDeletePhotos: () -> Void

    /// The name for the copy that leaves, and the temporary link that carries it. Nothing
    /// is stored: both die with the screen, and the file on disk is always `scan.pdf`.
    @State private var name = ""
    @State private var shareCopy: URL?
    @State private var confirmingPhotos = false
    @State private var reading = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Token.Size.space4) {
                nameField
                VStack(spacing: Token.Size.space2) {
                    Button("Open PDF") { reading = true }
                        .buttonStyle(OutlineStyle(ink: Token.Palette.accent,
                                                  edge: Token.Palette.accent))
                        .accessibilityHint("Reads the PDF here in the app.")
                    // The whole export. The system's own sheet has Save to Files - and
                    // with it iCloud Drive, in his folder rather than one this app picked -
                    // plus AirDrop and Mail. Nothing is uploaded behind his back and no
                    // entitlement is needed: this is a tool, not an opinion about where
                    // his PDFs live.
                    ShareLink(item: shareCopy ?? pdf) { Text("Share PDF") }
                        .buttonStyle(OutlineStyle(ink: Token.Palette.accent,
                                                  edge: Token.Palette.accent))
                    Button("Change pages", action: onChangePages)
                        .buttonStyle(OutlineStyle(ink: Token.Palette.accent, edge: .clear))
                        .accessibilityHint("Goes back to the pages. The PDF is made again afterwards.")
                }
                // Gone whole once the photos are, never greyed out: there is nothing left
                // to press and nothing to announce.
                if photoBytes > 0 { photosBlock }
            }
            .padding(Token.Size.screenPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Token.Palette.bg)
        .tint(Token.Palette.accent)
        .navigationTitle("PDF ready")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $reading) { reader }
        // The copy that leaves carries the typed name; nothing is stored, so leaving the
        // scan and coming back empties the field again.
        .onChange(of: name) { nameTheCopy() }
        // Once, when this screen opens. It belongs to this screen and not to `ScanFlow`'s
        // own `.onAppear`, which is shared with the camera, the takeover, Adjust and the
        // pages - screens with no name field. The sheets need no guard of their own: the
        // reader and the share sheet present over this screen without removing it.
        .onAppear {
            guard !focusTaken else { return }
            focusTaken = true
            naming = true
        }
    }

    /// The name for the copy that leaves. On disk the file is always `scan.pdf`, so this
    /// is the one field in the app and it holds nothing: the share sheet reads it and it
    /// dies with the screen ([`../../user-flows.md`](../../user-flows.md) section 10).
    private var nameField: some View {
        VStack(alignment: .leading, spacing: Token.Size.space1) {
            Text("Name for the shared copy")
                .font(Token.Face.body(Token.Size.textMeta))
                .foregroundStyle(Token.Palette.textMuted)
            TextField("scan", text: $name)
                .font(Token.Face.body(Token.Size.textControl))
                .foregroundStyle(Token.Palette.text)
                .autocorrectionDisabled()
                .focused($naming)
                .padding(.horizontal, Token.Size.space2)
                .frame(minHeight: Token.Size.inputMinH)
                .overlay(RoundedRectangle(cornerRadius: Token.Size.radiusMd)
                    .stroke(Token.Palette.divider, lineWidth: Token.Size.hairlineW))
        }
        .accessibilityElement(children: .combine)
    }

    private var photosBlock: some View {
        VStack(alignment: .leading, spacing: Token.Size.space2) {
            Rectangle()
                .fill(Token.Palette.divider)
                .frame(height: Token.Size.hairlineW)
                .padding(.bottom, Token.Size.space2)
            Text("Photos")
                .font(Token.Face.heading(Token.Size.textH6))
                .tracking(Token.Size.textH6 * Token.Number.trackingH6)
                .textCase(.uppercase)
                .foregroundStyle(Token.Palette.textMuted)
            Button(photosLine) { confirmingPhotos = true }
                .buttonStyle(OutlineStyle(ink: Token.Palette.destructive,
                                          edge: Token.Palette.destructive))
            Text("The PDF stays. Deleted photos cannot be brought back.")
                .font(Token.Face.body(Token.Size.textMeta))
                .lineSpacing(Token.Size.textMeta * (Token.Number.leadingBody - 1))
                .foregroundStyle(Token.Palette.textMuted)
        }
        // Asked every time and never remembered: there is no settings screen, and doing
        // nothing is the other half of the choice, so no "keep the photos" button exists.
        .confirmationDialog(photosQuestion,
                            isPresented: $confirmingPhotos,
                            titleVisibility: .visible) {
            Button("Delete photos", role: .destructive, action: onDeletePhotos)
                .accessibilityHint("Deletes this scan's photos.")
            Button("Cancel", role: .cancel) {}
                .accessibilityHint("Keeps the photos.")
        } message: {
            Text("The PDF stays. Without the photos the pages can no longer be adjusted.")
        }
    }

    /// "Delete the 40 photos (78 MB)" - the count and what they cost, both read off the
    /// files with everything else on this screen. The plural is the one `Scan.deleteBody`
    /// already carries.
    private var photosLine: String {
        "Delete the \(photos) photo\(photos == 1 ? "" : "s") (\(megabytes))"
    }

    private var photosQuestion: String {
        "Delete the \(photos) photo\(photos == 1 ? "" : "s")?"
    }

    /// "78 MB", in whatever the phone calls megabytes.
    private var megabytes: String {
        ByteCountFormatter.string(fromByteCount: Int64(photoBytes), countStyle: .file)
    }

    /// A hard link in the temporary directory carrying the typed name, so the share sheet
    /// offers `Rental contract.pdf` while the file on disk stays `scan.pdf`. A link rather
    /// than a copy: it costs no bytes and no time, and the same volume is the app's own
    /// container. Nothing is stored - the link is temporary and the field is empty at the
    /// next open.
    private func nameTheCopy() {
        if let old = shareCopy { try? FileManager.default.removeItem(at: old) }
        shareCopy = nil
        // A name is one path component, so the two characters that are not allowed in one
        // are the only thing taken out of what he typed.
        let wanted = name.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        guard !wanted.isEmpty else { return }
        let url = FileManager.default.temporaryDirectory.appending(path: wanted + ".pdf")
        try? FileManager.default.removeItem(at: url)
        try? FileManager.default.linkItem(at: pdf, to: url)
        if FileManager.default.fileExists(atPath: url.path) { shareCopy = url }
    }

    /// The reader: the system's own PDF view under the system's own sheet. Nothing is
    /// copied and nothing leaves the app - and there is nothing else on it, no share, no
    /// print, no page count.
    private var reader: some View {
        NavigationStack {
            Reader(url: pdf)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle("PDF")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { reading = false } label: { Image(systemName: "xmark") }
                            .accessibilityLabel("Close the PDF")
                    }
                }
        }
        .tint(Token.Palette.accent)
    }

    /// The finished PDF, read with the system's own PDF view. Nothing is copied and
    /// nothing leaves the app.
    private struct Reader: UIViewRepresentable {
        let url: URL

        func makeUIView(context: Context) -> PDFView {
            let view = PDFView()
            view.document = PDFDocument(url: url)
            view.autoScales = true
            return view
        }

        func updateUIView(_ view: PDFView, context: Context) {}
    }
}

/// The done screen's buttons: outlined, never filled, the label in the heading face. One
/// style with two colours covers all four - `edge` is clear for Change pages, which is the
/// quiet one.
private struct OutlineStyle: ButtonStyle {
    let ink: Color
    let edge: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Token.Face.heading(Token.Size.textControl))
            .tracking(Token.Size.textControl * Token.Number.trackingHeading)
            .padding(.vertical, Token.Size.buttonPaddingY)
            .padding(.horizontal, Token.Size.buttonPaddingX)
            .frame(maxWidth: .infinity, minHeight: Token.Size.touchMin)
            .background(configuration.isPressed ? Token.Palette.pressAccent : .clear,
                        in: RoundedRectangle(cornerRadius: Token.Size.radiusMd))
            .overlay(RoundedRectangle(cornerRadius: Token.Size.radiusMd)
                .stroke(edge, lineWidth: Token.Size.hairlineW))
            .foregroundStyle(ink)
    }
}
