# Android-reference alignment — native iOS continuation

**Status: In Progress, NOT parity-approved.** Request classification: IMPROVEMENT to iOS PR #2 / existing iOS feasibility work, RELATED to Android PR #94 and design acceptance #28. Mike continues iOS implementation; no Android ownership changes. Jamie's message supplied by Mike requests equivalent native components and shared designs, not a new visual direction. This records that direction; it is not a claim of a new independent approval.

## Authoritative reference

Android repository `gilfillanjamie2000-del/lunox-dj-automation`, branch `feature/v3-deck-aware-mix-20261031`, exact source `54f01bb213a5d30eaba99ea1f16f1d547b1d82ed`. Canonical UI is `app/index.html`, Git blob `5504651b59f9af4d6419e45c1045c2899363fb64`. The retained APK's `assets/index.html` bytes match that blob. At this commit `android/app/src/main/assets/index.html` is not tracked; Android CI stages it from `app/index.html`. Do not independently edit two supposed source-of-truth copies.

The accompanying [machine-readable reference](parity/android-reference.json) pins the revision, colours, dock, control ranges and known differences. Android PR #94 is draft; [design issue #28](https://github.com/gilfillanjamie2000-del/lunox-dj-automation/issues/28) remains open. The pinned branch is an implementation reference, not proof of final visual approval. Approved owner/Figma references continue to govern unresolved differences.

## Implemented in this slice

Native SwiftUI uses the reference navy/purple panels, cyan accents, main feature labels and Home/Library/Playlists/Mix dock instead of the unrelated original four-tab test interface. Home's Tap to Mix opens Mix Assistant; dock Mix opens the native mixer. Two decks sit alongside each other when space allows, with accessible stacked reflow. Transport labels are Load & play, Stop, Pause and Resume; gain/channel/crossfader range is 0–100%, tempo 50–200% in 1% steps. Title search is real, case/diacritic-insensitive, over selected session tracks.

`AudioModel.load` now returns success. The combined explicit `loadAndPlay` first requires a successful authorised load; a failed load cannot start an old deck. Existing standalone load still does not autoplay. Existing source-file read-only access, lifecycle gate and quieter initial gain are preserved. The original 41 policy assertions are retained; 43 further Swift assertions cover routes, filtering, formatting and fixed crossfade vectors. Two additional Simulator audio checks cover explicit combined playback and rejection of an unselected track. Native compilation and screenshots must be reported from the exact new CI run, never inherited from PR #2's earlier build.

Unavailable capabilities have truthful explanations, not invented recommendations, scores, demo track counts or enabled no-op buttons. A matching page title is not a matching feature implementation.

## Remaining parity blockers

| Area | Required work before parity can pass |
| --- | --- |
| Original assets | Approve redistribution into the public iOS repository or an authorised protected asset workflow. Android is private; this patch publishes neither its artwork nor implementation. No imitation neon art is substituted. |
| Home / splash | Integrate approved hero/splash, motion/reduced-motion behaviour, featured carousel and full studio tools. The current textual Tap to Mix panel is visibly different and not final approval. |
| Navigation | Port the full reference route sequence, Previous/Next/focus restoration and appropriate iOS Back behaviour. The separate iOS mixer route currently differs from Android's home-section scrolling. |
| Library | Replace or extend 20-file session selection with reviewed persistent library behaviour, metadata, revocation/restart handling and bounded indexing. Preserve source music. |
| Playlists / occasions | Implement editing, collision protection, ordering, availability, persistence/backup and reviewed metadata filters. These pages currently report unavailability. |
| Mix Assistant | Port the versioned reviewed-metadata engine and its fixtures, source-selection invalidation, explanations, consent and opposite-deck action. Current iOS page is not a recommender. |
| Mixer | Review the safer 50% initial iOS gain versus Android's 100%; never silently increase startup loudness. Test transport, rate, seek and simultaneous audible output on both devices. Waveform capture and Android single-track mini-player have no iOS equivalent yet. |
| Advanced audio | Do not infer true beat sync, automatic audio analysis, EQ or scratching from labels or decorative displays. Verify reference capabilities separately. |
| Accessibility | Keep large text, screen-reader labels, safe areas and native system prompts usable. Document necessary platform differences rather than faking an Android OS dialog. |
| Approval | Independent exact-revision technical/security review, paired device evidence and Jamie's explicit acceptance. |

## Parity gate

A feature may be called visually and functionally equivalent only after ALL applicable evidence is linked: both source SHAs; matching fixture version and initial state; device/OS/build identities; screenshots for normal, empty, loading, error and denied-permission states; same visible labels and actions; navigation outcomes; persisted data outcomes; audio measurements/listening checks where relevant; and an independent review. Compare app-controlled content at matched content viewport, text size, theme and state. Mask only documented OS chrome. No fabricated global pixel threshold or auto-approved screenshot tolerance: Jamie/design review must agree acceptance criteria. A required deviation remains a blocker until approved.

Apple file pickers, system permission prompts, status bars and safe areas need not imitate Android. This exception does not excuse different LENOX navigation or missing features. Simulator screenshots are evidence of rendering only, not real-phone acceptance, audio quality or complete interaction testing.

## Resume here

1. Read this file and the pinned JSON; compare with the live Android branch before updating the reference.
2. Run the original policy suite, new alignment suite and source checks. On a reviewed macOS checkout run `bash scripts/ci-alignment.sh` for separate device/Simulator compilation, 12 synthetic audio checks and seven route captures.
3. Inspect every capture. Test VoiceOver, large text, landscape, actual Files selection and repeated load/play/stop on physical devices after authorised signing.
4. Prefer completing a missing existing feature over further cosmetic redesign. Link the implementation and tests to the existing shared task; maintain original credit.
5. Keep the parity flags false until evidence and review support promotion. A green cloud build alone cannot change them.

No merge, signing, deployment, paid runner, Android change or original-music mutation is authorised by this document. Linear searches for iOS and mixer returned no matching accessible records in this session; that is not proof the shared workspace has no relevant tasks. Existing assignments remain untouched.
