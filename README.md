# Peek

A minimalist macOS menu bar camera app. Lives in your menu bar — no Dock icon, no clutter.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Download

  [Download DMG](https://github.com/viperwraith47/Peek/blob/main/build/Peek.dmg)
 
1. Open Build folder and downloaded `.dmg` file
2. Open the `.dmg`
3. Drag **Peek** to your **Applications** folder
4. Launch from Applications or Spotlight

## Features

- **Menu Bar Only** — No Dock icon, no window clutter. Just a camera icon in your menu bar.
- **Resizable Preview** — Drag any edge to resize (150px – 800px).
- **Toggle Visibility** — Click the menu bar icon to show/hide instantly.
- **Photo Capture** — Shutter button saves photos to `~/Downloads/Peek/`.
- **Video Recording** — Record video clips, saved to `~/Downloads/Peek/`.
- **Camera Selection** — Choose from any connected camera source.
- **Continuity Camera** — Use your iPhone's camera as a source (iPhone nearby + unlocked).
- **Mirror View** — Toggle between mirrored and non-mirrored view.
- **Launch at Login** — Optionally start on system login.
- **Persistent State** — Remembers window size, position, camera, and preferences.

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.4+ (for building from source)

## Build from Source

```bash
git clone https://github.com/viperwraith47/Peek.git
cd Peek
chmod +x create-dmg.sh
./create-dmg.sh
```

The built `.app` and `.dmg` will be in the `build/` directory.

## Usage

1. Launch **Peek** — a camera icon appears in the menu bar
2. Click the icon to show the camera preview
3. Use the **PHOTO / VIDEO** toggle at the bottom of the preview to switch modes
4. Press the **shutter button** (bottom right) to capture or start/stop recording
5. Click the **gear icon** (bottom left) to open settings
6. Select camera source, toggle mirror, launch at login, or quit

## Controls

| Control | Location | Action |
|---------|----------|--------|
| Camera icon | Menu bar | Show/hide preview |
| **PHOTO** / **VIDEO** | Bottom center | Switch capture mode |
| Shutter button | Bottom right | Capture photo / Start or stop video |
| Gear icon | Bottom left | Open settings panel |

## Project Structure

```
Peek/
├── Peek/
│   ├── PeekApp.swift           # MenuBarExtra entry point
│   ├── AppDelegate.swift        # Hides Dock icon
│   ├── CameraManager.swift      # AVCaptureSession, photo/video capture
│   ├── CameraPreviewView.swift  # NSViewRepresentable camera feed
│   ├── FloatingWindow.swift     # Borderless floating NSWindow
│   ├── MenuBarView.swift        # UI: preview, shutter, mode toggle
│   ├── StateManager.swift       # UserDefaults persistence
│   ├── LoginItemManager.swift   # SMAppService launch at login
│   ├── Info.plist               # LSUIElement, camera/mic permissions
│   ├── Peek.entitlements        # Sandbox, camera, audio
│   └── Assets.xcassets/
├── Peek.xcodeproj/
├── create-dmg.sh                # Build + DMG packaging script
├── LICENSE
└── README.md
```

## Permissions

On first launch, macOS will prompt for:

| Permission | Reason |
|------------|--------|
| **Camera** | Display your webcam / iPhone feed |
| **Microphone** | Required for video recording audio |

Captured photos and videos are saved to `~/Downloads/Peek/`.

## License

MIT License. See [LICENSE](LICENSE) for details.
