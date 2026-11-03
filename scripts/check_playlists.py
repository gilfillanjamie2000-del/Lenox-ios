#!/usr/bin/env python3
"""Supplementary source assertions; runtime tests remain mandatory."""
from pathlib import Path
import json
r=Path(__file__).resolve().parents[1]
a=(r/'ios/LENOX/AudioModel.swift').read_text()
s=(r/'ios/LENOX/PlaylistStore.swift').read_text()
u=(r/'ios/LENOX/PlaylistViews.swift').read_text()
assert 'candidate.revision += 1' in s
assert s.index('try file.write(bytes)') < s.index('diskBytes = bytes; state = candidate')
assert 'guard try file.read() == diskBytes' in s
assert 'completeFileProtection' in s and 'options: .atomic' in s
assert 'bookmarkData(options: .minimalBookmark' in a
assert 'guard !stale else' in a and 'NSFileCoordinator' in a
assert 'track.bookmark == nil' in u
assert 'fileExporter' in u and 'fileImporter' in u
assert 'defaultFilename: "LENOX-playlist.json"' in u
assert 'revision: draft.revision' in u
assert '.onDelete' in u and '.onMove' in u
assert 'selected.byteCount == saved.byteCount' in a
assert 'Read-only' in (r/'ios/LENOX/LenoxApp.swift').read_text()
for name in ['PlaylistStore.swift','PlaylistViews.swift']:
    assert name in (r/'ios/LENOX.xcodeproj/project.pbxproj').read_text()
assert 'private func runPlaylistSmokeIfRequested() {\n        #if targetEnvironment(simulator)' in a
print(json.dumps({'playlist_source_checks':'PASS','scope':'static assertions only'}))
