import Foundation

final class StateManager {
    static let shared = StateManager()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let windowWidth = "windowWidth"
        static let windowHeight = "windowHeight"
        static let windowX = "windowX"
        static let windowY = "windowY"
        static let selectedCameraID = "selectedCameraID"
        static let isMirrored = "isMirrored"
        static let launchAtLogin = "launchAtLogin"
    }

    var windowWidth: CGFloat {
        get { CGFloat(defaults.double(forKey: Keys.windowWidth).nonZero(300)) }
        set { defaults.set(Double(newValue), forKey: Keys.windowWidth) }
    }

    var windowHeight: CGFloat {
        get { CGFloat(defaults.double(forKey: Keys.windowHeight).nonZero(300)) }
        set { defaults.set(Double(newValue), forKey: Keys.windowHeight) }
    }

    var windowX: CGFloat? {
        get { defaults.object(forKey: Keys.windowX) != nil ? CGFloat(defaults.double(forKey: Keys.windowX)) : nil }
        set { defaults.set(newValue.map { Double($0) }, forKey: Keys.windowX) }
    }

    var windowY: CGFloat? {
        get { defaults.object(forKey: Keys.windowY) != nil ? CGFloat(defaults.double(forKey: Keys.windowY)) : nil }
        set { defaults.set(newValue.map { Double($0) }, forKey: Keys.windowY) }
    }

    var selectedCameraID: String? {
        get { defaults.string(forKey: Keys.selectedCameraID) }
        set { defaults.set(newValue, forKey: Keys.selectedCameraID) }
    }

    var isMirrored: Bool {
        get { defaults.object(forKey: Keys.isMirrored) != nil ? defaults.bool(forKey: Keys.isMirrored) : true }
        set { defaults.set(newValue, forKey: Keys.isMirrored) }
    }

    var launchAtLogin: Bool {
        get { defaults.bool(forKey: Keys.launchAtLogin) }
        set { defaults.set(newValue, forKey: Keys.launchAtLogin) }
    }

    func saveWindowPosition(_ point: NSPoint) {
        defaults.set(Double(point.x), forKey: Keys.windowX)
        defaults.set(Double(point.y), forKey: Keys.windowY)
    }

    func saveWindowSize(_ size: NSSize) {
        defaults.set(Double(size.width), forKey: Keys.windowWidth)
        defaults.set(Double(size.height), forKey: Keys.windowHeight)
    }
}

private extension Double {
    func nonZero(_ fallback: Double) -> Double {
        self == 0 ? fallback : self
    }
}
