import SwiftUI

@main
struct PeekApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var cameraManager = CameraManager()
    @State private var isMirrored = StateManager.shared.isMirrored
    @State private var isWindowVisible = false

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(
                cameraManager: cameraManager,
                isMirrored: $isMirrored,
                isWindowVisible: $isWindowVisible
            )
        } label: {
            Image(systemName: "camera.fill")
        }
        .menuBarExtraStyle(.window)
    }
}
