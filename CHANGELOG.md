# 更新记录 / Changelog

## 0.4.3 — 待发布 / Unreleased

- 移除已停用的上游更新框架；构建时保留中文和英文资源，完整原始语言素材仍保存在源码里。
- 通知与预设管理器按需初始化；图标移动、位置校验、菜单恢复和权限处理继续使用完整底层。
- 收纳框关闭后保留一分钟图片缓存，快速重开继续复用；持续关闭后释放，重开取消旧清理任务。
- 57 项定向回归通过，含快速重开与排队清理取消检查；安装后交互和性能验收另行记录。

## 0.4.2 — 本地开发版 / Local development build

- 不再为当前面板截图计算未使用的背景颜色。
- 框外点击监听跟随面板打开和关闭；稳定且无界面显示时，备用清单扫描降到 30 秒，应用事件和打开面板仍会触发刷新。
- 图标复用 AppKit 图像，清理时释放派生缓存；取消等待中的截图任务，不执行过期刷新。
- 图像刷新跟随整理界面实际显示的两组；关闭时不预热截图，不初始化已禁用的上游更新器。
- 本机构建也剥离 Release 调试／局部符号，保留开发签名。

## 0.4.1 — 2026-10-06

- 应用更名为“秒收”（MiaoShou），面板、菜单、安装包和说明同步更新。
- 新增蓝色底、白色收纳托盘的简约应用图标。
- 保持应用标识、已有偏好设置与收纳交互不变。

Renamed the app to MiaoShou (秒收) and added a minimal blue-and-white tray icon. Application identifiers and menu organization behavior remain unchanged.

## 0.4.0 — 2026-10-04

首次开源，基于完整 Thaw 2.0.1 工程。

- 简洁收纳框；点击图标使用原应用菜单。
- 整理模式中的“已收纳／顶栏”两组、移动按钮和组间拖放。
- 点框外关闭，拖动和移动期间保持打开。
- 修复手动模式清单刷新、物理折叠状态判断、内部事件误关框及空白区域拖放。
- 18 项定向回归通过；独立测试图标完成安装版往返验证。

同一版本补充 DMG 安装包（Apple Silicon、macOS 26 起），采用 ad-hoc 签名，未经 Apple 公证。附完整源码及依赖、第三方许可和 SHA256 校验文件；原源码附件保持不变。

First public release, based on the full Thaw 2.0.1 implementation, with a compact panel, explicit organization controls and group-to-group drag and drop. Eighteen targeted regression tests passed. Includes an ad-hoc-signed, unnotarized DMG and complete source with pinned dependencies.
