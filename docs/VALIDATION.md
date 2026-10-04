# 验证范围 / Validation scope

0.4.0 在一台 Apple Silicon Mac、macOS 26.5.2 上完成了以下验证。这里只描述已取得的结果，不代表所有应用与显示模式都已兼容。

- 18 项定向单元回归通过，失败与跳过均为 0。覆盖手动布局、折叠几何、关闭保护、过期身份拒绝和开发夹具隔离。
- 独立 A/B/C 测试图标：A 放回顶栏再收回时，B/C 保持隐藏；同时核对原生位置和面板分组。
- 原应用菜单打开与关闭、右键移动、整理框内两组之间拖放、点击框外关闭。
- 测试图标重建后，清单更新并可以移动新图标。
- 正式安装的 0.4.0 包再次完成 A 往返；结束后移除测试夹具。

未完成完整验收：所有第三方应用、原生顶栏直接拖入面板、全屏、菜单栏自动隐藏、显示器热插拔、单次拖动跨屏、整机重启后的布局恢复、长期耗电与内存变化。

The regression and interactive checks used independent fixtures. Passing those checks does not imply universal third-party compatibility. The README animation is an explanatory diagram, not additional test evidence.

## 公开 DMG 的额外检查

公开包由公共提交 `e416cb9` 的源码以 Release 模式重新构建；显式关闭覆盖率插桩，剥离暂存二进制的调试与局部符号，使用 ad-hoc 签名。与已验证开发版的应用源码一致，签名与打包方式不同。

- DMG 完整性校验通过；只读挂载并复制出应用后，7 个代码组件通过签名检查。
- 主程序和后台服务不含覆盖率运行时及本机构建路径，没有调试器附加权限。
- 主程序在 `TRAYBOX_UNIT_TESTS=1` 隔离模式下完成加载；不会创建顶栏控制项或退出日常运行副本。
- 将包内 XPC 原样放入独立宿主，`start` 请求得到正确回复；未操作真实菜单栏应用。
- 完整源码包包含 11 项锁定依赖的源码与许可；应用内附第三方声明和构建来源。

包没有经过 Apple 公证，Gatekeeper 不会自动放行。以上检查不代替全新 Mac 的首次下载、手动允许、权限授权和菜单交互验收；这些仍待实测。你正在使用的开发签名版本未被替换。
