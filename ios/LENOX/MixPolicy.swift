import Foundation

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
    mutating func setActive(_ value: Bool) {
        if !value { generation &+= 1 }
        active = value
    }
    mutating func invalidate() { generation &+= 1 }
    func accepts(_ token: UInt64) -> Bool { active && token == generation }
}
