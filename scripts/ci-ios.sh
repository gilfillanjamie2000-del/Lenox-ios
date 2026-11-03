#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
SOURCE_SHA="$(git rev-parse HEAD)"
if [[ -n "${GITHUB_SHA:-}" && "$SOURCE_SHA" != "$GITHUB_SHA" ]]; then echo 'Source SHA mismatch' >&2; exit 1; fi
[[ "$SOURCE_SHA" =~ ^[0-9a-f]{40}$ ]]
export LENOX_SOURCE_SHA="$SOURCE_SHA"
mkdir -p reports out .build
xcodebuild -version | tee reports/xcode-version.txt
sw_vers > reports/macos-version.txt
swift --version > reports/swift-version.txt
python3 scripts/check_source.py | tee reports/source-checks.json
swiftc ios/LENOX/MixPolicy.swift Tests/main.swift -o .build/policy-tests
.build/policy-tests | tee reports/policy-tests.json
# Verify checked-in project generation has no uncommitted drift.
python3 scripts/generate_project.py
git diff --exit-code -- ios/LENOX.xcodeproj
xcodebuild -project ios/LENOX.xcodeproj -scheme LENOX -configuration Debug \
  -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath .build/device \
  -resultBundlePath reports/device-build.xcresult CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= LENOX_SOURCE_SHA="$SOURCE_SHA" build \
  2>&1 | tee reports/device-build.log
xcodebuild -project ios/LENOX.xcodeproj -scheme LENOX -configuration Debug \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath .build/simulator \
  -resultBundlePath reports/simulator-build.xcresult CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= LENOX_SOURCE_SHA="$SOURCE_SHA" build \
  2>&1 | tee reports/simulator-build.log
xcrun simctl list devices available --json > reports/simulator-devices.json
UDID="$(python3 - <<'PY'
import json
with open('reports/simulator-devices.json') as f: data=json.load(f)
for runtime, devices in data['devices'].items():
    if 'iOS' in runtime:
        for d in devices:
            if d.get('isAvailable') and d['name'].startswith('iPhone'):
                print(d['udid']); raise SystemExit(0)
raise SystemExit('No available iPhone simulator')
PY
)"
# Fresh hosted runner: boot the selected device and block for readiness.
xcrun simctl boot "$UDID"
xcrun simctl bootstatus "$UDID" -b
SIM_APP=.build/simulator/Build/Products/Debug-iphonesimulator/LENOX.app
xcrun simctl install "$UDID" "$SIM_APP"
xcrun simctl launch --terminate-running-process "$UDID" app.lenox.ios.test --ci-smoke | tee reports/simulator-launch.txt
DATA_DIR="$(xcrun simctl get_app_container "$UDID" app.lenox.ios.test data)"
for attempt in $(seq 1 60); do
  [[ -s "$DATA_DIR/Documents/ci-smoke.json" ]] && break
  sleep 1
done
test -s "$DATA_DIR/Documents/ci-smoke.json"
cp "$DATA_DIR/Documents/ci-smoke.json" reports/simulator-smoke.json
xcrun simctl io "$UDID" screenshot reports/simulator-mixer.png
python3 - <<'PY'
import json, os
with open('reports/simulator-smoke.json') as f: r=json.load(f)
assert r['ok'] is True, r
assert len(r['checks']) == 12 and all(x['passed'] is True for x in r['checks']), r
assert r['source'] == os.environ['LENOX_SOURCE_SHA'], r
assert r['physical_device_tested'] is False
print('12 simulator synthetic-audio checks PASS; not physical-device evidence')
PY
DEVICE_APP=.build/device/Build/Products/Debug-iphoneos/LENOX.app
test -s "$DEVICE_APP/LENOX"
/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$DEVICE_APP/Info.plist" | grep -Fx app.lenox.ios.test
/usr/libexec/PlistBuddy -c 'Print :LENOXSourceCommit' "$DEVICE_APP/Info.plist" | grep -Fx "$SOURCE_SHA"
xcrun vtool -show-build "$DEVICE_APP/LENOX" | tee reports/device-mach-o.txt
grep -Eq 'platform[[:space:]]+IOS$' reports/device-mach-o.txt
! grep -q IOSSIMULATOR reports/device-mach-o.txt
test ! -e "$DEVICE_APP/embedded.mobileprovision"
mkdir -p .build/package/Payload
ditto "$DEVICE_APP" .build/package/Payload/LENOX.app
APP_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$DEVICE_APP/Info.plist")"
APP_BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$DEVICE_APP/Info.plist")"
NAME="LENOX-iOS-${APP_VERSION}-b${APP_BUILD}-${SOURCE_SHA:0:12}-UNSIGNED.ipa"
(cd .build/package && /usr/bin/zip -qry "../../out/$NAME" Payload)
unzip -t "out/$NAME" > reports/ipa-zip-test.txt
# Simulator .app is separately labelled; it cannot be installed on an iPhone.
tar -czf "out/LENOX-${SOURCE_SHA:0:12}-SIMULATOR.app.tar.gz" -C "$(dirname "$SIM_APP")" LENOX.app
git archive --format=zip --prefix=LENOX-ios/ HEAD > "out/LENOX-${SOURCE_SHA:0:12}-source.zip"
python3 - <<'PY'
import datetime, hashlib, json, os, pathlib, subprocess
source=os.environ['LENOX_SOURCE_SHA']
files=[]
for p in sorted(pathlib.Path('out').iterdir()):
    if p.is_file():
        files.append({'name':p.name,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
r={'source_commit':source,'repository':os.environ.get('GITHUB_REPOSITORY'),
   'workflow_run_id':os.environ.get('GITHUB_RUN_ID'), 'run_attempt':os.environ.get('GITHUB_RUN_ATTEMPT'),
   'recorded_at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),
   'signing':'UNSIGNED; no provisioning profile', 'installable_on_iphone':False,
   'physical_device_tested':False, 'approved_visual_parity':False,
   'private_android_source_included':False, 'approved_android_artwork_included':True,
   'policy_tests':json.load(open('reports/policy-tests.json')),
   'simulator_tests':json.load(open('reports/simulator-smoke.json')),
   'xcode':pathlib.Path('reports/xcode-version.txt').read_text().strip(),'files':files}
pathlib.Path('out/build-provenance.json').write_text(json.dumps(r,indent=2)+'\n')
pathlib.Path('out/SHA256SUMS').write_text(''.join(f"{x['sha256']}  {x['name']}\n" for x in files))
pathlib.Path('out/READ_ME_FIRST.txt').write_text('LENOX iOS native test host. UNSIGNED IPA: NOT directly installable on iPhone.\nApple signing/provisioning and physical-device acceptance remain required.\nSimulator package is for Xcode Simulator only. Contains two owner-authorised original artwork/video assets; no Android implementation or configuration.\n')
PY
cp reports/simulator-smoke.json reports/policy-tests.json reports/simulator-mixer.png README_MEMORY_ZIP_POLICY.md out/
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  printf '## LENOX iOS test build\nSource: `%s`\n\n- Device and simulator compilation succeeded.\n- Portable Swift tests and 12 generated-audio simulator checks passed.\n- IPA is **UNSIGNED**, not directly installable on iPhone.\n- No physical-device or approved-design acceptance claimed.\n' "$SOURCE_SHA" >> "$GITHUB_STEP_SUMMARY"
fi
