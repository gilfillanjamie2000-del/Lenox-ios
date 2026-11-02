import Foundation

var passed = 0, failed = 0
func check(_ title: String, _ value: @autoclosure () -> Bool) { if value() { passed += 1 } else { failed += 1; print("FAIL: \(title)") } }
func rejects(_ title: String, _ body: () throws -> Void) { do { try body(); failed += 1; print("FAIL accepted: \(title)") } catch { passed += 1 } }
final class MemoryFile: PlaylistFileIO {
    var bytes: Data?; var failWrite = false; var failRead = false; var writes = 0
    func read() throws -> Data? { if failRead { throw PlaylistFailure.locked }; return bytes }
    func write(_ data: Data) throws { if failWrite { throw PlaylistFailure.locked }; bytes = data; writes += 1 }
}
let io = MemoryFile(), s = PlaylistStore(file: io)
func track(_ title: String = "Synthetic WAV") -> SavedTrack { SavedTrack(id: UUID(), title: title, byteCount: 1024, bookmark: Data([1,2,3])) }
let a = track("A"), b = track("B")
try s.saveTrack(a, revision: 0); try s.saveTrack(b, revision: 1)
let id = try s.create(name: "Evening", tracks: [a.id,b.id], revision: 2)
check("create saved", s.state.playlists.count == 1 && io.writes == 3)
for name in ["Evening", "EVENING", "Ｅｖｅｎｉｎｇ"] { rejects("collision \(name)") { try s.create(name: name, tracks: [], revision: s.state.revision) } }
for name in ["", " leading", "trailing ", "bad\nname", "\u{00A0}name", "bad\u{200D}name", String(repeating:"x",count:81),String(repeating:"😀",count:41)] {
    rejects("invalid name") { try s.create(name: name, tracks: [], revision: s.state.revision) }
}
let before = s.state
rejects("stale editor") { try s.edit(id:id,name:"Changed",tracks:[],revision:0) }
rejects("duplicate position") { try s.edit(id:id,name:"Evening",tracks:[a.id,a.id],revision:s.state.revision) }
rejects("unauthorised id") { try s.edit(id:id,name:"Evening",tracks:[UUID()],revision:s.state.revision) }
check("rejected edits preserve state", s.state == before)
try s.edit(id:id,name:"Night",tracks:[b.id,a.id],revision:s.state.revision)
check("rename/reorder",s.state.playlists[0].trackIDs == [b.id,a.id] && s.state.playlists[0].name == "Night")
let diskBefore = io.bytes, stateBefore = s.state
io.failWrite = true
rejects("failed edit") { try s.edit(id:id,name:"Lost",tracks:[],revision:s.state.revision) }
rejects("failed delete") { try s.delete(id:id,revision:s.state.revision) }
rejects("failed add track") { try s.saveTrack(track(),revision:s.state.revision) }
check("failed disk writes preserve state and bytes",s.state == stateBefore && io.bytes == diskBefore)
io.failWrite = false
let reopened = PlaylistStore(file:io)
check("reopen exact state", reopened.state == s.state && !reopened.blocked)
rejects("referenced track cannot be forgotten") { try s.forgetTrack(id:a.id,revision:s.state.revision) }
let backup = try s.export(id:id), text = String(data:backup,encoding:.utf8)!
check("no capabilities exported", !text.contains("bookmark") && !text.contains("file:") && !text.contains("id\""))
let imported = PlaylistStore(file:MemoryFile())
let importedID = try imported.importBackup(backup,revision:0)
check("import preserves name and order", imported.state.playlists[0].name == "Night" && imported.state.tracks.map(\.title) == ["B","A"])
check("import new identities only", Set(imported.state.tracks.map(\.id)).isDisjoint(with:[a.id,b.id]))
check("import does not authorise files", imported.state.tracks.allSatisfy { $0.bookmark == nil })
let roundtrip = try PlaylistPolicy.decodeTransfer(imported.export(id:importedID))
let originalTransfer = try PlaylistPolicy.decodeTransfer(backup)
check("metadata roundtrip", roundtrip == originalTransfer)
rejects("import collision") { try imported.importBackup(backup,revision:imported.state.revision) }
for bad in ["", "{}", "[]", "null", "{\"format\":\"lenox-playlist\",\"version\":2,\"name\":\"bad\",\"tracks\":[]}", "{\"format\":\"lenox-playlist\",\"version\":true,\"name\":\"bad\",\"tracks\":[]}"] {
    rejects("malformed/unsupported backup") { try imported.importBackup(Data(bad.utf8),revision:imported.state.revision) }
}
var object = try JSONSerialization.jsonObject(with:backup) as! [String:Any]
object["bookmark"] = "evil"
rejects("injected root capability") { try imported.importBackup(JSONSerialization.data(withJSONObject:object),revision:imported.state.revision) }
object.removeValue(forKey:"bookmark"); object["tracks"] = [["title":"X","byteCount":1024,"url":"file:///etc/passwd"]]
rejects("injected file path") { try imported.importBackup(JSONSerialization.data(withJSONObject:object),revision:imported.state.revision) }
object["tracks"] = [["title":"X","byteCount":-1]]
rejects("negative size") { try imported.importBackup(JSONSerialization.data(withJSONObject:object),revision:imported.state.revision) }
rejects("oversized backup") { try imported.importBackup(Data(repeating:32,count:PlaylistPolicy.maxBytes+1),revision:imported.state.revision) }
try s.edit(id:id,name:"Night",tracks:[b.id],revision:s.state.revision)
try s.forgetTrack(id:a.id,revision:s.state.revision)
check("remove membership then forget ref",s.state.tracks.count == 1)
try s.delete(id:id,revision:s.state.revision)
check("delete leaves tracks",s.state.playlists.isEmpty && s.state.tracks.count == 1)
let replacement = SavedTrack(id:b.id,title:"Relinked",byteCount:100,bookmark:Data([4]))
try s.saveTrack(replacement,replacing:b.id,revision:s.state.revision)
check("explicit relink preserves id",s.state.tracks[0] == replacement)
rejects("relink unknown") { try s.saveTrack(track(),replacing:UUID(),revision:s.state.revision) }
for corrupted in [Data(),Data("truncated".utf8),Data("{\"format\":\"unknown\",\"version\":99,\"revision\":0,\"tracks\":[],\"playlists\":[]}".utf8)] {
    let f = MemoryFile(); f.bytes = corrupted; let broken = PlaylistStore(file:f)
    check("bad store locked",broken.blocked)
    rejects("bad store not overwritten") { try broken.create(name:"Keep",tracks:[],revision:0) }
    check("bad bytes preserved",f.bytes == corrupted && f.writes == 0)
}
let unreadable = MemoryFile(); unreadable.failRead = true
check("read failure locked",PlaylistStore(file:unreadable).blocked)
let moved = MemoryFile(), stale = PlaylistStore(file:MemoryFile())
_ = stale
let changed = PlaylistStore(file:moved); moved.bytes = Data("other-process".utf8)
rejects("external edit blocks overwrite") { try changed.create(name:"New",tracks:[],revision:0) }
check("external edit retained",changed.blocked && moved.bytes == Data("other-process".utf8))
let bounded = PlaylistStore(file:MemoryFile())
try bounded.saveTracks((0..<500).map { _ in track() }, revision: 0)
try bounded.saveTrack(track(),revision:bounded.state.revision)
check("single and batch inserts exceed old song cap", bounded.state.tracks.count == 501)
let largeID = try bounded.create(name: "Large set", tracks: bounded.state.tracks.map(\.id), revision: bounded.state.revision)
let largeBackup = try bounded.export(id: largeID)
let largeDecoded = try PlaylistPolicy.decodeTransfer(largeBackup)
check("large playlist export exceeds old song cap", largeDecoded.tracks.count == 501)
let largeImportFile = MemoryFile(), largeImport = PlaylistStore(file: largeImportFile)
try largeImport.importBackup(largeBackup, revision: 0)
check("large playlist backup restores every entry", largeImport.state.tracks.count == 501 && largeImport.state.playlists[0].trackIDs.count == 501)
check("large library reload has no count cap", PlaylistStore(file: largeImportFile).state == largeImport.state)
try bounded.delete(id: largeID, revision: bounded.state.revision)
for n in 0..<100 { try bounded.create(name:"Set \(n)",tracks:[],revision:bounded.state.revision) }
rejects("playlist limit") { try bounded.create(name:"Extra",tracks:[],revision:bounded.state.revision) }
// Actual disk roundtrip, not a mocked save.
let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
defer { try? FileManager.default.removeItem(at:folder) }
let disk = PlaylistDiskFile(url:folder.appendingPathComponent("library.json")), real = PlaylistStore(file:disk)
try real.saveTrack(a,revision:0); let rid = try real.create(name:"Disk",tracks:[a.id],revision:1)
check("actual disk reload",PlaylistStore(file:disk).state == real.state)
let originalBytes = try disk.read()
try real.edit(id:rid,name:"Disk 2",tracks:[],revision:2)
let replacedBytes = try disk.read()
check("atomic replacement reload",PlaylistStore(file:disk).state.playlists[0].name == "Disk 2" && replacedBytes != originalBytes)
try FileManager.default.removeItem(at:disk.url)
try FileManager.default.createSymbolicLink(at:disk.url,withDestinationURL:folder.appendingPathComponent("not-library"))
check("symlink store blocked",PlaylistStore(file:disk).blocked)
print("{\"playlist_assertions_passed\":\(passed),\"failed\":\(failed)}")
if failed > 0 { exit(1) }
