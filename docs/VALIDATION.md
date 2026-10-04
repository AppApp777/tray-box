# 验证范围 / Validation scope

0.4.0 在一台 Apple Silicon Mac、macOS 26.5.2 上完成了以下验证。这里只描述已取得的结果，不代表所有应用与显示模式都已兼容。

- 18 项定向单元回归通过，失败与跳过均为 0。覆盖手动布局、折叠几何、关闭保护、过期身份拒绝和开发夹具隔离。
- 独立 A/B/C 测试图标：A 放回顶栏再收回时，B/C 保持隐藏；同时核对原生位置和面板分组。
- 原应用菜单打开与关闭、右键移动、整理框内两组之间拖放、点击框外关闭。
- 测试图标重建后，清单更新并可以移动新图标。
- 正式安装的 0.4.0 包再次完成 A 往返；结束后移除测试夹具。

未完成完整验收：所有第三方应用、原生顶栏直接拖入面板、全屏、菜单栏自动隐藏、显示器热插拔、单次拖动跨屏、整机重启后的布局恢复、长期耗电与内存变化。

The regression and interactive checks used independent fixtures. Passing those checks does not imply universal third-party compatibility. The README animation is an explanatory diagram, not additional test evidence.
