"""Reject stale updater artifacts and accidental unrelated-app resource pruning."""
from pathlib import Path
import importlib.util
import plistlib
import tempfile
import unittest

SCRIPT_DIR = Path(__file__).resolve().parent
ROOT = next(root for root in (SCRIPT_DIR.parent, SCRIPT_DIR.parents[2]) if (root / 'vendor/Thaw/scripts/prepare-compact-resources.py').exists())


def load_module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


PACKAGE = load_module('compact_package', SCRIPT_DIR / 'package.py')
RESOURCES = load_module('compact_resources', ROOT / 'vendor/Thaw/scripts/prepare-compact-resources.py')


class CompactPackageTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.app = Path(self.temp.name) / 'Test.app'
        self.resources = self.app / 'Contents/Resources'
        self.resources.mkdir(parents=True)
        (self.resources.parent / 'Info.plist').write_bytes(plistlib.dumps({'CFBundleIdentifier': 'local.miao.traybox'}))

    def test_linked_updater_is_rejected(self):
        with self.assertRaises(ValueError):
            PACKAGE.validate_compact_layout(self.app, '@rpath/Sparkle.framework/Versions/B/Sparkle')

    def test_stale_embedded_updater_is_rejected(self):
        (self.app / 'Contents/Frameworks/Sparkle.framework').mkdir(parents=True)
        with self.assertRaises(ValueError):
            PACKAGE.validate_compact_layout(self.app, '/usr/lib/libobjc.A.dylib')

    def test_unused_locale_is_rejected(self):
        (self.resources / 'fr.lproj').mkdir()
        with self.assertRaises(ValueError):
            PACKAGE.validate_compact_layout(self.app, '/usr/lib/libobjc.A.dylib')

    def test_pruning_preserves_languages_and_licenses(self):
        for name in ['en', 'zh-Hans', 'zh-Hant', 'Base', 'fr']:
            (self.resources / (name + '.lproj')).mkdir()
        (self.resources / 'LICENSE.txt').write_text('Preserved')
        self.assertEqual(RESOURCES.prune_localizations(self.resources), ['fr.lproj'])
        PACKAGE.validate_compact_layout(self.app, '/usr/lib/libobjc.A.dylib')
        self.assertEqual((self.resources / 'LICENSE.txt').read_text(), 'Preserved')
        self.assertTrue((self.resources / 'zh-Hant.lproj').is_dir())

    def test_unrelated_app_is_never_modified(self):
        (self.resources / 'fr.lproj').mkdir()
        (self.resources.parent / 'Info.plist').write_bytes(plistlib.dumps({'CFBundleIdentifier': 'unrelated.app'}))
        with self.assertRaises(ValueError):
            RESOURCES.prune_localizations(self.resources)
        self.assertTrue((self.resources / 'fr.lproj').is_dir())


if __name__ == '__main__':
    unittest.main()
