#!/usr/bin/env python3
"""Small fail-closed packaging checks. Not a replacement for independent review."""
import hashlib, json, plistlib, re
from pathlib import Path
root = Path(__file__).resolve().parents[1]
info = plistlib.loads((root/'ios/LENOX/Info.plist').read_bytes())
assert info['CFBundleIdentifier'] == '$(PRODUCT_BUNDLE_IDENTIFIER)'
assert 'NSMicrophoneUsageDescription' not in info
assert 'UIBackgroundModes' not in info
app = (root/'ios/LENOX/AudioModel.swift').read_text(encoding='utf-8')
for required in ['url.startAccessingSecurityScopedResource()', 'url.stopAccessingSecurityScopedResource()',
                 'guard gate.accepts(pickerToken)', 'if !value { pauseAll() }',
                 'guard valid(deck), active, let player', 'tracks.contains(where:',
                 '"--ci-smoke"', 'physical_device_tested']:
    assert required in app, required
for forbidden in ['URLSession', 'AVAudioRecorder', 'allowsArbitraryLoads', 'WKScriptMessageHandler']:
    assert forbidden not in app, forbidden
for p in root.rglob('*'):
    if p.is_file() and not any(x in p.parts for x in ['.git','.build','reports','out','__pycache__']):
        assert p.suffix.lower() not in ['.p12','.mobileprovision','.key','.pem'], p
project = (root/'ios/LENOX.xcodeproj/project.pbxproj').read_text(encoding='utf-8')
for name in ['LenoxApp.swift', 'AudioModel.swift', 'MixPolicy.swift']:
    assert name in project
assert 'CODE_SIGNING_ALLOWED = NO;' in project
print(json.dumps({'source_contract_checks': 'PASS', 'scope': 'static checks only'}, indent=2))
