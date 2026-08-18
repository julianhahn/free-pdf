//  CameraView.swift - the camera screen, and the one place a photo is made.
//
//  A shot is one file. The page number it lands on is settled at the press and carried
//  by the writer, so two shots finishing out of order cannot swap pages. A write that
//  fails is said out loud: a full disk at page 25 that kept the shutter clicking would
//  produce a 24 page PDF of a 40 page contract, and that is the one bug this app may
//  not have.
//
//  No image work happens here ([`../AGENTS.md`](../AGENTS.md)) - the JPEG the camera
//  hands over is written exactly as it came, EXIF and all, and the engine does the rest.
//
//  Every colour, size and step comes from `Token`, which is generated out of
//  design/system/tokens/*.css. No number is written here.

import AVFoundation
import SwiftUI
import UIKit

struct CameraView: View {
    let scan: Scan
    /// The page number a shot lands on. `nil` means the next one, which is what
    /// shooting normally does; a number is a retake of that page.
    let slot: Int?
    /// Called when the user is finished shooting and wants the pages scanned.
    let finished: () -> Void

    /// The session, the output and the shots in flight. One per screen, and it is
    /// stopped on the way out.
    @State private var camera = Camera()
    /// What the disk said the last time it was read. The files are still the only
    /// state; this is what SwiftUI redraws on.
    @State private var photos: [Int] = []
    @State private var message: String?
    /// True from the press until the photo is on disk, and the shutter is dead while
    /// it is. That is what keeps two quick presses from both reading the same
    /// `nextPage` off the disk and one page from overwriting the other.
    ///
    /// ponytail: one shot at a time, so the shutter is dead for as long as a capture
    /// takes. Hand the numbers out of a claimed set if burst shooting ever matters.
    @State private var busy = false
    /// The user said no to the camera. There is nothing to shoot then, so the screen
    /// becomes the sentence and the way to Settings.
    @State private var denied = false
    /// A sentence about the screen rather than about one page: no camera, a session that
    /// would not start, a stand-in that would not draw. It takes the whole screen over
    /// and offers nothing, because there is nothing to press.
    @State private var blocked: String?

    /// The page the next shot lands on, read off the disk rather than counted.
    private var number: Int { slot ?? scan.nextPage }

