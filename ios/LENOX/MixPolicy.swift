import Foundation

enum FileAccessPolicy {
    static func isContainerURL(_ url: URL, container: URL = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)) -> Bool {
        guard url.isFileURL, container.isFileURL else { return false }
        let root = container.resolvingSymlinksInPath().standardizedFileURL.path
        let path = url.resolvingSymlinksInPath().standardizedFileURL.path
        return path.hasPrefix(root + "/")
    }
}

/// Platform-neutral contract. Invalid control data fails silent, not louder.
enum MixPolicy {
    static func level(deck: Int, crossfade: Double, gain: Double, channel: Double) -> Float {
        guard (0...1).contains(deck), crossfade.isFinite, gain.isFinite, channel.isFinite,
              (0...1).contains(crossfade), (0...1).contains(gain), (0...1).contains(channel) else { return 0 }
        // Android-compatible centre-full curve, NOT equal-power or a limiter.
        let side = deck == 0 ? 1 - crossfade : crossfade
        return Float(min(1, 2 * side * gain * channel))
    }
    static func validRate(_ value: Double) -> Bool {
        value.isFinite && (0.5...2).contains(value)
    }
    static func seek(_ value: Double, duration: Double) -> Double? {
        guard value.isFinite, duration.isFinite, duration > 0 else { return nil }
        return min(duration, max(0, value))
    }
}

/// Invalidate pending picker/load operations on backgrounding and library reset.
struct PlaybackGate {
    private(set) var active = false
    private(set) var generation: UInt64 = 0
    mutating func setActive(_ value: Bool, invalidatePending: Bool = true) {
        if !value && invalidatePending { generation &+= 1 }
        active = value
    }
    mutating func invalidate() { generation &+= 1 }
    func accepts(_ token: UInt64) -> Bool { active && token == generation }
}

/// Tested navigation/formatting shared by the native reference-alignment views.
enum StudioRoute: String, CaseIterable {
    case home, library, playlists, occasions, assistant, mixer, status, more
    var title: String {
        switch self {
        case .home: return "LENOX"
        case .library: return "Library"
        case .playlists: return "Playlists"
        case .occasions: return "Occasions"
        case .assistant: return "Mix Assistant"
        case .mixer: return "Two-deck mixer"
        case .status: return "System Status"
        case .more: return "More"
        }
    }
    static func initial(arguments: [String]) -> StudioRoute {
        #if targetEnvironment(simulator)
        if let index = arguments.firstIndex(of: "--ci-screen"), arguments.indices.contains(index + 1),
           let route = StudioRoute(rawValue: arguments[index + 1]) { return route }
        #endif
        return arguments.contains("--ci-smoke") ? .mixer : .home
    }
    static func matches(title: String, query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return q.isEmpty || title.range(of: q, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }
    static func clock(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0, seconds < Double(Int.max / 2) else { return "0:00" }
        let value = Int(seconds)
        return "\(value / 60):" + String(format: "%02d", value % 60)
    }
}
