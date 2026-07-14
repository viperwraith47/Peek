import SwiftUI

struct SettingsView: View {
    @ObservedObject var cameraManager: CameraManager
    @Binding var isMirrored: Bool
    @State private var launchAtLogin = LoginItemManager.isEnabled

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline)
                .padding(.bottom, 4)

            // Camera Selection
            VStack(alignment: .leading, spacing: 6) {
                Text("Camera")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ForEach(cameraManager.availableCameras, id: \.uniqueID) { device in
                    Button(action: { cameraManager.selectCamera(device) }) {
                        HStack {
                            Image(systemName: device.position == .front ? "person.fill" : "video.fill")
                                .frame(width: 20)
                            Text(device.localizedName)
                            Spacer()
                            if device.uniqueID == cameraManager.currentCamera?.uniqueID {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
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
            }

            Divider()

            // Mirror toggle
            Toggle(isOn: $isMirrored) {
                Label("Mirror View", systemImage: "arrow.left.and.right.righttriangle.left.righttriangle.right")
            }
            .toggleStyle(.switch)
            .onChange(of: isMirrored) { _, newValue in
                StateManager.shared.isMirrored = newValue
            }

            // Launch at Login
            Toggle(isOn: $launchAtLogin) {
                Label("Launch at Login", systemImage: "power")
            }
            .toggleStyle(.switch)
            .onChange(of: launchAtLogin) { _, newValue in
                LoginItemManager.setEnabled(newValue)
            }

            Spacer()
        }
        .padding(16)
        .frame(width: 260, height: 280)
    }
}