    var body: some View {
        Group {
            if let blocked {
                takeover(blocked, settings: false)
            } else if denied {
                takeover("FreePDF needs the camera to photograph the pages.", settings: true)
            } else {
                viewfinder
            }
        }
        .background(Token.Palette.bg)
        .tint(Token.Palette.accent)
        // The counter, top centre, on every one of those three screens: leaving is
        // always possible and the page number never disappears. It is a toolbar item
        // rather than `navigationTitle` for one reason - a title cannot carry a font,
        // and this one has to be the heading face with tabular figures, so nothing
        // shuffles between "Page 1" and "Page 40". The back button reads "Scans" by
        // itself, and there is no Save button because there is nothing to save.
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Page \(number)")
                    .font(Token.Face.heading(Token.Size.textH5))
                    .tracking(Token.Size.textH5 * Token.Number.trackingHeading)
                    .monospacedDigit()
                    .foregroundStyle(Token.Palette.text)
            }
        }
        .onAppear { photos = scan.photos }
        // The session goes before the drain does its work: the pipeline holds about
        // 200 MB, and the drain peaks near 280 MB on its own
        // ([plan section 9](../../iphone-client-plan.md#9-memory)).
        .onDisappear { camera.stop() }
        .task { await begin() }
    }

    // MARK: - Shooting

    private var viewfinder: some View {
        VStack(spacing: 0) {
            VStack(spacing: Token.Size.space4) {
                // Above the picture, not under it: it is about the press that just
                // happened, and it pushes nothing off the screen the user is aiming at.
                if let message { ErrorLine(sentence: message) }
                preview
                shutter.padding(.top, Token.Size.space2)
            }
            .padding(Token.Size.screenPadding)

            Spacer(minLength: 0)

            // A retake is one shot, so it takes itself back to the pages afterwards.
            if slot == nil { footer }
        }
    }

    /// The live picture on its dark ground, or - where there is no camera at all - the
    /// stand-in that keeps the app usable on a simulator. 3:4 is the shape of the photo
    /// that gets written, so nothing the user frames is cropped away by the preview
    /// alone; the frame shrinks to make room for the error line, it is never cropped.
    private var preview: some View {
        ZStack {
            Token.Palette.viewfinder
            if Camera.device == nil {
                Text("No camera on this iPhone. The shutter draws a page instead.")
                    .font(Token.Face.body(Token.Size.textMeta))
                    .foregroundStyle(Token.Palette.onDarkMuted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .padding(Token.Size.space3)
            } else {
                Preview(layer: camera.preview)
            }
            // Four corner marks rather than a hairline rectangle: on a dark moving
            // picture a thin continuous line reads as part of the scene.
            Corners()
                .stroke(Token.Palette.accent, lineWidth: Token.Size.ruleStrong)
        }
        .aspectRatio(Token.Number.pageRatio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: Token.Size.radiusMd))
    }

    /// The one control on the screen, dead while the photo is written - and it says so,
    /// because a control that does nothing without saying why is a broken app.
    private var shutter: some View {
        Button(action: shoot) {}
            .buttonStyle(ShutterStyle(busy: busy))
            .disabled(busy)
            .accessibilityLabel(busy ? "Photographing page \(number), wait"
                                     : "Photograph page \(number)")
    }

    /// The screen's action, pinned above a hairline. Outlined, never filled: in this
    /// theme colour is a stroke.
    private var footer: some View {
        // `busy` for the same reason the shutter carries it, and it matters more here:
        // leaving while a photo is in flight tears this screen down, the session stops,
        // the capture is aborted - and the sentence saying so would be written into a
        // screen that no longer exists. The user would get a 7 page PDF of an 8 page
        // document in silence.
        let off = photos.isEmpty || busy
        return VStack(spacing: 0) {
            Rectangle()
                .fill(Token.Palette.divider)
                .frame(height: Token.Size.hairlineW)
            Button { finished() } label: {
                Text(photos.isEmpty ? "Photograph at least one page"
                                    : "Scan \(pageCount(photos.count))")
                    .font(Token.Face.heading(Token.Size.textControl))
                    .tracking(Token.Size.textControl * Token.Number.trackingHeading)
                    .monospacedDigit()
                    .foregroundStyle(off ? Token.Palette.disabledText : Token.Palette.accent)
                    .padding(.vertical, Token.Size.buttonPaddingY)
                    .padding(.horizontal, Token.Size.buttonPaddingX)
                    .frame(maxWidth: .infinity, minHeight: Token.Size.touchMin)
                    .overlay(RoundedRectangle(cornerRadius: Token.Size.radiusMd)
                        .stroke(off ? Token.Palette.disabledBorder : Token.Palette.accent,
                                lineWidth: Token.Size.hairlineW))
                    // The box is a stroke round an empty frame, and neither of those takes
                    // a touch, so without this the tap area is the centred words and most
                    // of a full-width button is dead.
                    .contentShape(Rectangle())
            }
            .disabled(off)
            .padding(Token.Size.screenPadding)
        }
    }

    /// The whole screen becomes one sentence. A button only where there is something to
    /// do: if there is one, the user can fix this; if there is none, he cannot, and he
    /// does not have to work out which.
    private func takeover(_ sentence: String, settings: Bool) -> some View {
        VStack(spacing: 0) {
            Image(systemName: "camera.slash")
                .font(.system(size: Token.Size.iconEmpty))
                .foregroundStyle(Token.Palette.accent)
                .padding(.bottom, Token.Size.space3)
            Text(sentence)
                .font(Token.Face.heading(Token.Size.textH4))
                .tracking(Token.Size.textH4 * Token.Number.trackingHeading)
                .foregroundStyle(Token.Palette.text)
                .multilineTextAlignment(.center)
            if settings {
                Button {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                } label: {
                    // The box is drawn inside the label, the way the footer's button above
                    // draws its own: a box painted on the Button instead decorates a
                    // wrapper, and the words stay the only thing that answers a tap.
                    Text("Open Settings")
                        .font(Token.Face.heading(Token.Size.textControl))
                        .foregroundStyle(Token.Palette.accent)
                        .padding(.vertical, Token.Size.buttonPaddingY)
                        .padding(.horizontal, Token.Size.buttonPaddingX)
                        .frame(minHeight: Token.Size.touchMin)
                        .overlay(RoundedRectangle(cornerRadius: Token.Size.radiusMd)
                            .stroke(Token.Palette.accent, lineWidth: Token.Size.hairlineW))
                        // A stroke answers a touch on its own hairline and a frame answers
                        // none at all, so the box needs a shape of its own - the one way
                        // out of this screen may not have a dead middle.
                        .contentShape(Rectangle())
                }
                .padding(.top, Token.Size.space4)
                .accessibilityHint("Opens the iPhone's settings for FreePDF, "
                                   + "where the camera can be allowed.")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Token.Size.screenPadding)
    }

    /// Asks for the camera, starts it, and lets `-autofake` make the taps a script
    /// cannot.
    private func begin() async {
        // Permission is only ever asked for where there is a camera to permit. A
        // simulator has none, and its permission alert cannot be tapped by the check
        // that drives the app there - an unanswered one survives even uninstalling.
        if Camera.device != nil {
            if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
                _ = await AVCaptureDevice.requestAccess(for: .video)
            }
            denied = AVCaptureDevice.authorizationStatus(for: .video) != .authorized
            // A session that will not start is the screen, not a page: there is nothing
            // to press and no photo was lost.
            if !denied { blocked = await camera.start() }
        } else {
            // No camera at all. On a simulator that is the stand-in's whole reason to
            // exist and the shutter draws instead; on a phone it is the end of this
            // screen, and the sentence has this one home.
            #if !targetEnvironment(simulator)
            blocked = "This iPhone has no camera to photograph with."
            #endif
        }
        if slot == nil, let failure = FakeShoot.autoShoot(scan, finished: finished) {
            say(failure)
        }
        photos = scan.photos
        await autoShootMore()
    }

    /// The taps `-autofake-more` stands in for: adding pages to a finished scan, one
    /// press of this screen's own shutter at a time with a redraw in between, and the
    /// footer at the end. A screen that ends itself after the first shot loses the rest
    /// of them, which is what makes that bug visible to
    /// [`../check/scan_check.sh`](../check/scan_check.sh).
    private func autoShootMore() async {
        guard slot == nil, let more = FakeShoot.morePagesWanted, !scan.pages.isEmpty
        else { return }
        let target = scan.photos.count + more
        while scan.photos.count < target {
            shoot()
            // The task is cancelled when this screen goes away, and then the pressing
            // stops with it - a torn-down screen may not carry on shooting.
            do { try await Task.sleep(for: .seconds(1)) } catch { return }
        }
        finished()
    }

    /// One press: a real capture where there is a camera, a drawn page where there is
    /// not. Both write the same 12 MP JPEG through the same atomic write.
    private func shoot() {
        let page = number
        guard Camera.device != nil else {
            let failure = FakeShoot.write(page: page, into: scan)
            say(failure)
            if failure == nil { landed() }
            return
        }
        busy = true
        Task {
            let sentence = await camera.shoot(page: page, to: scan.photoURL(page))
            busy = false
            message = sentence
            if sentence == nil { landed() }
        }
    }

    /// Puts a sentence where it belongs. The stand-in has one of each kind: a page that
    /// missed the disk is the line over the viewfinder, a page it could not draw at all
    /// is the screen.
    private func say(_ failure: FakeShoot.Failure?) {
        switch failure {
        case .notDrawn(let sentence)?: blocked = sentence
        case .notSaved(let sentence)?: message = sentence
        case nil: message = nil
        }
    }

    /// A photo reached the disk: the counter and the button read the files again, and a
    /// retake - which is one shot and nothing else - is over.
    private func landed() {
        photos = scan.photos
        if slot != nil { finished() }
    }
}

