#!/usr/bin/env python3
"""Compile real Swift variants; require assertion failures, never compiler errors."""
from pathlib import Path
import subprocess, tempfile, json
root=Path(__file__).resolve().parents[1]
source=(root/'ios/LENOX/PlaylistStore.swift').read_text()
probe=r'''
import Foundation
final class Memory: PlaylistFileIO {
 var bytes: Data?; var fail=false
 func read() throws -> Data? { bytes }
 func write(_ data: Data) throws { if fail { throw PlaylistFailure.locked }; bytes=data }
}
var fails=0
func check(_ value: Bool) { if !value { fails += 1 } }
func denies(_ f: () throws -> Void) -> Bool { do { try f(); return false } catch { return true } }
let io=Memory(), store=PlaylistStore(file:io)
let a=SavedTrack(id:UUID(),title:"A",byteCount:100,bookmark:Data([1]))
try store.saveTrack(a,revision:0)
let id=try store.create(name:"NIGHT",tracks:[a.id],revision:1)
check(denies { try store.create(name:"Ｎｉｇｈｔ",tracks:[],revision:store.state.revision) })
check(denies { try store.edit(id:id,name:"STALE",tracks:[],revision:0) })
let before=store.state, old=io.bytes
io.fail=true
check(denies { try store.edit(id:id,name:"Failure",tracks:[],revision:store.state.revision) })
check(store.state==before && io.bytes==old)
io.fail=false
let transfer=try PlaylistPolicy.encode(PlaylistTransfer(name:"Import",tracks:[.init(title:"X",byteCount:1)]))
let imported=PlaylistStore(file:Memory()); try imported.importBackup(transfer,revision:0)
check(imported.state.tracks[0].bookmark == nil)
print("PROBE_FAILED_ASSERTIONS=\(fails)")
if fails>0 { exit(1) }
'''
variants={
 'baseline':source,
 'early_memory_commit':source.replace('try file.write(bytes) //','state = candidate\n        try file.write(bytes) //'),
 'stale_revision_bypass':source.replace('revision == state.revision, ',''),
 'import_grants_capability':source.replace('byteCount: $0.byteCount, bookmark: nil','byteCount: $0.byteCount, bookmark: Data([1])'),
 'name_collision_bypass':source.replace('names.insert(key(p.name)).inserted,','true,').replace('guard !s.playlists.contains(where: { PlaylistPolicy.key($0.name) == PlaylistPolicy.key(name) }) else { throw PlaylistFailure.collision }',''),
}
results=[]
with tempfile.TemporaryDirectory() as temp:
 d=Path(temp); (d/'main.swift').write_text(probe)
 for name, body in variants.items():
  assert name=='baseline' or body!=source
  (d/'PlaylistStore.swift').write_text(body)
  compile=subprocess.run(['swiftc',str(d/'PlaylistStore.swift'),str(d/'main.swift'),'-o',str(d/'probe')],capture_output=True,text=True)
  if compile.returncode: raise SystemExit(compile.stderr)
  run=subprocess.run([str(d/'probe')],capture_output=True,text=True)
  assert 'PROBE_FAILED_ASSERTIONS=' in run.stdout, run.stderr
  count=int(run.stdout.split('PROBE_FAILED_ASSERTIONS=')[1].strip())
  assert (run.returncode==0 and count==0) if name=='baseline' else (run.returncode==1 and count>0), (name,run.stdout)
  results.append({'variant':name,'compiled':True,'failed_assertions':count,'exit':run.returncode})
print(json.dumps({'mutation_probes':results},indent=2))
