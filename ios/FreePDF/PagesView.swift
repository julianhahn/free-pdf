//  PagesView.swift - the pages, one per swipe, before they become a PDF.
//
//  This screen shows what is already on disk and never lists it: every number it draws
//  comes in from `ScanFlow`'s cache of the files. A directory listing inside a view body
//  gives two answers in one frame while the drain writes into it, and SwiftUI then never
//  settles - the drain screen was fixed for exactly that and this one is built that way
//  from the start ([`../AGENTS.md`](../AGENTS.md)).
//
//  Every colour, size and step comes from `Token`. No number is written here.

import ImageIO
import SwiftUI
import UIKit

struct PagesView: View {
    let scan: Scan
    /// Every page number this scan has, whether it got as far as a page file or not.
    /// Cached in `ScanFlow`, never read off the disk here.
    let numbers: [Int]
    /// The pages that still have their photo. Same cache, and it is what decides whether
    /// Adjust is offered at all.
    let photos: [Int]
    /// The pages the engine refused. They are on this carousel because this is the only
    /// place the user can do something about them.
    let failed: Set<Int>
    /// True when every photo has a page - which is both what makes Make PDF appear and
    /// what lets "Shoot another page" be tapped.
    let complete: Bool
    let making: Bool
    let message: String?
    /// Grey as the files say it, read by `ScanFlow` off the lowest-numbered page that
    /// has a state file. One switch for the whole scan, and flipping it rewrites every
    /// page - so what is on screen is what is written.
    let grey: Bool
    /// How small the pages are written, as `quality.txt` says it. One setting for the whole
    /// scan, read by `ScanFlow` off that one file, and moving it rewrites every page - so
    /// what the switch says is what is on disk. It is here as well as on the check after the
    /// first photo, because that check is shown once per scan and a scan resumed tomorrow
    /// never sees it again.
    let quality: Engine.PageQuality
    @Binding var showing: Int
    var onRetake: (Int) -> Void
    var onDelete: (Int) -> Void
    var onGrey: (Bool) -> Void
    var onQuality: (Engine.PageQuality) -> Void
    var onAdjust: (Int) -> Void
    var onShootAnother: () -> Void
    var onMakePDF: () -> Void