// MARK: - The session

/// Everything AVFoundation, on one queue of its own.
///
/// `nonisolated(unsafe)` on the four AVFoundation properties rather than
/// `@unchecked Sendable` on the class: the conformance stays checked, so the compiler
/// still watches everything else here, and the promise those four make is narrow
/// enough to read in one place. Every line that touches the session runs on `queue`, and
/// the preview layer is made here, turned here, and otherwise only mounted by the screen.
private final class Camera: Sendable {
    /// The back camera, or nil where there is none - which is every simulator: iOS
    /// 26.2 on "iPhone 17 Pro" reports zero video devices, only a microphone
    /// (measured). Everything the camera screen does branches on this one value.
    nonisolated(unsafe) static let device =
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)

    /// How far the picture is turned, for the preview and for the EXIF tag the photo
    /// output writes - the two must be the same number or the preview lies about what
    /// gets written.
    ///
    /// Fixed at portrait rather than following the phone: a phone held flat over a
    /// table has no reliable "up" for `AVCaptureDevice.RotationCoordinator` to read,
    /// and the app is portrait-locked anyway. Doing nothing is not an option - the
    /// default is 0 degrees, the sensor's own landscape, and every page would come out
    /// on its side (`AVCaptureSession.h:1106`; the plan claimed portrait lock made this
    /// come out right by itself, and it does not).
    private static let portrait: CGFloat = 90

    nonisolated(unsafe) private let session = AVCaptureSession()
    nonisolated(unsafe) private let output = AVCapturePhotoOutput()
    /// The live picture: made before the session has an input, so its connection exists
    /// to be turned as soon as one is added, and mounted by the screen afterwards.
    nonisolated(unsafe) let preview: AVCaptureVideoPreviewLayer
    /// One queue for the whole session, because `startRunning` blocks the thread it is
    /// called on (`AVCaptureSession.h:607`) and that thread must not be the main one.
    private let queue = DispatchQueue(label: "freepdf.camera")
    /// The shots asked for and not landed yet, keyed by the id their settings carry.
    /// AVFoundation does not promise to keep the delegate alive, so this is what does
    /// - until the callback it promises comes last. Only ever touched on `queue`.
    nonisolated(unsafe) private var inFlight: [Int64: Shot] = [:]

    /// One shot: the writer that must stay alive, and the press waiting for it.
    private struct Shot {
        let writer: PageWriter
        let waiting: CheckedContinuation<String?, Never>
    }

    init() {
        preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
    }

    /// Wires the camera up and starts it, all of it on `queue`.
    ///
    /// - Returns: nil when there is a picture, or the sentence saying why there is not.
    func start() async -> String? {
        await withCheckedContinuation { waiting in
            queue.async { [self] in
                guard !session.isRunning else { return waiting.resume(returning: nil) }
                // Nothing to start and nothing to say: the screen branches on the same
                // value before it ever calls this, and the sentence for having no camera
                // is written there, once. The device is read here rather than handed in
                // because `AVCaptureDevice` is not `Sendable` and this closure is.
                guard let device = Self.device else { return waiting.resume(returning: nil) }
                let input: AVCaptureDeviceInput
                do {
                    input = try AVCaptureDeviceInput(device: device)
                } catch {
                    // Its own sentence rather than the one above: there is a camera, and
                    // saying there is none would send the user looking in the wrong place.
                    return waiting.resume(returning:
                        "The camera could not be started: \(error.localizedDescription)")
                }

                session.beginConfiguration()
                session.sessionPreset = .photo
                // The video input only, so the app never needs a microphone key.
                guard session.canAddInput(input), session.canAddOutput(output) else {
                    session.commitConfiguration()
                    return waiting.resume(returning: "The camera could not be started.")
                }
                session.addInput(input)
                session.addOutput(output)
                session.commitConfiguration()
                // After the input is in, because that is when the connections exist.
                // Asked before it is set, because setting an angle a connection does not
                // support throws (`AVCaptureSession.h:1106`).
                for connection in [output.connection(with: .video), preview.connection]
                    .compactMap({ $0 })
                where connection.isVideoRotationAngleSupported(Self.portrait) {
                    connection.videoRotationAngle = Self.portrait
                }
                session.startRunning()
                // `startRunning` returns nothing and reports a failure only through a
                // notification (`AVCaptureSession.h:607`), so the only honest answer is
                // whether it is running now - otherwise a screen with no picture at all
                // would say nothing was wrong.
                waiting.resume(returning: session.isRunning
                    ? nil : "The camera could not be started.")
            }
        }
    }

    /// One photo, written where it is told. The page number never leaves this call.
    ///
    /// - Returns: nil when the file is on disk, or the sentence for the screen.
    func shoot(page: Int, to url: URL) async -> String? {
        await withCheckedContinuation { waiting in
            queue.async { [self] in
                // A session AVFoundation stopped by itself - the media server resetting
                // is the real case - is never restarted by anything else, and it does
                // not say so either: the preview simply freezes on its last frame. One
                // press pays for it, and the next one works.
                if !session.isRunning { session.startRunning() }
                // Both halves of this guard turn a crash into a sentence. A stopped
                // session would take the shot and never deliver it; and a codec that is
                // not in `availablePhotoCodecTypes` is the one rule `capturePhoto`
                // enforces by throwing, where nothing can catch it
                // (`AVCapturePhotoOutput.h:96`) - the array is empty until the output
                // sits in a session with a video source.
                guard session.isRunning, output.availablePhotoCodecTypes.contains(.jpeg)
                else {
                    return waiting.resume(returning:
                        pageNotSaved(page, "the camera is not ready."))
                }
                // JPEG at the moment of capture, asked for rather than assumed: HEIC
                // would need a decoder the engine will not ship
                // ([`../../README.md`](../../README.md)). A settings object may not be
                // used twice - a second capture with the same id throws
                // (`AVCapturePhotoOutput.h:71`) - so it is made here, per press.
                let settings = AVCapturePhotoSettings(
                    format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
                // Flat paper gains nothing from the fusion a higher setting pays for.
                settings.photoQualityPrioritization = .speed
                // 12 MP, by writing no code at all: the settings default to the
                // smallest of the active format's `supportedMaxPhotoDimensions`
                // (`AVCapturePhotoOutput.h:1454`), not to the 48 MP capture.
                let id = settings.uniqueID
                let writer = PageWriter(number: page, url: url) { [self] text in
                    queue.async { self.land(id, text) }
                }
                inFlight[id] = Shot(writer: writer, waiting: waiting)
                output.capturePhoto(with: settings, delegate: writer)
            }
        }
    }

    /// The first answer wins and the ones after it are dropped: a photo that reached
    /// the disk says so, and `didFinishCaptureFor` - the callback AVFoundation promises
    /// comes last - is what answers a capture that never delivered one at all. Always
    /// on `queue`, which is what makes "resumed exactly once" true without a lock.
    private func land(_ id: Int64, _ text: String?) {
        inFlight.removeValue(forKey: id)?.waiting.resume(returning: text)
    }

    /// Stops the flow of data, and with it the memory the pipeline holds.
    func stop() {
        queue.async { [self] in
            if session.isRunning { session.stopRunning() }
        }
    }
}

