# 菜单收纳的完整 Thaw 底层

- 上游：https://github.com/thaw-app/Thaw
- 固定版本：2.0.1，commit `d5eab80b4e1f62328a8b130994220e49524a48d1`。
- 使用 `git archive` 收录完整已跟踪工程，没有复制 `.git`；许可证保留为 GNU GPLv3，见 `LICENSE`。版权保留在源文件中。
- 本地修改：独立 bundle／XPC 标识、`Thaw/TrayBox/` 简洁面板、原 IceBarPanel 的焦点与关闭条件、手动整理的缓存／自动归位守卫、应用启动默认值和测试宿主隔离。
- 仍保留上游 AppState、HID、菜单栏识别、移动、菜单点击、临时展示、XPC 服务及完整初始化。`SetsCursorInBackground` 保持原启动位置。
- 本地版本通过`scripts/build.sh` 构建构建；本地版已禁用上游 Sparkle 自动更新。图标缓存仅保存在内存。
- `--fixture-only` 仅用于开发：界面和动作入口只允许独立 `local.miao.thaw-baseline-fixture`，底层 move/click 也拒绝其他应用图标。普通启动不屏蔽任何用户应用。
- `TRAYBOX_UNIT_TESTS=1` 只用于测试宿主：不执行应用 setup、不创建分隔项、不终止已有应用实例。