    @State private var confirmingDelete = false
    /// How far the page is pinched open, and where the pinch started. Reading small
    /// print is the only reason this screen exists.
    @State private var zoom: CGFloat = 1
    @State private var zoomStart: CGFloat = 1
    /// The page whose sheet ran off the edge of the photo, as the engine reads it off
    /// that photo when the page is shown. One run for the page on screen, never for the
    /// others, and nothing is stored: the fact belongs to the photo, so it disappears
    /// with it. `nil` while the run is out, or when the photo is gone or unreadable -
    /// there is then nothing to say and nothing to retake from.
    @State private var ranOff: Int?
    /// The jump: one field and a Go, open only while asked for. Nothing is remembered.
    @State private var jumping = false
    @State private var jumpTo = ""

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: Token.Size.space4) {
                if let message { ErrorLine(sentence: message) }
                carousel
                // A calm note, not an `ErrorLine`: nothing failed, the page is simply a
                // piece of the sheet. It sits under the page it is about and the retake
                // below it is the repair.
                if ranOff == showing {
                    Text("Not the whole sheet - it ran off the edge of the photo.")
                        .font(Token.Face.body(Token.Size.textSub))
                        .lineSpacing(Token.Size.textSub * (Token.Number.leadingBody - 1))
                        .foregroundStyle(Token.Palette.textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                // Adjust has its own control on the screen, in the same place for every
                // page - it was the hardest thing in the app to find behind the "…"
                // (Julian, 2026-08-16). Disabled, never hidden, where the photo is gone,
                // so it does not move: Adjust re-runs the recipe from `photo/NNNN.jpg`.
                Button("Adjust page") { onAdjust(showing) }
                    .buttonStyle(SecondaryStyle(off: !photos.contains(showing)))
                    .disabled(!photos.contains(showing))
                    .accessibilityHint("Opens the tools for page \(position).")
                // The same rule: its own control, always in the same place, dead rather
                // than gone while a page is still waiting for the engine.
                Button("Shoot another page") { onShootAnother() }
                    .buttonStyle(SecondaryStyle(off: !complete))
                    .disabled(!complete)
                    .accessibilityHint("Photographs one more page at the end of this scan.")
                if failed.contains(showing) || ranOff == showing {
                    Button("Scan this page again") { onRetake(showing) }
                        .buttonStyle(SecondaryStyle())
                        .accessibilityHint("Photographs page \(position) again.")
                }
                rail
            }
            .padding(Token.Size.screenPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            Rectangle()
                .fill(Token.Palette.divider)
                .frame(height: Token.Size.hairlineW)
            footer
        }
        .background(Token.Palette.bg)
        .tint(Token.Palette.accent)
        .navigationTitle("Page \(position) of \(numbers.count)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { menu }
        // One engine run for the page on screen, re-keyed by the swipe and cancelled by
        // it - the same call Adjust makes when it opens, and the only place this fact
        // comes from.
        .task(id: showing) { await askThePhoto(showing) }
        .onChange(of: showing) {
            // A new page starts unpinched, and the jump closes on the next swipe.
            zoom = 1
            zoomStart = 1
            jumping = false
        }
        .confirmationDialog("Delete this page?",
                            isPresented: $confirmingDelete,
                            titleVisibility: .visible) {
            Button("Delete page", role: .destructive) { onDelete(showing) }
                .accessibilityHint("Deletes page \(position) and its photo.")
            Button("Cancel", role: .cancel) {}
                .accessibilityHint("Keeps the page.")
        } message: {
            Text("The photo goes too. This cannot be undone.")
        }
    }

    /// Whether this page's sheet left the frame, asked of the photo itself. A refused
    /// page has no page image to talk about, and a photo that is gone or unreadable
    /// leaves the note off - it is a note, not an error.
    private func askThePhoto(_ number: Int) async {
        ranOff = nil
        guard photos.contains(number), !failed.contains(number) else { return }
        let photo = scan.photoURL(number)
        let suggestion = try? await Task.detached(priority: .userInitiated) {
            try Engine.suggest(photo)
        }.value
        guard !Task.isCancelled, suggestion?.runsOffThePicture == true else { return }
        ranOff = number
    }

    /// Where in the carousel he is. Counted, not the page number: a page deleted in the
    /// middle keeps its gap for ever, and "Page 7 of 6" would be the result.
    private var position: Int { (numbers.firstIndex(of: showing) ?? 0) + 1 }

    // MARK: - The page

    private var carousel: some View {
        TabView(selection: $showing) {
            ForEach(numbers, id: \.self) { number in
                page(number).tag(number)
            }
        }
        // The rail is the indicator now, so the system's dots would be a second one.
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func page(_ number: Int) -> some View {
        if failed.contains(number) {
            VStack(spacing: Token.Size.space2) {
                Image(systemName: "doc.badge.exclamationmark")
                    .font(.system(size: Token.Size.iconEmpty))
                Text("This page could not be scanned.")
                    .font(Token.Face.body(Token.Size.textSub))
                    .lineSpacing(Token.Size.textSub * (Token.Number.leadingBody - 1))
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(Token.Palette.destructive)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Token.Palette.surface, in: RoundedRectangle(cornerRadius: Token.Size.radiusMd))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Page \(pos(number)) of \(numbers.count), could not be scanned.")
        } else {
            PageImage(url: scan.pageURL(number))
                .scaleEffect(zoom)
                .clipped()
                .gesture(pinch)
                .accessibilityLabel("Page \(pos(number)) of \(numbers.count)\(grey ? ", grey" : "")")
        }
    }

    private func pos(_ number: Int) -> Int { (numbers.firstIndex(of: number) ?? 0) + 1 }

    /// Pinch to zoom, held between 1 and 4. Skipped: panning while zoomed in - add it
    /// when looking at the middle of a page turns out to be what he wants.
    private var pinch: some Gesture {
        MagnifyGesture()
            .onChanged { zoom = min(max(zoomStart * $0.magnification, 1), 4) }
            .onEnded { _ in zoomStart = zoom }
    }

    // MARK: - The rail

    /// From ten pages up the rail carries the jump. Julian's number, decided on
    /// 2026-08-16 because "Go to page" on a one page scan has nowhere to go - it is not
    /// measured off anything.
    private static let jumpFrom = 10

    private var rail: some View {
        VStack(alignment: .leading, spacing: Token.Size.space2) {
            HStack(spacing: Token.Size.space2) {
                ScrollViewReader { view in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Token.Size.space2) {
                            ForEach(numbers, id: \.self) { number in tile(number).id(number) }
                        }
                    }
                    .onAppear { view.scrollTo(showing, anchor: .center) }
                    .onChange(of: showing) { withAnimation { view.scrollTo(showing, anchor: .center) } }
                }
                if numbers.count >= Self.jumpFrom {
                    Rectangle()
                        .fill(Token.Palette.divider)
                        .frame(width: Token.Size.hairlineW, height: Token.Size.touchMin)
                    // Words, not a glyph, and always in the same place at the rail's end.
                    Button("Go to page") { jumping.toggle() }
                        .buttonStyle(GhostStyle())
                        .accessibilityHint("Go to a page number. Page \(position) of \(numbers.count) shown.")
                }
            }
            if jumping { jump }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Pages, \(position) of \(numbers.count) shown")
    }

    private var jump: some View {
        HStack(spacing: Token.Size.space2) {
            TextField("", text: $jumpTo)
                .keyboardType(.numberPad)
                .font(Token.Face.body(Token.Size.textControl))
                .monospacedDigit()
                .foregroundStyle(Token.Palette.text)
                .padding(.horizontal, Token.Size.space2)
                .frame(minHeight: Token.Size.inputMinH)
                .overlay(RoundedRectangle(cornerRadius: Token.Size.radiusMd)
                    .stroke(Token.Palette.divider, lineWidth: Token.Size.hairlineW))
                .accessibilityLabel("Page number, 1 to \(numbers.count)")
            Button("Go") { go() }
                .buttonStyle(SecondaryStyle())
                .accessibilityHint("Goes to that page.")
        }
    }

    /// The number typed is the page as the user counts it - the third page, not the file
    /// called 0003. The two disagree the moment a page in the middle is deleted, and the
    /// rail is what he read the number off.
    private func go() {
        if let typed = Int(jumpTo), numbers.indices.contains(typed - 1) {
            showing = numbers[typed - 1]
        }
        jumping = false
        jumpTo = ""
    }

    private func tile(_ number: Int) -> some View {
        let chosen = number == showing
        let refused = failed.contains(number)
        return VStack(spacing: Token.Size.space1) {
            Group {
                if refused {
                    Rectangle().fill(Token.Palette.surface)
                } else {
                    PageImage(url: scan.pageURL(number), maxPixels: 200)
                }
            }
            .frame(width: Token.Size.iconEmpty,
                   height: Token.Size.iconEmpty / Token.Number.pageRatio)
            .clipShape(RoundedRectangle(cornerRadius: Token.Size.radiusSm))
            .overlay(RoundedRectangle(cornerRadius: Token.Size.radiusSm)
                .stroke(refused ? Token.Palette.destructive
                                : (chosen ? Token.Palette.accent : Token.Palette.divider),
                        lineWidth: refused || chosen ? Token.Size.ruleStrong : Token.Size.hairlineW))
            Text(String(number))
                .font(Token.Face.body(Token.Size.textMeta))
                .monospacedDigit()
                .foregroundStyle(chosen ? Token.Palette.text : Token.Palette.textMuted)
        }
        .onTapGesture { showing = number }
        .accessibilityElement(children: .combine)
        // The refusal sentence does not fit on a 30 pt tile and is not shortened to fit,
        // so the tile speaks it instead.
        .accessibilityLabel("Page \(pos(number))"
                            + (refused ? ", could not be scanned" : "")
                            + (chosen ? ", shown" : ""))
    }

    // MARK: - The footer

    private var footer: some View {
        VStack(spacing: Token.Size.space2) {
            Toggle(isOn: Binding(get: { grey }, set: { onGrey($0) })) {
                Text("Grey")
                    .font(Token.Face.heading(Token.Size.textControl))
                    .tracking(Token.Size.textControl * Token.Number.trackingHeading)
                    .foregroundStyle(Token.Palette.text)
            }
            .toggleStyle(.switch)
            .tint(Token.Palette.accent)
            .frame(minHeight: Token.Size.touchMin)
            .accessibilityHint("Rewrites every page of this scan in grey.")

            // The same switch as on the check after the first photo, the same value and the
            // same callback: one setting, two places to reach it. Dead rather than gone once
            // the photos are, the way Adjust page is for a page whose photo is missing.
            Toggle(isOn: Binding(get: { quality == .small },
                                 set: { onQuality($0 ? .small : .original) })) {
                Text("Smaller pages")
                    .font(Token.Face.heading(Token.Size.textControl))
                    .tracking(Token.Size.textControl * Token.Number.trackingHeading)
                    .foregroundStyle(frozen ? Token.Palette.disabledText : Token.Palette.text)
            }
            .toggleStyle(.switch)
            .tint(Token.Palette.accent)
            .frame(minHeight: Token.Size.touchMin)
            .disabled(frozen)
            .accessibilityHint("Rewrites every page of this scan at about half the file size.")

            // Hidden until every photo has a page, so a scan cannot quietly lose a page
            // to a PDF the user thought was whole.
            if complete {
                Button(making ? "Making the PDF…" : "Make PDF", action: onMakePDF)
                    .buttonStyle(PrimaryStyle(wide: true, off: making))
                    .disabled(making)
                    .accessibilityHint("Makes one PDF from the \(numbers.count) pages.")
            }
        }
        .padding(Token.Size.screenPadding)
    }

    /// Once the photos are gone the rung is frozen: the real pixels went with them, so a
    /// page can only be made from the page itself, which would be a second lossy pass and
    /// never an improvement. The control stays where it is and does nothing, exactly as
    /// Adjust page does for a page whose photo is missing - it re-runs the recipe from
    /// `photo/NNNN.jpg` too.
    private var frozen: Bool { photos.isEmpty }

    // MARK: - The page menu

    private var menu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button("Retake this page", systemImage: "camera") { onRetake(showing) }
                    .accessibilityHint("Photographs page \(position) again.")
                Divider()
                Button("Delete page", systemImage: "trash", role: .destructive) {
                    confirmingDelete = true
                }
            } label: {
                Image(systemName: "ellipsis")
            }
            .accessibilityLabel("Page menu")
        }
    }
}

