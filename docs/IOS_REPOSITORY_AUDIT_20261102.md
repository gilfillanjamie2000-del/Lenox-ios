# iOS continuation audit — 2 November 2026

## Exact baseline and dependencies

| Record | Head | Base / classification |
| --- | --- | --- |
| iOS PR #1, policy | `a0ab643ca4b93985413b4e31351d92476e0152d9` | main; required governance ancestor; requested Mike review, not merged |
| iOS PR #2, native host | `06015b88d5c3ab011229acef6295081037039dfa` | policy branch; native audio/build foundation; draft |
| iOS PR #3, Android alignment | `5922983fc6059ba798724eb9061b277b44b8ecfc` | native-host branch; native reference UI plus artwork importer; draft |
| iOS PR #4, persistence | `1af6c6ccc1f3716b5a74579323b11f0f033f64bf` | alignment branch; persistent metadata/bookmarks and backups; draft |
| Last compiled application | `f57009b840f96103a17265018d0e5cf692670a45` | PR #4 ancestor; current PR #4 differs only in README, parity register and two build receipts |

`main` is documentation-only despite its README describing the application work. Do not start app development from it. All four open iOS PRs were inspected, including PR #4 discussion and successful historical build/artifact records. Existing iOS feature branches and their ancestry were inspected locally. There were no accessible open iOS issues in the initial combined issue query. No existing iOS PR is merged or displaced by this stacked continuation.

## Android coordination and overlap

The initial combined inventory returned 93 open PRs (4 iOS plus 89 Android) and 39 open issues. A fresh direct Android metadata inventory subsequently returned 90 open PRs, including newly opened #162. These are timestamped inventories, not fixed project totals or blanket code approvals. All current Android PR base/head refs, exact SHAs, authors and assignees were retained in the local audit deliverable. Individual source review was focused on relevant design, asset and integration evidence; no claim is made that every draft's source has passed QA.

- **Active P0 Android path:** #108 → #107 → #138 → cumulative #161 at `ac637094d693db4139fbadd8da26192817439766`. Draft and not accepted as a working A36 build at audit. #157/#159 are recorded as consolidated ancestors in issue #160, not extra changes to replay.
- **Picker overlap:** #152 overlaps the cumulative P0 fixes but retains an independent local-build helper, according to the existing triage record. Do not close or cherry-pick it blindly.
- **Advanced audio:** #150 consolidates PCM/analysis/waveforms; #139–#142 are overlapping/diverged research contracts, while recording/mix-bus proposals #128–#132 and crossfade #129 are separate. None supplies accepted iOS DSP.
- **Independent/deferred:** #155 Room/Set Builder, #153 Android agent skills, #135 isolated mixer, and older V3/Firebase/CI branches. They are not dependencies to import into this iOS slice.
- **Intro:** #116 pins `c20276ac…`; new #162 is a draft lifecycle/provenance repair stacked on it, with no media changes. iOS implements its own native pause/mute/finish and checksum checks. Android lifecycle code is not copied.
- **Design authority:** #51, #117, #118 and selected reference #119; outstanding original-design acceptance #28 remains. The verified V4 JPEG is a composition reference, not a functional backdrop. The iOS home/intro use the exact authorised binaries.

Existing issue #160 remains the Android consolidation record. Existing #62 and LEN-7/LEN-8/LEN-14 identify coordination; no new Android issue, assignment, PR, source change or build dispatch was created. Accessible Linear searches for iOS, playlists and mixer returned no matching issues, so full Linear ownership visibility is not claimed.

## Ownership and publication

Jamie retains final integration authority. Mike is the iOS collaborator; previous authorship and contributor proposals remain. The new branch is an improvement stacked on PR #4, not another competing baseline. It may be reviewed independently without editing predecessor branches.

Repository metadata confirmed iOS is public and Android is private. Only the original hero PNG and approved MP4 are authorised for public publication by Jamie's explicit answer reported in this chat. The local Android APK, HTML, reference JPEG and legacy splash are not included in the public candidate. No Firebase configuration, credentials, user music or private Android implementation is copied.

## Evidence boundaries

The original baseline artifact 13050277454 was downloaded and its outer SHA-256 `662cabcc628b7ebb3eca46d1e1bac0de897bd7bdd8a58905f5000a737e6d5c1f`, ZIP integrity and 26 manifest entries were independently checked. This is archive verification, not a fresh native execution.

Fresh ARM-runner attempt 2 of 41221542950 could not acquire a runner. Standard macOS 15 Intel wrapper run 41512471689 passed 60/43 portable assertions and stopped at the source guard; the wrapper was corrected without changing baseline application source. Run 41512834080 reproduces the full exact `f57009b…` baseline. Candidate source/local/static, compiled-device, Simulator, actual-device, independent-QA and owner-approval evidence must remain separately labelled in the build receipts.
