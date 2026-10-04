# Distribution

The 0.4.0 DMG contains an **ad-hoc-signed, unnotarized** Release build for Apple Silicon and macOS 26. It is not signed with Developer ID. Gatekeeper will not accept it automatically. See [installation instructions](INSTALL.txt) and [Apple's guidance](https://support.apple.com/102445).

The package retains hardened runtime and uses `com.apple.security.cs.disable-library-validation` so teamless code can load the embedded Sparkle framework. It omits `com.apple.security.get-task-allow`. The existing teamless XPC path is used. No certificate, private key, provisioning profile, permission grant or personal preference file is shipped. Upstream automatic updates remain disabled. Ad-hoc signatures do not provide a stable identity across updates; permissions may need to be granted again.

## Reproduce the package

Use a clean public Git checkout with Xcode 26.6. Commit changes before packaging. This command builds without a personal certificate; it does not install, launch or restart any app.

```sh
xcodebuild -quiet -project vendor/Thaw/Thaw.xcodeproj -scheme Thaw ENABLE_CODE_COVERAGE=NO \
  -configuration Release -derivedDataPath build/public-release-derived.noindex \
  -clonedSourcePackagesDirPath build/thaw-packages.noindex \
  -onlyUsePackageVersionsFromResolvedFile ARCHS=arm64 CODE_SIGNING_ALLOWED=NO \
  GCC_GENERATE_DEBUGGING_SYMBOLS=NO SWIFT_SERIALIZE_DEBUGGING_OPTIONS=NO build
python3 scripts/package.py \
  --app build/public-release-derived.noindex/Build/Products/Release/Thaw.app \
  --packages build/thaw-packages.noindex \
  --output build/distribution-0.4.0
```

The output directory must not already exist. The packager rejects fixture-only builds, dirty source/dependencies, mismatched dependency revisions, unsupported architectures and enabled upstream automatic updates. It requires the built source's `vendor/Thaw` tree to match the checkout. It strips staged Mach-O debugging/local symbols and rejects remaining home-directory paths. It signs nested components before the containing app, verifies signatures, and creates a DMG with an Applications shortcut and bilingual instructions.

`tray-box-0.4.0-complete-source.zip` includes the public application source, packaging scripts and all 11 pinned dependency source trees. Each retains its original license. The application's `Contents/Resources/THIRD_PARTY_NOTICES.txt` includes dependency notices; `BUILD-METADATA.json` records source revisions and build settings. The original 0.4.0 source ZIP and checksum remain available unchanged.

Xcode resolves the pinned dependencies via `Package.resolved`; a normal build needs network access and Apple's SDK. The complete source archive also includes the dependency trees separately for inspection and modification. It is not a preconfigured offline Xcode workspace, and the resulting binary is not claimed to be bit-for-bit reproducible.

## Verification

Use `hdiutil verify` for the image, mount it read-only without launching the app, copy the app out with `ditto`, then run `codesign --verify --deep --strict`. Confirm version, arm64 architecture and the absence of debug/fixture flags. Verify the release download against `SHA256SUMS-app.txt`; successful local launch without a browser quarantine flag is not a first-download Gatekeeper test.

For a future notarized release, obtain a Developer ID Application identity, restore same-team library validation, sign inside out, submit to Apple's notary service, staple the result and validate a fresh download on a clean Mac. This script intentionally does not claim to perform that workflow.
