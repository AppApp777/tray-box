#!/usr/bin/env python3
"""Package a Release build for manual installation, without modifying Applications.

This produces an ad-hoc-signed, unnotarized DMG, never a Developer ID release.
Run from a clean public checkout; see docs/DISTRIBUTION.md.
"""
import argparse
import hashlib
import io
import json
import plistlib
import re
import shutil
import subprocess
import tempfile
import zipfile
from pathlib import Path


def run(*args, **kwargs):
    return subprocess.run([str(a) for a in args], check=True, **kwargs)


def output(*args, **kwargs):
    return run(*args, capture_output=True, **kwargs).stdout


def validate_info(info):
    if info.get('CFBundleIdentifier') != 'local.miao.traybox':
        raise ValueError('Not a Tray Box application')
    if info.get('TrayBoxFixtureOnly'):
        raise ValueError('Refusing to distribute a fixture-only application')
    if info.get('SUEnableAutomaticChecks') or info.get('SUAutomaticallyUpdate'):
        raise ValueError('Upstream automatic updates must be disabled')
    if info.get('LSMinimumSystemVersion') != '26.0':
        raise ValueError('Review the documented system requirements first')


def archive_into(archive, repo, revision, prefix):
    data = output('git', 'archive', '--format=zip', revision, cwd=repo)
    with zipfile.ZipFile(io.BytesIO(data)) as source:
        for entry in source.infolist():
            contents = source.read(entry)
            entry.filename = prefix + entry.filename
            archive.writestr(entry, contents)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--app', required=True, type=Path)
    parser.add_argument('--packages', required=True, type=Path,
                        help='Xcode clonedSourcePackagesDirPath used for the build')
    parser.add_argument('--output', required=True, type=Path, help='New output directory')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    app_source = args.app.resolve()
    info = plistlib.loads((app_source / 'Contents/Info.plist').read_bytes())
    validate_info(info)
    if output('lipo', '-archs', app_source / 'Contents/MacOS/TrayBox').strip() != b'arm64':
        raise ValueError('This release is for Apple Silicon only')
    for binary in (app_source / 'Contents/MacOS/TrayBox',
                   app_source / 'Contents/XPCServices/MenuBarItemService.xpc/Contents/MacOS/MenuBarItemService'):
        if b'default.profraw' in binary.read_bytes():
            raise ValueError('Coverage-instrumented build; rebuild with -enableCodeCoverage NO')
    if output('git', 'status', '--porcelain', cwd=root).strip():
        raise ValueError('Commit public source and packaging changes before packaging')
    revision = output('git', 'rev-parse', 'HEAD', cwd=root).decode().strip()
    built_revision = info.get('GitCommitSHA', '')
    if not re.fullmatch(r'[0-9a-f]{7,40}', built_revision):
        raise ValueError('Build must identify a clean public source commit')
    run('git', 'diff', '--exit-code', built_revision, revision, '--', 'vendor/Thaw', cwd=root)
    pins_path = root / 'vendor/Thaw/Thaw.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved'
    pins = json.loads(pins_path.read_text())['pins']
    checkouts = {p.name.lower(): p for p in (args.packages.resolve() / 'checkouts').iterdir() if p.is_dir()}
    notices = ['Tray Box / 菜单收纳 — GNU GPLv3', (root / 'LICENSE').read_text()]
    for pin in pins:
        checkout = checkouts[pin['identity']]
        if output('git', 'rev-parse', 'HEAD', cwd=checkout).decode().strip() != pin['state']['revision']:
            raise ValueError('Dependency revision mismatch: ' + pin['identity'])
        if output('git', 'status', '--porcelain', '--untracked-files=no', cwd=checkout).strip():
            raise ValueError('Modified dependency: ' + pin['identity'])
        tracked = output('git', 'ls-files', '-z', cwd=checkout).decode().split('\0')
        licenses = [p for p in tracked if p and re.search(r'(^|_)(license|licence|copying|notice)(\.|$)', Path(p).name, re.I)]
        if not licenses:
            raise ValueError('No license found for ' + pin['identity'])
        notices.append('\n\n' + '=' * 72 + '\n' + pin['identity'] + '\n' + pin['location'] + '\n' + pin['state']['revision'])
        for rel in sorted(licenses):
            notices.append('\n--- ' + rel + ' ---\n' + (checkout / rel).read_text())

    destination = args.output.resolve()
    destination.mkdir(parents=True, exist_ok=False)
    version = info['CFBundleShortVersionString']
    stem = 'tray-box-' + version
    with tempfile.TemporaryDirectory(prefix='tray-box-package-') as temporary:
        temporary = Path(temporary)
        volume = temporary / 'volume'
        volume.mkdir()
        app = volume / '菜单收纳.app'
        run('ditto', '--norsrc', '--noextattr', app_source, app)
        # Swift object files may retain debug paths despite the Xcode setting.
        # Strip only the staged Mach-O files, before signing them.
        mach_magic = {bytes.fromhex(h) for h in ('cffaedfe', 'cefaedfe', 'feedface', 'feedfacf', 'cafebabe', 'bebafeca', 'cafebabf', 'bfbafeca')}
        for binary in app.rglob('*'):
            if binary.is_file() and not binary.is_symlink():
                with binary.open('rb') as stream:
                    is_mach = stream.read(4) in mach_magic
                if is_mach:
                    run('xcrun', 'strip', '-S', '-x', binary)
                    if b'/Users/' in binary.read_bytes() or b'/home/' in binary.read_bytes():
                        raise ValueError('Absolute home path remains in binary: ' + str(binary.relative_to(app)))
        resources = app / 'Contents/Resources'
        (resources / 'LICENSE.txt').write_text((root / 'LICENSE').read_text())
        (resources / 'THIRD_PARTY_NOTICES.txt').write_text('\n'.join(notices))
        metadata = {
            'version': version, 'build': info['CFBundleVersion'],
            'app_source_commit': built_revision, 'packaging_commit': revision,
            'source_url': 'https://github.com/AppApp777/tray-box',
            'architecture': 'arm64', 'minimum_macos': '26.0',
            'signature': 'ad-hoc', 'notarized': False,
            'configuration': 'Release', 'dependencies': pins,
        }
        (resources / 'BUILD-METADATA.json').write_text(json.dumps(metadata, indent=2) + '\n')
        # Sign nested executables first; --deep is used for verification only.
        targets = [p for p in app.rglob('*') if not p.is_symlink() and
                   (p.suffix in ('.app', '.xpc', '.framework') or p.name == 'Autoupdate')]
        targets.sort(key=lambda p: len(p.parts), reverse=True)
        targets.append(app)
        for index, target in enumerate(targets):
            entitlements = {}
            if target.suffix != '.framework':
                # Teamless signatures cannot satisfy same-team library validation.
                # Retain hardened runtime, without the development debugger grant.
                entitlements['com.apple.security.cs.disable-library-validation'] = True
            entitlements_path = temporary / ('entitlements-' + str(index) + '.plist')
            entitlements_path.write_bytes(plistlib.dumps(entitlements))
            run('codesign', '--force', '--sign', '-', '--timestamp=none', '--options', 'runtime',
                '--entitlements', entitlements_path, target)
        run('codesign', '--verify', '--deep', '--strict', app)
        for target in targets:
            signature = output('codesign', '-d', '--entitlements', '-', '--xml', target)
            if signature and plistlib.loads(signature).get('com.apple.security.get-task-allow'):
                raise ValueError('Debug entitlement remains: ' + str(target.relative_to(app)))
        (volume / 'Applications').symlink_to('/Applications')
        shutil.copy2(root / 'docs/INSTALL.txt', volume / '安装说明 Installation.txt')
        dmg = destination / (stem + '-macos-arm64.dmg')
        run('hdiutil', 'create', '-volname', '菜单收纳 ' + version, '-srcfolder', volume,
            '-format', 'UDZO', '-fs', 'HFS+', dmg)
        run('hdiutil', 'verify', dmg)

    # Corresponding source includes the pinned dependency trees and packaging scripts.
    source_zip = destination / (stem + '-complete-source.zip')
    with zipfile.ZipFile(source_zip, 'w', compression=zipfile.ZIP_DEFLATED) as archive:
        archive_into(archive, root, revision, stem + '/')
        for pin in pins:
            archive_into(archive, checkouts[pin['identity']], pin['state']['revision'],
                         stem + '/dependencies/' + pin['identity'] + '/')
        archive.writestr(stem + '/BUILD-METADATA.json', json.dumps(metadata, indent=2) + '\n')
    (destination / 'SHA256SUMS-app.txt').write_text(''.join(
        hashlib.sha256(p.read_bytes()).hexdigest() + '  ' + p.name + '\n'
        for p in (dmg, source_zip)))
    print(destination)


if __name__ == '__main__':
    main()
