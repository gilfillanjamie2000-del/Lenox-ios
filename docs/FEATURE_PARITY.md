# LENOX iOS ↔ Android Feature Parity Register

This register is a **link index and evidence ledger**, not a replacement for Linear task status or GitHub CI. Update it only with verified source, test and device evidence. Empty cells mean **not verified**, not missing by default.

| Feature / existing task | iOS implementation + exact SHA | Android implementation + exact SHA | iOS tests/device evidence | Android tests/device evidence | Accountable lead | Blocker / next action |
| --- | --- | --- | --- | --- | --- | --- |
| Music library / [LEN-7](https://linear.app/lenox-app/issue/LEN-7) | First test slice at `a7fc11fab969f79e8f96c26dd055b7ae9860232d`: explicit session-file selection only; no full scanner/persistence | See existing Android PRs and LEN-7 | Compiled; synthetic local files decoded in Simulator. Real Files permissions/provider/revocation NOT tested | Check LEN-7 | Retain existing issue assignment; Mike's iOS contribution in PR #2 | Sign for an authorised test device; verify Files flow and define persistent contract |
| Playlists / [LEN-8](https://linear.app/lenox-app/issue/LEN-8) | Not implemented in first iOS slice | See LEN-8 | Not verified | Check LEN-8 | Retain existing issue assignment | Document persistence contract |
| Two-deck mixer / [LEN-14](https://linear.app/lenox-app/issue/LEN-14) | Native test source at `a7fc11fab969f79e8f96c26dd055b7ae9860232d`; no beat SYNC/EQ/waveforms | Behaviour reference PR #94 at `54f01bb213a5d30eaba99ea1f16f1d547b1d82ed`; retain LEN-14 integration record | 41 portable policy assertions; 10 generated-audio Simulator checks. No physical iPhone evidence or independent approval | Check LEN-14 and exact Android artifacts separately | Retain existing issue assignment; Mike's iOS contribution in PR #2 | Audible A/B device tests, real OS lifecycle/route checks, independent review |
| AI recommendations / [LEN-10](https://linear.app/lenox-app/issue/LEN-10) | Not implemented in first iOS slice | See LEN-10 | Not verified | Check LEN-10 | Retain existing issue assignment | Define metadata confidence fixtures |
| Android APK evidence / [LEN-6](https://linear.app/lenox-app/issue/LEN-6) | N/A: separate IPA evidence below | See LEN-6 | Do not inherit Android test results | Check LEN-6 | Retain existing issue assignment | Preserve independent build gates |
| First iOS test build / existing [#62](https://github.com/gilfillanjamie2000-del/lunox-dj-automation/issues/62) | [PR #2](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/2), tested source `a7fc11fab969f79e8f96c26dd055b7ae9860232d` | Android unchanged | [macOS run 41211621619](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions/runs/41211621619) SUCCESS; ARM64 unsigned IPA and separate Simulator app verified | Not applicable to this iOS build | Mike's requested iOS work; Jamie retains integration authority | Apple signing/provisioning, iPhone acceptance, independent QA/security |

**No platform parity or shipment is claimed.** These are independent test-implementation records. The native UI is a test harness, not approved Android visual parity. Source code/artwork from the private Android repo was not published here. The current Linear inventory was not verified; no assignment or issue state was changed.

[Exact build/checksum receipt](builds/2026-10-31-a7fc11fab969.json) · [Cross-platform continuation handover](IOS_FIRST_TEST_HANDOVER.md) · [Physical acceptance checklist](IOS_BUILD_AND_ACCEPTANCE.md).

**Update procedure:** For each feature, link the existing Linear issue and both implementation PRs, precise SHAs, tests and device evidence. Record explicit exceptions. Never mark 'Completed' from a screenshot, a compiled build, a draft PR or a different platform's test. Documentation-only commits after the above source SHA are not represented as new compiled app revisions.

Related: [Policy v1.0](CROSS_PLATFORM_POLICY_V1.md) · [Handover template](FEATURE_HANDOVER_TEMPLATE.md).
