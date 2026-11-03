# LENOX Universal Cross-Platform Development Policy v1.0

**Approved by:** Jamie, project owner · **Effective:** 31 October 2026 · **Scope:** iOS, Android, and shared LENOX product features.

**Authority:** This policy supplements existing approved rules. It does not change contributor ownership, credit, branch protections, access permissions, paid-service permissions, release approval, or merge authority. If a requirement conflicts with an earlier approved arrangement, escalate it to Jamie; never silently replace it.

## Rules

1. **One product, two implementations.** Both platforms implement the same approved user-facing requirements where technically and legally feasible. Document material exceptions.
2. **Stable feature IDs.** Reuse an existing GitHub/Linear issue identifier. Each feature must specify purpose, acceptance criteria, design, inputs/outputs, storage, security, dependencies, implementation evidence, and limitations on each platform.
3. **Mandatory two-way handovers.** iOS-to-Android and Android-to-iOS changes must use the [feature handover template](FEATURE_HANDOVER_TEMPLATE.md). A locally implemented feature is not handover-complete until its continuation notes and tests are accessible.
4. **Independent development.** Neither team waits unnecessarily for the other. Each platform has separate code, builds, CI results, device evidence and release approvals.
5. **Truthful parity.** Do not equate feature proposals, mockups, PRs, compiled packages, test reports or physical-device acceptance. Each platform must independently pass applicable acceptance criteria before parity is claimed.
6. **Portable contracts and fixtures.** Version shared behaviour, data schemas, sample cases and expected outputs. Share portable logic where justified; do not assume Swift and Android source are interchangeable.
7. **Approved design fidelity.** Follow owner-approved Figma/asset references, preserve original art and credit, and document justified platform-specific accessibility/navigation differences.
8. **Data safety and least privilege.** Preserve music, playlists, USB and original files. Prefer read-only operations and synthetic tests. Handle iOS security-scoped access and Android SAF according to their respective rules. Never expose secrets.
9. **One accountable lead.** Inspect existing issues, PRs and decisions before starting work. Reuse related tasks; no unilateral ownership transfer or duplicate assignments. Contributors may collaborate voluntarily.
10. **Independent review and protected integration.** Use isolated branches/PRs, applicable tests, exact-commit CI and QA/security evidence, and existing protected-branch rules. No bypassing checks, merges, signing, paid builds or deployment without required approvals.
11. **Durable development knowledge.** Store architecture, algorithms, relevant files, dependencies, test instructions, results, bugs and attempted fixes with links in shared records, not just private chats.
12. **Continuously tracked parity.** Maintain an evidence-backed [feature parity register](FEATURE_PARITY.md). Record iOS and Android implementation state separately, named lead, exact SHA and blockers. Never infer status from the counterpart.
13. **Cross-platform regression control.** Changes to shared behaviour, design or storage contracts require impact analysis and corresponding updates to test fixtures, handovers and both platform records.
14. **Resumable work.** Every active feature handover should state the current commit, what was verified, what was not, blockers and the next safe action. Another authorised developer should be able to resume from shared evidence.
15. **Preserve existing governance.** Existing ownership, PRs, branches, approvals, authorship and release procedures remain intact. Jamie resolves conflicts and accepts integration decisions.

## Shared workflow

1. Find the existing GitHub/Linear record and check for duplicates and dependencies.
2. Record the platform-neutral behaviour and approved UI references.
3. Develop independently in isolated branches, maintaining a cross-platform handover.
4. Test the exact implementation on its own platform. Record failures and unknowns.
5. Update the parity register and link the PR, commit, CI/device evidence and next action.
6. Seek existing independent reviews and Jamie's relevant approval before integration/release.

**States:** Proposed; Under Discussion; Research Approved; Approved for Development; In Progress; Testing; Completed; Deferred; Declined. These describe decisions and work, not automatic claims of shipment.

## Existing coordination

- [Android shared AI development contract / governance issue #52](https://github.com/gilfillanjamie2000-del/lunox-dj-automation/issues/52)
- [iOS feasibility and integration issue #62](https://github.com/gilfillanjamie2000-del/lunox-dj-automation/issues/62)
- Existing Linear LENOX tasks remain authoritative for task state, owner, dependencies and priority.
- GitHub remains authoritative for implementation, review, CI, builds and exact code provenance.
- Approved Figma references remain authoritative for design fidelity.

This document is the canonical text of policy v1.0. Android-side guidance should link here instead of creating a separately edited copy.
