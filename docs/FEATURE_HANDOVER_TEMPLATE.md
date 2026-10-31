# LENOX Cross-Platform Feature Handover

**Required for significant changes affecting shared product behaviour.** Fill in factual evidence; mark unknowns instead of guessing. Use one shared feature ID; do not create duplicate tasks.

- **Feature ID / existing Linear and GitHub links:** 
- **Feature name / purpose:**
- **Original author(s) and contributors (preserve credit):**
- **Accountable lead (existing assignment):**
- **Implementing platform / receiving platform:**
- **Approval state / relevant owner decision:**
- **Source repository / branch / exact full commit SHA / PR:**
- **Dependencies / blocked-by links:**

## 1. Expected behaviour
User scenario, success criteria, non-goals, error states and permissions.

## 2. Portable contract
Inputs, outputs, units, schema/version, state transitions, storage format, algorithms, lifecycle, edge cases and security/privacy considerations. Include example fixtures and expected results. Mark unimplemented functionality honestly.

## 3. Design and interaction
Approved Figma frames/assets, actual screenshots, controls, accessibility, navigation and platform-specific deviations. Do not replace owner-approved artwork.

## 4. Implementation details
Relevant file paths, architecture, APIs and integration points. Distinguish portable concepts from Swift/SwiftUI/AVFoundation and Android Kotlin/Java/WebView/SAF specifics.

## 5. Counterpart implementation steps
Equivalent behaviours, platform API mapping, dependencies, safe branch/PR approach, likely pitfalls, and suggested small initial task.

## 6. Independent verification
Exact commands and test data; expected vs actual outcomes; CI URL/commit; emulator/simulator vs real-device results; permission denial, backgrounding and failure scenarios. Explicitly list **NOT TESTED** items.

## 7. Recovery and outstanding work
Known bugs, reproduction, attempted remedies, risks, safe rollback, blockers and next action. Never change original music/USB contents without explicit authorisation.

## 8. Handover checklist
- [ ] Shared feature ID and ownership confirmed
- [ ] Product behaviour and design reference documented
- [ ] Inputs/outputs and test fixtures provided
- [ ] Implementation and platform differences explained
- [ ] Exact commit and real verification evidence linked
- [ ] Gaps, blockers and next action recorded
- [ ] Parity register updated with truthful per-platform status
- [ ] Independent reviews and required owner approvals obtained where applicable

**Handover state:** Draft / Ready for counterpart / Counterpart in progress / Independently verified

A feature may ship on one platform before its counterpart; this does not confer parity or release approval on the other.
