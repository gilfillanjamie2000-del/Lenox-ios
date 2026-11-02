#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p reports .build
# Keep readable UI attachments even when an assertion stops the pipeline.
trap 'if [[ -d reports/studio-ui.xcresult && ! -d out/ui-captures ]]; then mkdir -p reports/ui-failure-captures; xcrun xcresulttool export attachments --path reports/studio-ui.xcresult --output-path reports/ui-failure-captures || true; fi' EXIT
xcodebuild -version | tee reports/studio-xcode-version.txt
swift --version | tee reports/studio-swift-version.txt
git rev-parse HEAD | tee reports/studio-source.txt
python3 scripts/check_studio_assets.py | tee reports/studio-assets.json
swiftc ios/LENOX/MixPolicy.swift ios/LENOX/PerformancePolicy.swift Tests/Performance/main.swift -o .build/performance-tests
.build/performance-tests | tee reports/performance-policy.json
swiftc ios/LENOX/MixPolicy.swift ios/LENOX/PlaylistStore.swift Tests/Import/main.swift -o .build/import-tests
.build/import-tests | tee reports/import-policy.json
python3 scripts/test_playlist_mutations.py | tee reports/playlist-mutations.txt
# Compile the new UI-test target before waiting for a cold Simulator boot.
# The following established build chain reuses this derived-data directory.
python3 scripts/generate_project.py
git diff --exit-code -- ios/LENOX.xcodeproj
xcodebuild -project ios/LENOX.xcodeproj -scheme LENOX -configuration Debug \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .build/simulator -resultBundlePath reports/ui-preflight.xcresult \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= \
  LENOX_SOURCE_SHA="$GITHUB_SHA" build-for-testing 2>&1 | tee reports/ui-preflight.log
# Reuse the complete established native build + baseline regression chain.
bash scripts/ci-playlists.sh
UDID="$(python3 - <<'PY'
import json
data=json.load(open('reports/simulator-devices.json'))
for runtime, devices in data['devices'].items():
    if 'iOS' in runtime:
        for d in devices:
            if d.get('isAvailable') and d['name'].startswith('iPhone'):
                print(d['udid']); raise SystemExit(0)
raise SystemExit('No iPhone Simulator')
PY
)"
DATA_DIR="$(xcrun simctl get_app_container "$UDID" app.lenox.ios.test data)"
xcrun simctl launch --terminate-running-process "$UDID" app.lenox.ios.test --ci-screen mixer --ci-performance
for attempt in $(seq 1 60); do
  [[ -s "$DATA_DIR/Documents/performance-smoke.json" ]] && break
  sleep 1
done
cp "$DATA_DIR/Documents/performance-smoke.json" reports/performance-smoke.json
python3 - <<'PY'
import json,os
r=json.load(open('reports/performance-smoke.json'))
assert r['ok'] is True and len(r['checks']) == 34, r
assert all(x['passed'] is True for x in r['checks']), r
assert r['source'] == os.environ['GITHUB_SHA'] and r['physical_device_tested'] is False, r
assert r['scratch_audio_implemented'] is False
print('34 native performance/import/video checks PASS; Simulator only')
PY
for SCENARIO in completed missing; do
  rm -f "$DATA_DIR/Documents/intro-result.json"
  if [[ "$SCENARIO" == missing ]]; then
    xcrun simctl launch --terminate-running-process "$UDID" app.lenox.ios.test --ci-intro --ci-intro-missing
  else
    xcrun simctl launch --terminate-running-process "$UDID" app.lenox.ios.test --ci-intro
  fi
  for attempt in $(seq 1 20); do
    [[ -s "$DATA_DIR/Documents/intro-result.json" ]] && break
    sleep 1
  done
  cp "$DATA_DIR/Documents/intro-result.json" "reports/intro-$SCENARIO.json"
  SCENARIO="$SCENARIO" python3 - <<'PY'
import json,os
scenario=os.environ['SCENARIO']
r=json.load(open('reports/intro-'+scenario+'.json'))
assert r['reason'] == scenario and r['source'] == os.environ['GITHUB_SHA'], r
assert r['physical_device_tested'] is False
print('Native intro',scenario,'PASS')
PY
done
xcodebuild -project ios/LENOX.xcodeproj -scheme LENOX -configuration Debug \
  -sdk iphonesimulator -destination "id=$UDID" -derivedDataPath .build/simulator \
  -resultBundlePath reports/studio-ui.xcresult -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= \
  LENOX_SOURCE_SHA="$GITHUB_SHA" test 2>&1 | tee reports/studio-ui.log
mkdir -p out/ui-captures
xcrun xcresulttool export attachments --path reports/studio-ui.xcresult --output-path out/ui-captures
python3 scripts/check_studio_assets.py --app .build/device/Build/Products/Debug-iphoneos/LENOX.app | tee reports/bundled-assets.json
cp reports/performance-{policy,smoke}.json reports/studio-assets.json reports/bundled-assets.json out/
cp reports/import-policy.json out/
cp reports/intro-{completed,missing}.json out/
# Preserve full toolchain/test logs and xcresults, not just a success summary.
tar -czf out/studio-test-reports.tar.gz reports
python3 - <<'PY'
import hashlib,json,pathlib,os
root=pathlib.Path('out')
entries=[{'path':str(p.relative_to(root)),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(root.rglob('*')) if p.is_file()]
(root/'studio-evidence.json').write_text(json.dumps({'source':os.environ['GITHUB_SHA'],'files':entries,'physical_device_tested':False,'scratch_audio_implemented':False,'signing':'UNSIGNED','installable_on_iphone':False,'independent_approval':False},indent=2)+'\n')
PY
