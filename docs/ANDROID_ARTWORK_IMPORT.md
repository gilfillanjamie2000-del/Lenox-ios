# Original Android artwork: reproducible iOS staging

**Status (31 October 2026): exact images extracted and locally verified; native UI/resource integration and an artwork-inclusive IPA remain pending.** The earlier alignment build at `cdc101ac7e6b7c9f5826b21e394760798295617f` has now succeeded; see its [cloud receipt](builds/2026-10-31-cdc101ac7e6b-cloud.json). That build does not include these original images.

Mike requested reuse of the Android assets rather than replacement graphics. The existing Android source and its artwork provenance are the reference. This step does not constitute Jamie's final visual acceptance or permission to republish unrelated private source, service configuration, music, or credentials.

## Pinned originals

Repository: `gilfillanjamie2000-del/lunox-dj-automation`.
Commit: `54f01bb213a5d30eaba99ea1f16f1d547b1d82ed`.
Provenance: `docs/design/owner-art-provenance.json` at that commit.

| Resource | Source element | Original bytes | Image dimensions | SHA-256 |
| --- | --- | --- | --- | --- |
| `lenox-android-hero.png` | `app/index.html`, `img.owner-hero-art` | 389384 | 553 x 436 | `4a09a937f442b1d246b0f352f40f9e0bc4036ef37bb8d3d1ad4aeb0784564221` |
| `lenox-android-splash.jpg` | `app/splash.html`, `img#sourceArtwork` | 372199 | 941 x 1672 | `a14623a9801b5c342cea642cf461bfe6c61e13895e26379a25a3476554a11db5` |

The hero is Android's existing lossless crop from the owner's reference. The splash is Android's existing spelling-corrected LENOX image, not the older misspelled version. No new image generation, repainting, resizing, recompression or recolouring was performed.

The retained V3 APK was read locally, not installed or executed. Its SHA-256 was `5e38c70b1d0a8f275d622659e02cf52cb4e7a35a3562df10eb37a7e6fd04cda0`. Both embedded HTML Git blob hashes matched the pinned repository files; the decoded image hashes then matched Android's provenance independently.

## Import without publishing Android HTML

From this iOS checkout, supply an authorised local copy of the pinned Android APK:

```bash
python3 scripts/import_android_artwork.py --apk /path/to/Lenox-V3-Test-54f01bb213a5-debug.apk
python3 scripts/import_android_artwork.py --verify-dir ios/LENOX/AndroidArtwork
```

Alternatively, use an authorised local Android checkout containing the exact pinned HTML:

```bash
python3 scripts/import_android_artwork.py --android-dir /path/to/lunox-dj-automation
```

These paths are command-line inputs, not included files or downloaded credentials. The importer creates only `ios/LENOX/AndroidArtwork/lenox-android-hero.png`, `lenox-android-splash.jpg` and `android-artwork-provenance.json`. It makes no network requests and copies neither HTML nor Android executable code. Unchanged existing imports are verified; conflicting, incomplete or symlinked output is rejected. Do not run concurrently with another editor. A process interruption may leave an incomplete new directory; preserve it for diagnosis and import into a new explicit output directory rather than force-overwriting it.

**The two binary images are in the separately delivered verified asset ZIP, not committed to this branch by this step.** The repository gains the importer, tests and this handover. Merely staging image files does not put them in an Xcode target or update a SwiftUI screen.

## Executed evidence

Local Python: **22 tests passed** (18 synthetic guard/parser cases and 4 integration tests against the exact retained APK). Four deliberately broken importer variants were detected by assertion failures, with zero test errors: omitted HTML identity check (1), omitted extracted-image identity check (1), omitted staged-image identity check (1), omitted symlink guard (2). Both images also decoded locally at their recorded dimensions.

```bash
LENOX_TEST_APK=/path/to/Lenox-V3-Test-54f01bb213a5-debug.apk python3 -m unittest discover -s Tests -p 'test_android_artwork.py' -v
```

Without `LENOX_TEST_APK`, the four real-APK integration tests are explicitly skipped. A skipped test is not a pass. The new Python test uses the existing `Tests` directory, avoiding a competing lowercase directory on case-insensitive Macs. These are importer tests, not SwiftUI compilation, screenshot parity, physical-device tests or independent approval.

## Remaining native integration gates

Use these exact resources in the existing native alignment work, not a second design. Extend `scripts/generate_project.py` to put the artwork folder into the target's Copy Bundle Resources phase, preserving image bytes. Replace the textual home-artwork panel with the original hero and retain the real Tap to Mix action. Use the original splash image with the Android reference's crop; implement or explicitly disclose any motion differences rather than inventing replacement rings. Do not treat a static splash as source-pixel animation parity.

Verify both resource hashes inside the built device `.app`/IPA, run existing mixer/lifecycle tests, capture matched states and obtain independent review and Jamie's acceptance. Neither previously compiled IPA contains this future wiring. No source audio, Android branch, signing configuration, permissions or merge settings were modified by the import work.

Continue in existing iOS PR #3 and Android #94; do not create duplicate feature ownership. Update this receipt and the parity register only when resource integration and build evidence actually exist.
