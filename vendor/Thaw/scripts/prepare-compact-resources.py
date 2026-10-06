#!/usr/bin/env python3
"""Prune built copies before signing; keep original catalogs and licenses."""
from pathlib import Path
import argparse
import plistlib
import shutil
import subprocess
import tempfile


def validate_resources(resources):
    resources = Path(resources)
    if resources.is_symlink() or resources.name != 'Resources' or resources.parent.name != 'Contents':
        raise ValueError('Expected a built application Contents/Resources directory')
    app = resources.parent.parent
    if app.suffix != '.app' or not resources.is_dir():
        raise ValueError('Expected an existing built application')
    info = plistlib.loads((resources.parent / 'Info.plist').read_bytes())
    if info.get('CFBundleIdentifier') != 'local.miao.traybox':
        raise ValueError('Only the MiaoShou build may be pruned')
    return app


def prune_localizations(resources):
    validate_resources(resources)
    removed = []
    for path in Path(resources).glob('*.lproj'):
        if path.stem.split('-')[0] in ('Base', 'en', 'zh'):
            continue
        if path.is_symlink():
            raise ValueError('Refusing a symbolic link in built resources')
        shutil.rmtree(path)
        removed.append(path.name)
    return removed


def prepare(resources):
    app = validate_resources(resources)
    binary = app / 'Contents/MacOS/TrayBox'
    linked = subprocess.check_output(['otool', '-L', str(binary)], text=True)
    if 'Sparkle.framework/' in linked:
        raise ValueError('Updater remains linked; refusing to create an incomplete app')
    # Xcode can leave an obsolete framework in an incremental product.
    framework = app / 'Contents/Frameworks/Sparkle.framework'
    if framework.is_symlink():
        raise ValueError('Refusing a symbolic link in built frameworks')
    if framework.exists():
        shutil.rmtree(framework)
    removed = prune_localizations(resources)
    print('Compact resources: kept Chinese/English; removed', len(removed), 'unused locales')


def self_test():
    with tempfile.TemporaryDirectory() as temp:
        app = Path(temp) / 'Test.app'
        resources = app / 'Contents/Resources'
        resources.mkdir(parents=True)
        plist = resources.parent / 'Info.plist'
        plist.write_bytes(plistlib.dumps({'CFBundleIdentifier': 'local.miao.traybox'}))
        for locale in ['Base', 'en', 'zh-Hans', 'zh-Hant', 'fr', 'de']:
            (resources / (locale + '.lproj')).mkdir()
        (resources / 'LICENSE.txt').write_text('Preserved license')
        assert set(prune_localizations(resources)) == {'fr.lproj', 'de.lproj'}
        assert (resources / 'zh-Hant.lproj').exists() and (resources / 'en.lproj').exists()
        assert (resources / 'LICENSE.txt').read_text() == 'Preserved license'
        plist.write_bytes(plistlib.dumps({'CFBundleIdentifier': 'unrelated.app'}))
        try:
            prune_localizations(resources)
        except ValueError:
            pass
        else:
            raise AssertionError('Unrelated application accepted')
        try:
            prune_localizations(Path(temp))
        except ValueError:
            pass
        else:
            raise AssertionError('Non-product directory accepted')
    print('Resource checks passed, including unrelated app and directory rejection')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('resources', nargs='?')
    parser.add_argument('--self-test', action='store_true')
    args = parser.parse_args()
    if args.self_test:
        self_test()
    if args.resources:
        prepare(args.resources)
