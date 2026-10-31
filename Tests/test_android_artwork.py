"""Importer tests: synthetic parser/guard cases plus optional pinned-APK integration.
Run: LENOX_TEST_APK=/path/to/reference.apk python3 -m unittest discover -s Tests -p 'test_android_artwork.py' -v
Without that explicitly supplied file the four pinned-APK tests are skipped.
"""
import base64
import contextlib
import hashlib
import importlib.util
import io
import os
from pathlib import Path
import tempfile
import unittest
import zipfile

MODULE = Path(__file__).resolve().parents[1] / 'scripts/import_android_artwork.py'
spec = importlib.util.spec_from_file_location('artwork', MODULE)
art = importlib.util.module_from_spec(spec)
spec.loader.exec_module(art)


def synthetic(html=None, image=b'synthetic-image'):
    if html is None:
        html = b'<img class="owner-hero-art" src="data:image/png;base64,' + base64.b64encode(image) + b'">'
    record = dict(art.SPECS[0])
    record.update(blob=art.git_blob(html), html_bytes=len(html), bytes=len(image), sha256=hashlib.sha256(image).hexdigest())
    return html, record, image


class GuardTests(unittest.TestCase):
    def test_pinned_reference_is_full_sha(self):
        self.assertRegex(art.ANDROID_SHA, r'^[0-9a-f]{40}$')
        self.assertEqual(len(art.SPECS), 2)

    def test_identified_image_extracted(self):
        html, record, image = synthetic()
        self.assertEqual(art.extract_image(html, record), image)

    def test_html_drift_rejected(self):
        html, record, _ = synthetic()
        with self.assertRaises(art.ArtworkError):
            art.extract_image(html.replace(b'<img', b'<IMG'), record)

    def test_duplicate_selected_images_rejected(self):
        html, _, _ = synthetic()
        html, record, _ = synthetic(html=html + html)
        with self.assertRaises(art.ArtworkError):
            art.extract_image(html, record)

    def test_duplicate_attributes_rejected(self):
        html, _, _ = synthetic()
        html, record, _ = synthetic(html=html.replace(b'<img ', b'<img id="a" id="b" '))
        with self.assertRaises(art.ArtworkError):
            art.extract_image(html, record)

    def test_external_url_rejected(self):
        html, record, _ = synthetic(b'<img class="owner-hero-art" src="https://invalid.example/image.png">')
        with self.assertRaises(art.ArtworkError):
            art.extract_image(html, record)

    def test_invalid_base64_rejected(self):
        html, record, _ = synthetic(b'<img class="owner-hero-art" src="data:image/png;base64,!">')
        with self.assertRaises(art.ArtworkError):
            art.extract_image(html, record)

    def test_wrong_image_hash_rejected(self):
        html, record, _ = synthetic()
        record['sha256'] = '0' * 64
        with self.assertRaises(art.ArtworkError):
            art.extract_image(html, record)

    def test_wrong_mime_rejected(self):
        html, _, _ = synthetic()
        html, record, _ = synthetic(html.replace(b'image/png', b'image/jpeg'))
        with self.assertRaises(art.ArtworkError):
            art.extract_image(html, record)

    def test_missing_image_rejected(self):
        html, record, _ = synthetic(b'<p>No image</p>')
        with self.assertRaises(art.ArtworkError):
            art.extract_image(html, record)

    def test_unverified_images_cannot_create_output(self):
        with tempfile.TemporaryDirectory() as tmp:
            dest = Path(tmp) / 'art'
            with self.assertRaises(art.ArtworkError):
                art.stage({}, dest)
            self.assertFalse(dest.exists())

    def test_incomplete_directory_not_overwritten(self):
        with tempfile.TemporaryDirectory() as tmp:
            dest = Path(tmp)
            p = dest / art.SPECS[0]['file']
            p.write_bytes(b'do-not-overwrite')
            with self.assertRaises(art.ArtworkError):
                art.verify_destination(dest)
            self.assertEqual(p.read_bytes(), b'do-not-overwrite')

    def test_symlinked_input_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp)
            (p / 'real').write_bytes(b'x')
            (p / 'link').symlink_to(p / 'real')
            with self.assertRaises(art.ArtworkError):
                art.bounded_file(p / 'link', 10)

    def test_symlinked_parent_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp)
            (p / 'real').mkdir()
            (p / 'link').symlink_to(p / 'real', target_is_directory=True)
            with self.assertRaises(art.ArtworkError):
                art.no_symlinks(p / 'link' / 'child')

    def test_oversized_read_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp) / 'large'
            p.write_bytes(b'12345')
            with self.assertRaises(art.ArtworkError):
                art.bounded_file(p, 4)

    def test_missing_apk_members_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp) / 'wrong.apk'
            with zipfile.ZipFile(p, 'w') as archive:
                archive.writestr('different.txt', b'x')
            with self.assertRaises(art.ArtworkError):
                art.read_apk(p)

    def test_duplicate_apk_member_rejected(self):
        import warnings
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp) / 'duplicate.apk'
            with warnings.catch_warnings():
                warnings.simplefilter('ignore', UserWarning)
                with zipfile.ZipFile(p, 'w') as archive:
                    archive.writestr(art.SPECS[0]['apk_path'], b'x')
                    archive.writestr(art.SPECS[0]['apk_path'], b'x')
            with self.assertRaises(art.ArtworkError):
                art.read_apk(p)

    def test_cli_failure_is_nonzero(self):
        with tempfile.TemporaryDirectory() as tmp, contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(art.main(['--verify-dir', tmp]), 1)


APK = os.environ.get('LENOX_TEST_APK')
@unittest.skipUnless(APK, 'Set LENOX_TEST_APK to run actual pinned-artwork integration')
class PinnedAPKTests(unittest.TestCase):
    def test_exact_source_and_artwork(self):
        images = art.read_apk(Path(APK))
        for record in art.SPECS:
            self.assertEqual(hashlib.sha256(images[record['file']]).hexdigest(), record['sha256'])

    def test_stage_and_idempotent_verify(self):
        with tempfile.TemporaryDirectory() as tmp:
            dest = Path(tmp) / 'art'
            images = art.read_apk(Path(APK))
            first = art.stage(images, dest)
            before = {p.name: p.read_bytes() for p in dest.iterdir()}
            self.assertEqual(first, art.stage(images, dest))
            self.assertEqual(before, {p.name: p.read_bytes() for p in dest.iterdir()})
            self.assertEqual(len(before), 3)
            self.assertFalse(first['native_ui_wiring_verified'])

    def test_mutated_output_refused_and_preserved(self):
        with tempfile.TemporaryDirectory() as tmp:
            dest = Path(tmp) / 'art'
            images = art.read_apk(Path(APK))
            art.stage(images, dest)
            p = dest / art.SPECS[0]['file']
            changed = b'x' + p.read_bytes()[1:]
            p.write_bytes(changed)
            with self.assertRaises(art.ArtworkError):
                art.stage(images, dest)
            self.assertEqual(p.read_bytes(), changed)

    def test_android_directory_and_apk_are_identical(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            with zipfile.ZipFile(APK) as archive:
                for record in art.SPECS:
                    p = root / record['source']
                    p.parent.mkdir(parents=True, exist_ok=True)
                    p.write_bytes(archive.read(record['apk_path']))
            dest = root / 'out'
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(art.main(['--android-dir', str(root), '--output', str(dest)]), 0)
            self.assertTrue(art.verify_destination(dest)['ok'])


if __name__ == '__main__':
    unittest.main()
