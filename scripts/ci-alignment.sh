#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p reports .build
python3 scripts/check_alignment.py | tee reports/alignment-contract.json
swiftc ios/LENOX/MixPolicy.swift Tests/Alignment/main.swift -o .build/alignment-tests
.build/alignment-tests | tee reports/alignment-tests.json
bash scripts/ci-ios.sh
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
mkdir -p out/alignment-screens
for SCREEN in home library playlists occasions assistant status; do
  xcrun simctl launch --terminate-running-process "$UDID" app.lenox.ios.test --ci-screen "$SCREEN"
  sleep 2
  xcrun simctl io "$UDID" screenshot "out/alignment-screens/$SCREEN.png"
done
cp reports/simulator-mixer.png out/alignment-screens/mixer.png
cp reports/alignment-tests.json reports/alignment-contract.json out/
# These are Simulator captures, not approved pixel comparisons or physical-device evidence.
python3 - <<'PY'
import hashlib,json,pathlib
root=pathlib.Path('out')
files=[{'path':str(p.relative_to(root)),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(root.rglob('*')) if p.is_file()]
(root/'alignment-evidence.json').write_text(json.dumps({'files':files,'visual_parity_verified':False,'functional_parity_verified':False,'physical_device_tested':False},indent=2)+'\n')
PY