/// One page file, decoded small enough to look at and no bigger.
///
/// The decode happens in a `.task`, not while the view is drawn: a paging carousel keeps
/// about three pages alive, and a full page decodes to some 34 MB. 1600 px is about 7 MB
/// and still shows whether the small print survived, which is the only reason this screen
/// exists; the rail's tiles ask for 200.
/// Not private: the Adjust screen shows the same page the same way
/// ([`AdjustView.swift`](./AdjustView.swift)).
struct PageImage: View {
    let url: URL
    var maxPixels = 1600

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Token.Palette.paper
            }
        }
        .task(id: url) { image = await Self.decode(url, maxPixels: maxPixels) }
    }

    private static func decode(_ url: URL, maxPixels: Int) async -> UIImage? {
        await Task.detached(priority: .userInitiated) {
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maxPixels,
            ]
            guard let made = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
            else { return nil }
            return UIImage(cgImage: made)
        }.value
    }
}

/// The secondary button: the label in the heading face inside a hairline box. Three places
/// on this screen use it - Adjust page, Retry and the jump's Go.
///
/// `off` is the dead look, and it is the `--disabled-*` colour role rather than an opacity:
/// the shape stays at full strength and only the words go grey (task 1).
private struct SecondaryStyle: ButtonStyle {
    var off = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Token.Face.heading(Token.Size.textControl))
            .tracking(Token.Size.textControl * Token.Number.trackingHeading)
            .padding(.vertical, Token.Size.buttonPaddingY)
            .padding(.horizontal, Token.Size.buttonPaddingX)
            .frame(maxWidth: .infinity, minHeight: Token.Size.touchMin)
            .background(configuration.isPressed ? Token.Palette.pressNeutral : Token.Palette.bg,
                        in: RoundedRectangle(cornerRadius: Token.Size.radiusMd))
            .overlay(RoundedRectangle(cornerRadius: Token.Size.radiusMd)
                .stroke(off ? Token.Palette.disabledBorder : Token.Palette.divider,
                        lineWidth: Token.Size.hairlineW))
            .foregroundStyle(off ? Token.Palette.disabledText : Token.Palette.text)
    }
}
