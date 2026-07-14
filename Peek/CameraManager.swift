import AVFoundation
import Combine
import AppKit

enum CaptureMode {
    case photo
    case video
}

final class CameraManager: NSObject, ObservableObject {
    @Published var availableCameras: [AVCaptureDevice] = []
    @Published var currentCamera: AVCaptureDevice?
    @Published var isSessionRunning = false
    @Published var captureMode: CaptureMode = .photo
    @Published var isRecording = false
    @Published var lastPhoto: NSImage?

    let session = AVCaptureSession()
    private var deviceInput: AVCaptureDeviceInput?
    private let photoOutput = AVCapturePhotoOutput()
    private let movieOutput = AVCaptureMovieFileOutput()
    private let sessionQueue = DispatchQueue(label: "com.maccam.session")

    var currentCameraPosition: AVCaptureDevice.Position? {
        currentCamera?.position
    }

    override init() {
        super.init()
        discoverCameras()
        configureSession()
    }

    func discoverCameras() {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .continuityCamera],
            mediaType: .video,
            position: .unspecified
        )
        availableCameras = discoverySession.devices
    }

    func selectCamera(_ device: AVCaptureDevice) {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            let wasRunning = self.session.isRunning
            if wasRunning { self.session.stopRunning() }

            self.session.beginConfiguration()

            if let input = self.deviceInput {
                self.session.removeInput(input)
                self.deviceInput = nil
            }

            do {
                let input = try AVCaptureDeviceInput(device: device)
                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                    self.deviceInput = input
                    DispatchQueue.main.async {
                        self.currentCamera = device
                    }
                    StateManager.shared.selectedCameraID = device.uniqueID
                }
            } catch {
                print("Failed to create device input: \(error)")
            }

            self.session.commitConfiguration()

            if wasRunning { self.session.startRunning() }
        }
    }

    func selectCamera(byID id: String) {
        if let device = availableCameras.first(where: { $0.uniqueID == id }) {
            selectCamera(device)
        }
    }

    func switchCamera() {
        guard let current = currentCamera else { return }
        let targetPosition: AVCaptureDevice.Position = current.position == .front ? .back : .front
        if let device = availableCameras.first(where: { $0.position == targetPosition }) {
            selectCamera(device)
        }
    }

    // MARK: - Photo Capture

    func capturePhoto() {
        guard session.isRunning, deviceInput != nil else {
            print("Cannot capture: session not running or no input")
            return
        }

        sessionQueue.async { [weak self] in
            guard let self else { return }
            let settings = AVCapturePhotoSettings()
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    // MARK: - Video Recording

    func startRecording() {
        guard !isRecording, session.isRunning, deviceInput != nil else {
            print("Cannot record: session not running, already recording, or no input")
            return
        }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Peek_\(Date().timeIntervalSince1970).mov")

        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.movieOutput.isRecording {
                self.movieOutput.stopRecording()
            }
            self.movieOutput.startRecording(to: outputURL, recordingDelegate: self)
            DispatchQueue.main.async {
                self.isRecording = true
            }
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        sessionQueue.async { [weak self] in
            self?.movieOutput.stopRecording()
            DispatchQueue.main.async {
                self?.isRecording = false
            }
        }
    }

    // MARK: - Session

    private func configureSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
            }

            if self.session.canAddOutput(self.movieOutput) {
                self.session.addOutput(self.movieOutput)
            }

            self.session.commitConfiguration()

            if let savedID = StateManager.shared.selectedCameraID,
               let device = self.availableCameras.first(where: { $0.uniqueID == savedID }) {
                self.selectCamera(device)
            } else if let first = self.availableCameras.first {
                self.selectCamera(first)
            }

            self.session.startRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = true
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = false
            }
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            print("Photo capture failed: \(error)")
            return
        }

        guard let data = photo.fileDataRepresentation(),
              let image = NSImage(data: data) else {
            print("Photo capture: could not create image from data")
            return
        }

        DispatchQueue.main.async {
            self.lastPhoto = image
        }

        savePhotoToDisk(data)
    }

    private func savePhotoToDisk(_ data: Data) {
        let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let folderURL = downloadsURL.appendingPathComponent("Peek", isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        } catch {
            print("Failed to create directory: \(error)")
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = "IMG_\(formatter.string(from: Date())).jpg"
        let fileURL = folderURL.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL)
            print("Photo saved: \(fileURL.path)")
        } catch {
            print("Failed to save photo: \(error)")
        }
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate

extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error {
            print("Recording failed: \(error)")
            return
        }

        saveVideoToDisk(outputFileURL)
    }

    private func saveVideoToDisk(_ sourceURL: URL) {
        let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let folderURL = downloadsURL.appendingPathComponent("Peek", isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        } catch {
            print("Failed to create directory: \(error)")
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = "VID_\(formatter.string(from: Date())).mov"
        let fileURL = folderURL.appendingPathComponent(filename)

        do {
            try FileManager.default.moveItem(at: sourceURL, to: fileURL)
            print("Video saved: \(fileURL.path)")
        } catch {
            print("Failed to save video: \(error)")
        }
    }
}
