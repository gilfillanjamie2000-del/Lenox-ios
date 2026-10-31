# LENOX iOS ↔ Android Feature Parity Register

This register is a **link index and evidence ledger**, not a replacement for Linear task status or GitHub CI. Update it only with verified source, test and device evidence. Empty cells mean **not verified**, not missing by default.

| Feature / existing task | iOS implementation + exact SHA | Android implementation + exact SHA | iOS tests/device evidence | Android tests/device evidence | Accountable lead | Blocker / next action |
| --- | --- | --- | --- | --- | --- | --- |
| Music library / [LEN-7](https://linear.app/lenox-app/issue/LEN-7) | Not verified | See existing Android PRs and LEN-7 | Not verified | Check LEN-7 | Retain existing issue assignment | Define shared scan/metadata fixtures |
| Playlists / [LEN-8](https://linear.app/lenox-app/issue/LEN-8) | Not verified | See LEN-8 | Not verified | Check LEN-8 | Retain existing issue assignment | Document persistence contract |
| Two-deck mixer / [LEN-14](https://linear.app/lenox-app/issue/LEN-14) | Not verified | See LEN-14 | Not verified | Check LEN-14 | Retain existing issue assignment | Document transport/crossfader behaviour |
| AI recommendations / [LEN-10](https://linear.app/lenox-app/issue/LEN-10) | Not verified | See LEN-10 | Not verified | Check LEN-10 | Retain existing issue assignment | Define metadata confidence fixtures |
| Android APK evidence / [LEN-6](https://linear.app/lenox-app/issue/LEN-6) | N/A: use separate IPA evidence | See LEN-6 | Not verified | Check LEN-6 | Retain existing issue assignment | Preserve independent build gates |

**Update procedure:** For each feature, link the existing Linear issue and both implementation PRs, precise SHAs, tests and device evidence. Record explicit exceptions. Never mark 'Completed' from a screenshot, a compiled build, a draft PR or a different platform's test.

Related: [Policy v1.0](CROSS_PLATFORM_POLICY_V1.md) · [Handover template](FEATURE_HANDOVER_TEMPLATE.md).
