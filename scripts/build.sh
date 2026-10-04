#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
identity="${TRAY_SIGNING_IDENTITY:-}"
if [[ -z "$identity" ]]; then
  identity=$(security find-identity -v -p codesigning | python3 -c 'import re,sys; ids=re.findall(r"\b([0-9A-F]{40})\b",sys.stdin.read()); print(ids[0] if len(ids)==1 else "")')
fi
if [[ -z "$identity" || "$identity" == "-" ]]; then
  echo '需要稳定的代码签名；有多个证书时用 TRAY_SIGNING_IDENTITY 指定。' >&2
  exit 1
fi
configuration="${TRAY_BUILD_CONFIGURATION:-Release}"
mkdir -p build/release.noindex
xcodebuild -quiet -project vendor/Thaw/Thaw.xcodeproj -scheme Thaw CLANG_ENABLE_CODE_COVERAGE=NO \
  -configuration "$configuration" -derivedDataPath build/thaw-derived.noindex \
  -clonedSourcePackagesDirPath build/thaw-packages.noindex \
  -onlyUsePackageVersionsFromResolvedFile \
  ARCHS=arm64 CODE_SIGN_IDENTITY="$identity" CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= \
  build > build/thaw-build.log 2>&1 || { tail -60 build/thaw-build.log; exit 1; }
source_app="build/thaw-derived.noindex/Build/Products/$configuration/Thaw.app"
app="build/release.noindex/菜单收纳.app"
# Atomic staging inside build only. The installer alone touches Applications.
stage="build/release.noindex/.菜单收纳-stage.app"
if [[ -d "$stage" ]]; then rm -rf "$stage"; fi
ditto "$source_app" "$stage"
if [[ "${TRAY_FIXTURE_ONLY:-0}" == "1" ]]; then
  /usr/libexec/PlistBuddy -c 'Add :TrayBoxFixtureOnly bool true' "$stage/Contents/Info.plist"
  codesign --force --sign "$identity" --timestamp=none "$stage"
fi
codesign --verify --strict --deep "$stage"
if [[ -d "$app" ]]; then rm -rf "$app"; fi
mv "$stage" "$app"
plutil -lint "$app/Contents/Info.plist"
echo "$PWD/$app"