/// One shot. The page number and the file it goes to are settled before the shutter and
/// never read again, so two shots landing out of order cannot swap pages.
private final class PageWriter: NSObject, AVCapturePhotoCaptureDelegate, Sendable {
    let number: Int
    let url: URL
    /// nil means the file is on disk. A sentence means it is not, and that sentence is
    /// what the screen shows.
    let done: @Sendable (String?) -> Void

    init(number: Int, url: URL, done: @escaping @Sendable (String?) -> Void) {
        self.number = number
        self.url = url
        self.done = done
        super.init()
    }

    /// The photo, on AVFoundation's own queue rather than the main one
    /// (`AVCapturePhotoOutput.h:981`) - which is where a 3 MB write belongs anyway.
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: (any Error)?) {
        if let error {
            return done(pageNotSaved(number, error.localizedDescription))
        }
        guard let jpeg = photo.fileDataRepresentation() else {
            return done(pageNotSaved(number, "the camera handed over no photo."))
        }
        do {
            // `.atomic`, so a kill mid-write leaves an aux file the sweep takes, never
            // half a photo wearing a real name ([`../AGENTS.md`](../AGENTS.md)).
            try jpeg.write(to: url, options: .atomic)
            done(nil)
        } catch {
            // Never swallowed. This is the sentence the product exists to show.
            done(pageNotSaved(number, error.localizedDescription))
        }
    }

    /// The callback AVFoundation promises comes last. If the photo never arrived, this
    /// is the only thing that would ever tell the screen - and it is what gives the
    /// shutter back.
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
                     error: (any Error)?) {
        done(pageNotSaved(number, "the camera stopped before the photo arrived."))
    }
}

