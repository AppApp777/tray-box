<div align="center">

<img src="assets/app-icon.png" width="112" alt="秒收 MiaoShou">

# MiaoShou · 秒收

Keep less-used Mac menu bar icons in a small panel, ready when you need them.

<p><a href="README.md">简体中文</a> · <b>English</b></p>

<img src="https://img.shields.io/badge/platform-macOS%2026-303846?style=for-the-badge" alt="macOS 26">
<img src="https://img.shields.io/badge/chip-Apple%20Silicon-52796F?style=for-the-badge" alt="Apple Silicon">
<img src="https://img.shields.io/github/license/AppApp777/tray-box?style=for-the-badge" alt="GPLv3 license">
<img src="https://img.shields.io/badge/version-0.4.1-597A9B?style=for-the-badge" alt="Version 0.4.1">

<br><br>
<img src="assets/demo.gif" width="800" alt="Illustration: move A to the menu bar and back while B and C stay hidden">

Interaction illustration with fictional A, B and C icons. Not a screen recording or a performance measurement.

</div>

## Download and install

| System | Download |
|---|---|
| macOS 26 or later, Apple Silicon | **[Download the 0.4.1 app (DMG)](https://github.com/AppApp777/tray-box/releases/download/v0.4.1/miaoshou-0.4.1-macos-arm64.dmg)** |
| Developers and source code | [Complete source with dependencies](https://github.com/AppApp777/tray-box/releases/download/v0.4.1/miaoshou-0.4.1-complete-source.zip) |

1. Open the DMG and drag **秒收.app** into **Applications**.
2. Open the installed app. **This package has not been notarized by Apple.** If macOS blocks it because the developer is unverified, verify its source, then use **System Settings → Privacy & Security → Open Anyway** for this app, as described by [Apple](https://support.apple.com/102445).
3. Grant Accessibility and Screen & System Audio Recording permissions. Quit and reopen if macOS requests it.

Xcode is not required. The app uses an ad-hoc signature, so updates may require granting permissions again. Quit the old version before replacing it, and avoid running multiple menu-bar organizers at once. See [installation instructions](docs/INSTALL.txt); `SHA256SUMS-app.txt` on the [release page](https://github.com/AppApp777/tray-box/releases/tag/v0.4.1) checks download integrity.

## Use

- Open the panel from the menu bar. Click an icon to use the original application's menu.
- Choose “整理” (Organize) to see the hidden and visible groups. Use the move buttons or drag between those groups.
- Click outside or press Escape to close. The panel stays open while dragging or moving an icon.

The current panel uses Chinese labels. Group-to-group dragging has been tested; dragging directly from the native menu bar into the panel has not. Full-screen mode, auto-hiding menu bars and complex display changes need further validation. Some fixed system items cannot be moved. See [validation scope](docs/VALIDATION.md).

## Permissions and privacy

Enable Accessibility to move icons and open menus, and Screen & System Audio Recording to capture menu bar icon images. Both are in System Settings → Privacy & Security.

Icon images are cached in memory. Menu bar processing stays on your Mac; the app collects no usage data. Upstream automatic updates are disabled in this derivative. To uninstall, quit from the menu bar button's context menu and delete the app. Preferences are not deleted automatically.

## License and upstream

MiaoShou is an independent derivative of [Thaw 2.0.1](https://github.com/thaw-app/Thaw), which builds on [Ice](https://github.com/jordanbaird/Ice). It retains the complete underlying implementation and adds a compact panel, explicit organization controls, and related cache and window-state fixes. It is not an official upstream release.

Code is licensed under [GNU GPLv3](LICENSE). You may use, modify and redistribute it under that license; distribution of modified versions carries corresponding source and licensing obligations. Upstream notices are retained. See [upstream details](docs/UPSTREAM.md) and [asset provenance](docs/ASSET_LICENSE.md).

## Feedback and recent changes

Report problems and suggestions in [Issues](https://github.com/AppApp777/tray-box/issues), including your macOS version, display setup, affected application and steps to reproduce.

**2026-10-06 · 0.4.1** — Renamed to MiaoShou (秒收), with a new minimal app icon. See the [changelog](CHANGELOG.md).

## About the author

Qiye makes small tools for everyday use and documents the process.

| Douyin | Xiaohongshu |
|:---:|:---:|
| <img src="assets/qr-douyin.png" width="160" alt="Qiye on Douyin"> | <img src="assets/qr-xiaohongshu.png" width="160" alt="Qiye on Xiaohongshu"> |
| 七也 · `miao1162603325` | 七也 · Scan for profile |

<details>
<summary><b>Build from source</b></summary>

Requires an Apple Silicon Mac, macOS 26, Xcode 26.6 and your own Apple Development signing certificate. The first build downloads pinned development dependencies.

```sh
git clone https://github.com/AppApp777/tray-box.git
cd tray-box
./scripts/build.sh
```

The output is `build/release.noindex/秒收.app`. Copy it to a stable Applications location before granting permissions. A development signature is intended for local development and is not Developer ID distribution signing or notarization.

If you have multiple certificates, select your identity with `TRAY_SIGNING_IDENTITY`. The script does not create, upload or change certificates. Run targeted regression tests with `./scripts/test.sh`. See [development notes](docs/DEVELOPMENT.md).

</details>
