#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build reports
swiftc ios/LENOX/PlaylistStore.swift Tests/Playlists/main.swift -o .build/playlist-tests
.build/playlist-tests | tee reports/playlist-tests.json
python3 scripts/check_playlists.py | tee reports/playlist-source.json
bash scripts/ci-alignment.sh
UDID="$(python3 - <<'PY'
import json
with open('reports/simulator-devices.json') as f: data=json.load(f)
for runtime, devices in data['devices'].items():
    if 'iOS' in runtime:
        for device in devices:
            if device.get('isAvailable') and device['name'].startswith('iPhone'):
                print(device['udid']); raise SystemExit(0)
raise SystemExit('No iPhone simulator')
PY
)"
DATA_DIR="$(xcrun simctl get_app_container "$UDID" app.lenox.ios.test data)"
# Two distinct launches test actual disk restoration, not two references to one object.
for PHASE in write read; do
  xcrun simctl launch --terminate-running-process "$UDID" app.lenox.ios.test --ci-screen playlists "--ci-playlists-$PHASE"
  for attempt in $(seq 1 60); do
    [[ -s "$DATA_DIR/Documents/playlist-$PHASE.json" ]] && break
    sleep 1
  done
  test -s "$DATA_DIR/Documents/playlist-$PHASE.json"
  cp "$DATA_DIR/Documents/playlist-$PHASE.json" "reports/playlist-$PHASE.json"
  PHASE="$PHASE" python3 - <<'PY'
import json, os
phase=os.environ['PHASE']
r=json.load(open('reports/playlist-'+phase+'.json'))
assert r['ok'] is True and r['phase']==phase, r
assert len(r['checks']) == (5 if phase=='write' else 7), r
assert all(c['passed'] is True for c in r['checks']), r
assert r['source']==os.environ['GITHUB_SHA'], r
assert r['physical_device_tested'] is False
print(phase, 'native playlist checks PASS')
PY
  xcrun simctl io "$UDID" screenshot "out/playlist-$PHASE.png"
done
cp reports/playlist-{tests,source,write,read}.json out/
python3 - <<'PY'
import hashlib,json,pathlib,os
root=pathlib.Path('out')
entries=[{'path':str(p.relative_to(root)),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(root.rglob('*')) if p.is_file()]
(root/'playlist-evidence.json').write_text(json.dumps({'source':os.environ['GITHUB_SHA'],'files':entries,'real_files_picker_tested':False,'real_iphone_tested':False,'android_backup_compatibility':False,'independent_approval':False},indent=2)+'\n')
PY
