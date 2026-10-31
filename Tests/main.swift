import Foundation

var passed = 0
var failed: [String] = []
func check(_ condition: @autoclosure () -> Bool, _ name: String) {
    if condition() { passed += 1 } else { failed.append(name) }
}
func level(_ deck: Int, _ fader: Double, _ gain: Double = 1, _ channel: Double = 1) -> Float {
    MixPolicy.level(deck: deck, crossfade: fader, gain: gain, channel: channel)
}
check(level(0, 0) == 1, "left: deck A full")
check(level(1, 0) == 0, "left: deck B silent")
check(level(0, 1) == 0, "right: deck A silent")
check(level(1, 1) == 1, "right: deck B full")
check(level(0, 0.5) == 1 && level(1, 0.5) == 1, "centre-full curve")
check(level(0, 0.5, 0.5, 0.5) == 0.25, "gain and channel multiply")
check(level(0, 0.75) == 0.5, "A intermediate fader")
check(level(1, 0.25) == 0.5, "B intermediate fader")
check(level(0, 0, 0.75) == 1, "final level clipped to one")
check(level(0, 0.5, 0) == 0, "gain mute")
check(level(1, 0.5, 1, 0) == 0, "channel mute")
check(level(-1, 0.5) == 0 && level(2, 0.5) == 0, "invalid deck")
for value in [-0.1, 1.1, Double.nan, Double.infinity, -Double.infinity] {
    check(level(0, value) == 0, "invalid fader \(value)")
    check(level(0, 0.5, value) == 0, "invalid gain \(value)")
    check(level(0, 0.5, 1, value) == 0, "invalid channel \(value)")
}
check(MixPolicy.validRate(0.5) && MixPolicy.validRate(2), "rate boundaries")
check(!MixPolicy.validRate(0.49) && !MixPolicy.validRate(2.01), "rate bounds reject")
check(!MixPolicy.validRate(.nan) && !MixPolicy.validRate(.infinity), "rate finite")
check(MixPolicy.seek(-1, duration: 10) == 0, "seek lower bound")
check(MixPolicy.seek(20, duration: 10) == 10, "seek upper bound")
check(MixPolicy.seek(4, duration: 10) == 4, "seek middle")
check(MixPolicy.seek(.nan, duration: 10) == nil, "seek rejects NaN")
check(MixPolicy.seek(2, duration: 0) == nil, "seek rejects empty media")
var gate = PlaybackGate()
check(!gate.accepts(gate.generation), "initial inactive")
gate.setActive(true)
let first = gate.generation
check(gate.accepts(first), "active request accepted")
gate.setActive(false)
check(!gate.accepts(first), "background request rejected")
gate.setActive(true)
check(!gate.accepts(first), "old request rejected after foreground")
let second = gate.generation
check(gate.accepts(second), "fresh foreground request")
gate.invalidate()
check(!gate.accepts(second), "library reset rejects old request")
let result: [String: Any] = ["suite": "LENOX portable mixer policy", "passed": passed,
                            "failed": failed.count, "failures": failed,
                            "scope": "native Swift policy tests; not device/audio validation"]
let bytes = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
print(String(decoding: bytes, as: UTF8.self))
if !failed.isEmpty { exit(1) }