// MARK: - The shutter and the frame

/// The shutter: a ring in the accent, a gap in the ground, and a paper disc inside it -
/// the sheet about to be photographed. Disabled it keeps the disc at full `--paper`, so
/// the mass a thumb aims at does not fade, and only the ring goes quiet. Opacity is not
/// the mechanism anywhere in this system.
private struct ShutterStyle: ButtonStyle {
    let busy: Bool

    func makeBody(configuration: Configuration) -> some View {
        Circle()
            .strokeBorder(busy ? Token.Palette.disabledBorder : Token.Palette.accent,
                          lineWidth: Token.Size.shutterRing)
            .frame(width: Token.Size.shutterSize, height: Token.Size.shutterSize)
            .overlay {
                Circle()
                    .fill(configuration.isPressed && !busy
                          ? Token.Palette.accent200 : Token.Palette.paper)
                    .overlay(Circle().strokeBorder(Token.Palette.shutterDiscEdge,
                                                   lineWidth: Token.Size.hairlineW))
                    .padding(Token.Size.shutterRing + Token.Size.shutterGap)
            }
            .frame(minWidth: Token.Size.touchMin, minHeight: Token.Size.touchMin)
            // One control, so one target. A stroked circle answers a touch on its 2 point
            // band and the disc inside answers on its own 60 points, which leaves the gap
            // between them - the ground the ring stands on - taking nothing. This is on the
            // style's own body rather than on the Button, so it is the shape the tap is
            // tested against.
            .contentShape(Circle())
    }
}

