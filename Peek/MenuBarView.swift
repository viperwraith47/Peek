import SwiftUI
import AVFoundation

struct MenuBarView: View {
    @ObservedObject var cameraManager: CameraManager
    @Binding var isMirrored: Bool
    @Binding var isWindowVisible: Bool
    @State private var showSettings = false
    @State private var showFlash = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Camera preview
            ZStack {
                Color.black

                if cameraManager.isSessionRunning {
                    CameraPreviewView(
                        session: cameraManager.session,
                        isMirrored: $isMirrored
                    )
                } else {
                    VStack {
                        Image(systemName: "video.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.6))
                        Text("No Camera")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                // Flash overlay
                if showFlash {
                    Color.white
                        .ignoresSafeArea()
                        .transition(.opacity)
                }

                // Recording indicator
                if cameraManager.isRecording {
                    VStack {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text("REC")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        Spacer()
                    }
                    .padding(.top, 10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            }
            .frame(width: 300, height: 300)

            // Bottom bar overlay
            HStack(spacing: 0) {
                // Settings gear
                Button(action: { showSettings.toggle() }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Spacer()

                // Mode toggle
                HStack(spacing: 0) {
                    Button(action: { withAnimation { cameraManager.captureMode = .photo } }) {
                        Text("PHOTO")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(cameraManager.captureMode == .photo ? .white : .white.opacity(0.5))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)

                    Button(action: { withAnimation { cameraManager.captureMode = .video } }) {
                        Text("VIDEO")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(cameraManager.captureMode == .video ? .white : .white.opacity(0.5))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
                .background(.ultraThinMaterial)
                .clipShape(Capsule())

                Spacer()

                // Shutter button
                Button(action: performCapture) {
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 40, height: 40)

                        if cameraManager.captureMode == .photo {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 34, height: 34)
                        } else {
                            RoundedRectangle(cornerRadius: cameraManager.isRecording ? 4 : 8)
                                .fill(Color.red)
                                .frame(
                                    width: cameraManager.isRecording ? 18 : 28,
                                    height: cameraManager.isRecording ? 18 : 28
                                )
                                .animation(.easeInOut(duration: 0.15), value: cameraManager.isRecording)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, alignment: .bottom)
        }
        .popover(isPresented: $showSettings) {
            SettingsPanel(
                cameraManager: cameraManager,
                isMirrored: $isMirrored,
                isWindowVisible: $isWindowVisible
            )
        }
    }

    private func performCapture() {
        switch cameraManager.captureMode {
        case .photo:
            withAnimation { showFlash = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation { showFlash = false }
            }
            cameraManager.capturePhoto()
        case .video:
            if cameraManager.isRecording {
                cameraManager.stopRecording()
            } else {
                cameraManager.startRecording()
            }
        }
    }
}

struct SettingsPanel: View {
    @ObservedObject var cameraManager: CameraManager
    @Binding var isMirrored: Bool
    @Binding var isWindowVisible: Bool
    @State private var launchAtLogin = LoginItemManager.isEnabled

    private func cameraIcon(for device: AVCaptureDevice) -> String {
        if device.deviceType == .continuityCamera {
            return "iphone"
        }
        return device.position == .front ? "person.fill" : "video.fill"
    }

    private func cameraLabel(for device: AVCaptureDevice) -> String {
        if device.deviceType == .continuityCamera {
            return "\(device.localizedName) (iPhone)"
        }
        return device.localizedName
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Camera Selection
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Camera")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(action: { cameraManager.discoverCameras() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Refresh cameras")
                }

                ForEach(cameraManager.availableCameras, id: \.uniqueID) { device in
                    Button(action: { cameraManager.selectCamera(device) }) {
                        HStack {
                            Image(systemName: cameraIcon(for: device))
                                .frame(width: 18)
                                .font(.system(size: 12))
                            Text(cameraLabel(for: device))
                                .font(.system(size: 13))
                            Spacer()
                            if device.uniqueID == cameraManager.currentCamera?.uniqueID {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                                    .font(.system(size: 12))
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(
                            device.uniqueID == cameraManager.currentCamera?.uniqueID
                                ? Color.accentColor.opacity(0.1)
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }

                if cameraManager.availableCameras.isEmpty {
                    Text("No cameras found")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                }
            }

            Divider()

            // Quick toggles
            Toggle(isOn: $isMirrored) {
                Label("Mirror View", systemImage: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                    .font(.system(size: 13))
            }
            .toggleStyle(.switch)
            .controlSize(.small)
            .onChange(of: isMirrored) { _, newValue in
                StateManager.shared.isMirrored = newValue
            }

            Toggle(isOn: $launchAtLogin) {
                Label("Launch at Login", systemImage: "power")
                    .font(.system(size: 13))
            }
            .toggleStyle(.switch)
            .controlSize(.small)
            .onChange(of: launchAtLogin) { _, newValue in
                LoginItemManager.setEnabled(newValue)
            }

            Divider()

            // Save location
            VStack(alignment: .leading, spacing: 4) {
                Label("Saves to", systemImage: "folder")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 4) {
                    Text("~/Downloads/Peek/")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.primary)
                    Button(action: openSaveFolder) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 11))
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                    .help("Open in Finder")
                }
            }

            Divider()

            // Hide button
            Button(action: { isWindowVisible = false }) {
                Label("Hide Window", systemImage: "eye.slash")
                    .font(.system(size: 13))
            }
            .buttonStyle(.plain)

            // Quit button
            Button(action: { NSApp.terminate(nil) }) {
                Label("Quit Peek", systemImage: "power")
                    .font(.system(size: 13))
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(width: 240)
    }

    private func openSaveFolder() {
        let folderURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Peek", isDirectory: true)
        try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        NSWorkspace.shared.open(folderURL)
    }
}
