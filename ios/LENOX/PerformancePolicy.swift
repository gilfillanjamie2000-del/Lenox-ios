import Foundation

enum ReferenceStatus: Equatable {
    case saved, loaded, relink, unavailable
    var label: String {
        switch self {
        case .saved: return "Saved reference · access checked at load"
        case .loaded: return "Loaded on a deck"
        case .relink: return "Relink required · no file access saved"
        case .unavailable: return "File unavailable or changed · relink in Library"
        }
    }
    var symbol: String {
        switch self {
        case .saved: return "doc.badge.clock"
        case .loaded: return "checkmark.circle"
        case .relink, .unavailable: return "exclamationmark.triangle"
        }
    }
    static func resolve(bookmark: Bool, loaded: Bool, failed: Bool) -> Self {
        if !bookmark { return .relink }
        if failed { return .unavailable }
        return loaded ? .loaded : .saved
    }
}

enum PerformancePolicy {
    // A visual 33 1/3 rpm platter follows source position, including speed/seek.
    // This is NOT a scratch audio renderer or a beat/phase measurement.
    static func platterDegrees(position: Double) -> Double {
        guard position.isFinite, position >= 0 else { return 0 }
        return position.truncatingRemainder(dividingBy: 1.8) * 200
    }
    static func jog(position: Double, delta: Double, duration: Double) -> Double? {
        guard position.isFinite, delta.isFinite, abs(delta) <= 0.25 else { return nil }
        return MixPolicy.seek(position + delta, duration: duration)
    }
}

struct IntroGate {
    enum State: Equatable { case waiting, playing, finished }
    private(set) var state: State = .waiting
    mutating func begin(reduceMotion: Bool, assetValid: Bool) -> Bool {
        guard state == .waiting else { return false }
        state = reduceMotion || !assetValid ? .finished : .playing
        return state == .playing
    }
    mutating func finish() { state = .finished }
}
