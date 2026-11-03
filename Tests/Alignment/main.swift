import Foundation
var checks = 0
var failures: [String] = []
func expect(_ name: String, _ condition: Bool) { checks += 1; if !condition { failures.append(name) } }
expect("unique seven routes", Set(StudioRoute.allCases.map(\.rawValue)).count == 7)
for route in StudioRoute.allCases {
    expect("route round-trip \(route.rawValue)", StudioRoute(rawValue: route.rawValue) == route)
    expect("label \(route.rawValue)", !route.title.isEmpty)
}
expect("normal home", StudioRoute.initial(arguments: []) == .home)
expect("audio smoke mixer", StudioRoute.initial(arguments: ["--ci-smoke"]) == .mixer)
expect("empty query", StudioRoute.matches(title: "Local Music", query: ""))
expect("trimmed query", StudioRoute.matches(title: "Local Music", query: "  MUSIC \n"))
expect("diacritic match", StudioRoute.matches(title: "Café", query: "cafe"))
expect("no invented result", !StudioRoute.matches(title: "Techno", query: "wedding"))
expect("zero clock", StudioRoute.clock(0) == "0:00")
expect("seconds clock", StudioRoute.clock(9.8) == "0:09")
expect("minute clock", StudioRoute.clock(61.9) == "1:01")
expect("hour clock", StudioRoute.clock(3600) == "60:00")
for value in [Double.nan, Double.infinity, -Double.infinity, -1, Double.greatestFiniteMagnitude] {
    expect("invalid time", StudioRoute.clock(value) == "0:00")
}
expect("lower tempo bound", MixPolicy.validRate(0.5))
expect("upper tempo bound", MixPolicy.validRate(2))
expect("reject out-of-range tempo", !MixPolicy.validRate(2.01))
// Fixed behavioural expectations are independent of any platform's implementation.
for (fader, a, b) in [(0.0,1.0,0.0),(0.25,1.0,0.5),(0.5,1.0,1.0),(0.75,0.5,1.0),(1.0,0.0,1.0)] {
    expect("A reference gain \(fader)", abs(Double(MixPolicy.level(deck: 0, crossfade: fader, gain: 1, channel: 1))-a) < 0.00001)
    expect("B reference gain \(fader)", abs(Double(MixPolicy.level(deck: 1, crossfade: fader, gain: 1, channel: 1))-b) < 0.00001)
}
let report: [String: Any] = ["suite":"LENOX reference alignment policy", "passed":checks-failures.count, "failed":failures.count, "failures":failures, "scope":"Executed native Swift logic; not rendered UI, independent approval or device parity"]
print(String(data: try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted,.sortedKeys]), encoding: .utf8)!)
exit(failures.isEmpty ? 0 : 1)
