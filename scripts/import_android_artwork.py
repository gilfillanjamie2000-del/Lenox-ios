#!/usr/bin/env python3
"""Import ONLY the two pinned LENOX Android images; never execute/copy HTML.

Usage:
  python3 scripts/import_android_artwork.py --apk /path/to/Lenox-V3-Test-54f01bb213a5-debug.apk
  python3 scripts/import_android_artwork.py --android-dir /path/to/android-repository
  python3 scripts/import_android_artwork.py --verify-dir ios/LENOX/AndroidArtwork

No network, dependencies, source-audio access, signing, or Xcode project edits.
Run in a trusted, non-concurrently edited checkout. Incomplete destinations
are rejected, not silently repaired or overwritten. The manifest is written last.
"""
from __future__ import annotations

import argparse
import base64
import binascii
import hashlib
from html.parser import HTMLParser
import json
import os
from pathlib import Path
import sys
import zipfile

ANDROID_SHA = "54f01bb213a5d30eaba99ea1f16f1d547b1d82ed"
MAX_HTML = 2 * 1024 * 1024
SPECS = (
    {"source": "app/index.html", "apk_path": "assets/index.html",
     "blob": "5504651b59f9af4d6419e45c1045c2899363fb64", "html_bytes": 627903,
     "attribute": "class", "value": "owner-hero-art", "mime": "image/png",
     "file": "lenox-android-hero.png", "bytes": 389384, "width": 553, "height": 436,
     "sha256": "4a09a937f442b1d246b0f352f40f9e0bc4036ef37bb8d3d1ad4aeb0784564221"},
    {"source": "app/splash.html", "apk_path": "assets/splash.html",
     "blob": "b21bf95ee62be3ab3c2f016816c02d8c93586962", "html_bytes": 503530,
     "attribute": "id", "value": "sourceArtwork", "mime": "image/jpeg",
     "file": "lenox-android-splash.jpg", "bytes": 372199, "width": 941, "height": 1672,
     "sha256": "a14623a9801b5c342cea642cf461bfe6c61e13895e26379a25a3476554a11db5"},
)
MANIFEST_NAME = "android-artwork-provenance.json"


class ArtworkError(ValueError):
    """The requested source or destination failed a required integrity gate."""


def git_blob(data: bytes) -> str:
    return hashlib.sha1(b"blob " + str(len(data)).encode("ascii") + b"\0" + data).hexdigest()


class ImageFinder(HTMLParser):
    def __init__(self, attribute: str, value: str):
        super().__init__(convert_charrefs=True)
        self.attribute, self.value, self.matches = attribute, value, []

    def handle_starttag(self, tag, attrs):
        if tag.lower() != "img":
            return
        values = dict(attrs)
        actual = values.get(self.attribute) or ""
        matches = self.value in actual.split() if self.attribute == "class" else actual == self.value
        if matches:
            if len(attrs) != len(values):
                raise ArtworkError("Duplicate HTML image attributes")
            self.matches.append(values.get("src") or "")


def extract_image(data: bytes, spec: dict) -> bytes:
    if len(data) != spec["html_bytes"] or len(data) > MAX_HTML or git_blob(data) != spec["blob"]:
        raise ArtworkError("HTML is not the pinned Android source: " + spec["source"])
    finder = ImageFinder(spec["attribute"], spec["value"])
    finder.feed(data.decode("utf-8", errors="strict"))
    finder.close()
    if len(finder.matches) != 1:
        raise ArtworkError("Expected exactly one identified image")
    prefix = "data:" + spec["mime"] + ";base64,"
    uri = finder.matches[0]
    if not uri.startswith(prefix):
        raise ArtworkError("Unexpected image type or external image URL")
    try:
        image = base64.b64decode(uri[len(prefix):], validate=True)
    except (ValueError, binascii.Error) as exc:
        raise ArtworkError("Invalid image encoding") from exc
    if len(image) != spec["bytes"] or hashlib.sha256(image).hexdigest() != spec["sha256"]:
        raise ArtworkError("Image identity mismatch: " + spec["file"])
    return image


def no_symlinks(path: Path) -> None:
    for part in (path, *path.parents):
        if part.is_symlink():
            raise ArtworkError("Refusing a symlink path")


def bounded_file(path: Path, limit: int) -> bytes:
    no_symlinks(path)
    if not path.is_file() or path.stat().st_size > limit:
        raise ArtworkError("Missing, non-regular or oversized input")
    with path.open("rb") as stream:
        data = stream.read(limit + 1)
    if len(data) > limit:
        raise ArtworkError("Input exceeded size limit")
    return data


