# Development

The complete application and XPC service are in `vendor/Thaw/Thaw.xcodeproj`. Scheme: `Thaw`. Product executable: `TrayBox`; output bundle is renamed to `秒收.app` by the wrapper script.

The public build keeps the application identifier `local.miao.traybox` and its companion service identifier. These are application identifiers, not credentials. Team defaults are cleared in the exported Xcode project; provide your own signing identity. Do not run multiple copies of the same bundle at once.

## Build

```sh
./scripts/build.sh
TRAY_SIGNING_IDENTITY='Apple Development: YOUR NAME (YOUR ID)' ./scripts/build.sh
```

Build prerequisites: Apple Silicon, macOS 26, Xcode 26.6 and a locally available stable signing identity. Dependencies are locked by `Package.resolved`. Build output and logs stay in `build/`. The script does not install, run or restart the app.

## Test

```sh
./scripts/test.sh
```

The shared test scheme sets `TRAYBOX_UNIT_TESTS=1` before initialization. The test host skips normal app setup, status-item creation and duplicate-instance termination. The script selects the tray interaction regressions, divider/window gates, and image-cache observation, gating, display and scale regressions; it is not the complete inherited upstream suite. The 0.4.2 candidate passed 58 tests.

A fixture-only build is available for development:

```sh
TRAY_FIXTURE_ONLY=1 TRAY_BUILD_CONFIGURATION=Debug ./scripts/build.sh
```

The marker is embedded in the bundle, and both the interface and move/click entry points allow only the independent fixture namespace. Do not use real personal applications as automated test fixtures. The normal product does not exclude applications by name.

## Integration boundaries

Preserve AppState initialization, the MenuBarItemService connection, HID handling and the `SetsCursorInBackground` setting. The hidden section's physical divider state differs from whether the panel is visible. Internal generated mouse events are not outside user clicks. Drag, move and temporary-menu restoration all participate in the panel's close guard.

The downloadable DMG uses ad-hoc signing and has not been notarized. See [distribution instructions](DISTRIBUTION.md) for certificate-free Release builds, packaging, source bundles and verification. The local development identity is not included in the public package.

The compact build uses `MIAOSHOU_COMPACT`, excludes Sparkle, and retains the upstream updater source behind its original-build condition. The resource build phase filters built copies to Chinese/English before signing; original catalogs remain in source. Notification and profile initialization is deferred, while menu-bar movement, XPC, HID and permission initialization remains intact. The image cache uses a cancellable one-shot idle release after 60 seconds.
