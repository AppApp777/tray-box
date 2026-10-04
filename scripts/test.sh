#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
identity="${TRAY_SIGNING_IDENTITY:-}"
if [[ -z "$identity" ]]; then
  identity=$(security find-identity -v -p codesigning | python3 -c 'import re,sys; ids=re.findall(r"\b([0-9A-F]{40})\b",sys.stdin.read()); print(ids[0] if len(ids)==1 else "")')
fi
[[ -n "$identity" && "$identity" != "-" ]]
result="build/traybox-tests-$(date +%Y%m%d-%H%M%S).xcresult"
xcodebuild -quiet -project vendor/Thaw/Thaw.xcodeproj -scheme Thaw \
 -destination "platform=macOS,arch=arm64" -configuration Debug -derivedDataPath build/thaw-derived.noindex \
 -clonedSourcePackagesDirPath build/thaw-packages.noindex -onlyUsePackageVersionsFromResolvedFile \
 -only-testing:ThawTests/TrayBoxRegressionTests \
 -only-testing:ThawTests/MidSectionTransitionTests \
 -only-testing:ThawTests/WindowIDsChangedGateTests \
 -resultBundlePath "$result" CODE_SIGN_IDENTITY="$identity" CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= \
 test > build/traybox-tests.log 2>&1 || { tail -70 build/traybox-tests.log; exit 1; }
xcrun xcresulttool get test-results summary --path "$result" --compact