def read_apk(path: Path) -> dict[str, bytes]:
    no_symlinks(path)
    if not path.is_file() or path.stat().st_size > 64 * 1024 * 1024:
        raise ArtworkError("Expected a regular APK no larger than 64 MiB")
    result = {}
    with zipfile.ZipFile(path) as archive:
        for spec in SPECS:
            candidates = [i for i in archive.infolist() if i.filename == spec["apk_path"]]
            if len(candidates) != 1:
                raise ArtworkError("Missing or duplicate selected APK member")
            item = candidates[0]
            mode = (item.external_attr >> 16) & 0o170000
            if item.is_dir() or mode == 0o120000 or item.file_size != spec["html_bytes"]:
                raise ArtworkError("Unsafe or wrong-sized selected APK member")
            with archive.open(item) as stream:
                data = stream.read(MAX_HTML + 1)
            result[spec["file"]] = extract_image(data, spec)
    return result


def manifest_bytes() -> bytes:
    manifest = {
        "schema_version": 1,
        "source_repository": "gilfillanjamie2000-del/lunox-dj-automation",
        "source_commit": ANDROID_SHA,
        "artwork_modifications_by_this_import": "None; decoded bytes retained exactly",
        "hero_provenance": "Existing lossless crop of owner dashboard reference",
        "splash_provenance": "Existing Android LENOX spelling-corrected JPEG; no new edit",
        "native_ui_wiring": "Not performed by this importer",
        "visual_parity_approved": False,
        "functional_parity_verified": False,
        "assets": list(SPECS),
    }
    return (json.dumps(manifest, indent=2, sort_keys=True) + "\n").encode("utf-8")


def verify_destination(destination: Path) -> dict:
    no_symlinks(destination)
    expected_names = {s["file"] for s in SPECS} | {MANIFEST_NAME}
    if not destination.is_dir() or {p.name for p in destination.iterdir()} != expected_names:
        raise ArtworkError("Destination is incomplete or contains unexpected files")
    for spec in SPECS:
        data = bounded_file(destination / spec["file"], spec["bytes"])
        if len(data) != spec["bytes"] or hashlib.sha256(data).hexdigest() != spec["sha256"]:
            raise ArtworkError("Staged artwork mismatch: " + spec["file"])
    if bounded_file(destination / MANIFEST_NAME, 65536) != manifest_bytes():
        raise ArtworkError("Manifest does not match this pinned import")
    return {"ok": True, "source_commit": ANDROID_SHA,
            "verified_images": len(SPECS), "native_ui_wiring_verified": False,
            "visual_parity_verified": False, "functional_parity_verified": False}


def stage(images: dict[str, bytes], destination: Path) -> dict:
    # Validate everything before creating output. Existing mismatches are never overwritten.
    for spec in SPECS:
        data = images.get(spec["file"], b"")
        if len(data) != spec["bytes"] or hashlib.sha256(data).hexdigest() != spec["sha256"]:
            raise ArtworkError("Refusing to stage unverified image bytes")
    no_symlinks(destination)
    if destination.exists():
        return verify_destination(destination)
    destination.parent.mkdir(parents=True, exist_ok=True)
    no_symlinks(destination.parent)
    destination.mkdir(exist_ok=False)
    for name, data in [(s["file"], images[s["file"]]) for s in SPECS] + [(MANIFEST_NAME, manifest_bytes())]:
        with (destination / name).open("xb") as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
    return verify_destination(destination)


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--apk", type=Path)
    source.add_argument("--android-dir", type=Path)
    source.add_argument("--verify-dir", type=Path)
    parser.add_argument("--output", type=Path, default=Path("ios/LENOX/AndroidArtwork"))
    args = parser.parse_args(argv)
    try:
        if args.verify_dir is not None:
            report = verify_destination(args.verify_dir.absolute())
        else:
            images = read_apk(args.apk.absolute()) if args.apk is not None else {
                spec["file"]: extract_image(bounded_file(args.android_dir.absolute() / spec["source"], MAX_HTML), spec)
                for spec in SPECS
            }
            report = stage(images, args.output.absolute())
        print(json.dumps(report, sort_keys=True))
        return 0
    except (ArtworkError, OSError, UnicodeError, zipfile.BadZipFile, RuntimeError) as exc:
        print("Artwork import failed: " + str(exc), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
