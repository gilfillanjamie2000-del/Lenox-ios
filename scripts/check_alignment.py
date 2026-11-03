#!/usr/bin/env python3
"""Read-only source-contract checks, not a rendered visual-parity test."""
import json
from pathlib import Path
root = Path(__file__).resolve().parents[1]
reference = json.loads((root/'docs/parity/android-reference.json').read_text())
assert reference['android']['source_commit'] == '54f01bb213a5d30eaba99ea1f16f1d547b1d82ed'
assert reference['android']['canonical_ui_blob'] == '5504651b59f9af4d6419e45c1045c2899363fb64'
assert reference['dock'] == ['Home','Library','Playlists','Mix']
for name in ['visual_parity_verified','functional_parity_verified','device_pair_tested','independent_review_passed','private_android_assets_published']:
    assert reference[name] is False, 'Do not promote a source contract into an approval: ' + name
assert len(reference['known_differences']) >= 10
ui = (root/'ios/LENOX/LenoxApp.swift').read_text()
audio = (root/'ios/LENOX/AudioModel.swift').read_text()
for text in ['dockItem("Home"','dockItem("Library"','dockItem("Playlists"','dockItem("Mix"',
             'in: 0.5...2, step: 0.01','"▶ Load & play"','"■ Stop"','"⏸ Pause"','"▶ Resume"',
             'audio.loadAndPlay(track, into: index)','StudioRoute.matches','ViewThatFits',
             'textSize.isAccessibilitySize','Original Android hero','not implemented']:
    assert text in ui, text
assert 'TabView' not in ui, 'Do not restore the unrelated four-tab test UI'
assert 'WKWebView' not in ui
assert 'gains = [0.5, 0.5]' in audio, 'Preserve safer default pending an explicit product decision'
combined = audio.split('func loadAndPlay',1)[1].split('func play',1)[0]
assert combined.index('guard load(track, into: deck) else { return false }') < combined.index('play(deck)')
assert 'explicit load-and-play starts selected deck' in audio
assert 'unselected load-and-play rejected without playing old deck' in audio
print(json.dumps({'source_contract':'PASS','reference':reference['android']['source_commit'],
                  'scope':'Static source checks only; no visual, device or independent-review approval'},indent=2))
