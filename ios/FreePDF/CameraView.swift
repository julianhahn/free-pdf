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

    /// The page the next shot lands on, read off the disk rather than counted.
    private var number: Int { slot ?? scan.nextPage }

    var body: some View {
        if denied {
            permission
        } else {
            viewfinder
        }
    }

    // MARK: - Shooting

    private var viewfinder: some View {
        VStack(spacing: 20) {
            preview

            if let message {
                Text(message).font(.footnote).foregroundStyle(.red)
            }

            Button(action: shoot) {
                Image(systemName: "circle.circle.fill").font(.system(size: 68))
            }
            .disabled(busy)
            .accessibilityLabel("Photograph page \(number)")

            // A retake is one shot, so it takes itself back to the pages afterwards.
            if slot == nil {
                Button(photos.isEmpty ? "Photograph at least one page"
                                      : "Scan \(pageCount(photos.count))") { finished() }
                    // `busy` for the same reason the shutter carries it, and it matters
                    // more here: leaving while a photo is in flight tears this screen
                    // down, the session stops, the capture is aborted - and the sentence
                    // saying so would be written into a screen that no longer exists.
                    // The user would get a 7 page PDF of an 8 page document in silence.
                    .disabled(photos.isEmpty || busy)
            }
        }
        .padding()
        // The counter, top centre. The back button reads "Scans" by itself, and there
        // is no Save button because there is nothing to save.
        .navigationTitle("Page \(number)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { photos = scan.photos }
        // The session goes before the drain does its work: the pipeline holds about
        // 200 MB, and the drain peaks near 280 MB on its own
        // ([plan section 9](../../iphone-client-plan.md#9-memory)).
        .onDisappear { camera.stop() }
        .task { await begin() }
    }

    /// The live picture, or - where there is no camera at all - the stand-in that keeps
    /// the app usable on a simulator.
    @ViewBuilder
    private var preview: some View {
        if Camera.device == nil {
            RoundedRectangle(cornerRadius: 12)
                .fill(.quaternary)
                .overlay(Text("No camera on this iPhone. The shutter draws a page instead.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding())
        } else {
            Preview(layer: camera.preview)
                // 3:4 is the shape of the photo that gets written, so nothing the user
                // frames is cropped away by the preview alone.
                .aspectRatio(3.0 / 4.0, contentMode: .fit)
        }
    }

    private var permission: some View {
        VStack(spacing: 20) {
            Text("FreePDF needs the camera to photograph the pages.")
                .multilineTextAlignment(.center)
            Button("Open Settings") {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
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
            if !denied { message = await camera.start() }
        }
        if slot == nil, let sentence = FakeShoot.autoShoot(scan, finished: finished) {
            message = sentence
        }
        photos = scan.photos
    }

    /// One press: a real capture where there is a camera, a drawn page where there is
    /// not. Both write the same 12 MP JPEG through the same atomic write.
    private func shoot() {
        let page = number
        guard Camera.device != nil else {
            message = FakeShoot.write(page: page, into: scan)
            if message == nil { landed() }
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
                guard let device = Self.device else {
                    return waiting.resume(returning: "This iPhone has no camera to photograph with.")
                }
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
