# LENOX source and build archive policy

This is a LENOX iOS source snapshot or build-evidence package, not a MODGPT memory export. Preserve the actual repository structure. Source archives include the exact tracked files at the named commit; no secrets, signing keys, private Android assets, user audio or fabricated implementation belong in an export.

Extract to a new directory. Never drag it over an existing checkout, app installation or user music directory. Confirm archive integrity, source commit, artifact purpose and SHA-256 before use. The UNSIGNED IPA is not directly installable on an iPhone. A Simulator app is not a device app. Source, compiled artifacts, test reports and physical-device acceptance are distinct evidence.

Recovery: retain the previous checkout and original archive unchanged. Use Git branches/commits for reversible changes; do not force-push or overwrite others' work. The authoritative build identity is build-provenance.json with the matching checksums, not this policy text or a filename alone.
