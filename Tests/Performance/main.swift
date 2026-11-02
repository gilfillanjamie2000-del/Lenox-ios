import Foundation
var checks = 0
var failures: [String] = []
func expect(_ name: String, _ condition: Bool) { checks += 1; if !condition { failures.append(name) } }
expect("zero platter", PerformancePolicy.platterDegrees(position: 0) == 0)
expect("half rotation follows source", abs(PerformancePolicy.platterDegrees(position: 0.9) - 180) < 0.0001)
expect("whole rotation", abs(PerformancePolicy.platterDegrees(position: 1.8)) < 0.0001)
expect("seek-derived angle", abs(PerformancePolicy.platterDegrees(position: 2.7) - 180) < 0.0001)
for value in [Double.nan, Double.infinity, -1] { expect("invalid platter position", PerformancePolicy.platterDegrees(position: value) == 0) }
expect("forward jog", PerformancePolicy.jog(position: 1, delta: 0.05, duration: 3) == 1.05)
expect("backward jog", PerformancePolicy.jog(position: 1, delta: -0.05, duration: 3) == 0.95)
expect("lower jog clamp", PerformancePolicy.jog(position: 0.01, delta: -0.05, duration: 3) == 0)
expect("upper jog clamp", PerformancePolicy.jog(position: 2.99, delta: 0.05, duration: 3) == 3)
for delta in [Double.nan, Double.infinity, -0.26, 0.26] { expect("reject unsafe jog", PerformancePolicy.jog(position: 1, delta: delta, duration: 3) == nil) }
expect("reject unknown duration", PerformancePolicy.jog(position: 1, delta: 0.1, duration: 0) == nil)
expect("reject invalid position", PerformancePolicy.jog(position: .nan, delta: 0.1, duration: 3) == nil)
expect("bookmark does not assert access", ReferenceStatus.resolve(bookmark: true, loaded: false, failed: false) == .saved)
expect("loaded status", ReferenceStatus.resolve(bookmark: true, loaded: true, failed: false) == .loaded)
expect("failure overrides cached load", ReferenceStatus.resolve(bookmark: true, loaded: true, failed: true) == .unavailable)
expect("unlinked remains unauthorised", ReferenceStatus.resolve(bookmark: false, loaded: true, failed: false) == .relink)
var intro = IntroGate()
expect("valid intro begins", intro.begin(reduceMotion: false, assetValid: true))
expect("intro cannot start twice", !intro.begin(reduceMotion: false, assetValid: true))
intro.finish()
expect("completion is final", intro.state == .finished && !intro.begin(reduceMotion: false, assetValid: true))
intro.finish(); expect("skip/error/background are idempotent", intro.state == .finished)
var motion = IntroGate()
expect("reduce motion goes directly to app", !motion.begin(reduceMotion: true, assetValid: true) && motion.state == .finished)
var missing = IntroGate()
expect("asset mismatch goes directly to app", !missing.begin(reduceMotion: false, assetValid: false) && missing.state == .finished)
expect("more route", StudioRoute(rawValue: "more") == .more)
let report: [String: Any] = ["suite": "LENOX performance and launch policies", "passed": checks - failures.count, "failed": failures.count, "failures": failures]
print(String(data: try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]), encoding: .utf8)!)
exit(failures.isEmpty ? 0 : 1)
