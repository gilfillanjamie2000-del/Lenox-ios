import Foundation
var passed = 0, failed = 0
func check(_ name: String, _ ok: Bool) { if ok { passed += 1 } else { failed += 1; fputs("FAIL: \(name)\n", stderr) } }
func rejects(_ name: String, _ action: () throws -> Void) { do { try action(); check(name, false) } catch { check(name, true) } }
final class File: PlaylistFileIO {
    var bytes: Data?, writes = 0, fail = false
    func read() throws -> Data? { bytes }
    func write(_ data: Data) throws { if fail { throw PlaylistFailure.locked }; bytes = data; writes += 1 }
}
func track(_ title: String = "Local song") -> SavedTrack { SavedTrack(id: UUID(), title: title, byteCount: 1234, bookmark: Data([1])) }
let f = File(), s = PlaylistStore(file: File())
let store = PlaylistStore(file: f), a = track("A"), b = track("B")
try store.saveTracks([a,b], revision: 0)
check("batch saves both in order", store.state.tracks == [a,b])
check("batch is one revision and write", store.state.revision == 1 && f.writes == 1)
check("actual reload preserves both", PlaylistStore(file: f).state == store.state)
let before = store.state, bytes = f.bytes
rejects("stale batch rejected") { try store.saveTracks([track()], revision: 0) }
rejects("empty batch rejected") { try store.saveTracks([], revision: 1) }
rejects("duplicate identities rejected") { try store.saveTracks([a], revision: 1) }
rejects("bad member rejects entire batch") { try store.saveTracks([track(), track("")], revision: 1) }
rejects("capacity checked before commit") { try store.saveTracks((0..<19).map { _ in track() }, revision: 1) }
check("all rejections preserve state and disk", store.state == before && f.bytes == bytes && f.writes == 1)
f.fail = true
rejects("write failure rejects entire batch") { try store.saveTracks([track(),track()], revision: 1) }
check("write failure does not publish memory", store.state == before && f.bytes == bytes)
try s.saveTracks((0..<20).map { _ in track() }, revision: 0)
check("unchanged 20 track limit", s.state.tracks.count == 20)
var gate = PlaybackGate(); gate.setActive(true); let token = gate.generation
gate.setActive(false, invalidatePending: false)
check("inactive suspends permission", !gate.accepts(token))
check("inactive preserves picker identity", gate.generation == token)
gate.setActive(true)
check("foreground permits same picker result", gate.accepts(token))
gate.setActive(false)
gate.setActive(true)
check("background rejects stale picker", !gate.accepts(token))
print("{\"import_assertions_passed\":\(passed),\"failed\":\(failed)}")
exit(failed == 0 ? 0 : 1)