/// The four corner marks of the viewfinder, one arm long each, set in from the frame.
private struct Corners: Shape {
    func path(in rect: CGRect) -> Path {
        let inset = CGPoint(x: rect.width * Token.Number.viewfinderCornerInset,
                            y: rect.height * Token.Number.viewfinderCornerInset)
        let arm = Token.Size.viewfinderCorner
        var path = Path()
        for x in [rect.minX + inset.x, rect.maxX - inset.x] {
            for y in [rect.minY + inset.y, rect.maxY - inset.y] {
                let towards = CGPoint(x: x == rect.minX + inset.x ? arm : -arm,
                                      y: y == rect.minY + inset.y ? arm : -arm)
                path.move(to: CGPoint(x: x + towards.x, y: y))
                path.addLine(to: CGPoint(x: x, y: y))
                path.addLine(to: CGPoint(x: x, y: y + towards.y))
            }
        }
        return path
    }
}

// MARK: - The live picture

/// The camera's own layer, mounted in a view SwiftUI can lay out.
private struct Preview: UIViewRepresentable {
    let layer: AVCaptureVideoPreviewLayer

    func makeUIView(context: Context) -> LayerView { LayerView(layer) }

    func updateUIView(_ view: LayerView, context: Context) {}
}

/// A view whose only job is to keep the camera's layer the size of itself. The layer
/// belongs to the camera, so that the preview and the written photo are turned by the
/// same one number.
private final class LayerView: UIView {
    private let preview: AVCaptureVideoPreviewLayer

    init(_ preview: AVCaptureVideoPreviewLayer) {
        self.preview = preview
        super.init(frame: .zero)
        layer.addSublayer(preview)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("CameraView never comes from a storyboard") }

    override func layoutSubviews() {
        super.layoutSubviews()
        preview.frame = bounds
    }
}

/// What the screen says when a photo did not reach the disk. It names the page and then
/// says what is safe, because that is the one thing the user needs to know - and it
/// says it without naming a range, which a scan with a deleted page in the middle would
/// make false.
func pageNotSaved(_ number: Int, _ reason: String) -> String {
    "Page \(number) was not saved: \(reason) Nothing already photographed is lost."
}
