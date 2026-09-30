# #30 获批 HUD 与结算资源

只接入 #27 已确认的 S6 和最终结算稿。S6 批准提交为 `2092f7076e55b398a439ed21e4943e9371abf08a`，冻结清单在 `prototypes/issue-27-ui/outcome-review/approved-hud.json`；结算稿为 `4c009adc21bd350732f9e44425f6f16584331c21` 的 `outcome-review/render.gd`。#27 当前已关闭；目录内早先“待确认”的说明是当时的历史记录。

运行时使用普通 TextureRect、Label、ProgressBar 和 ColorRect；不加载原型绘制器。三枚实心弹壳固定沿当前按住 J 连发的视觉，没有半/全自动切换、弹药库存或换枪逻辑。

| 入包文件 | 既有原始资源 / 切片 | 游戏内大小及位置 |
| --- | --- | --- |
| `hud.png` | S6 原生边框、头像背板及 18×7 三枚弹壳，按冻结绘制定义重建 | 192×68，左下 6px，即 [6,286] |
| `portrait.png` | `throwaway-ab/source/operative-portrait.png`，区域 [310,184,656,632]，保留原 RGBA | 48×48，[16,296] |
| `rifle.png` | `throwaway-portrait-match/source/rifle.png`，区域 [136,118,1928,540]，保留原 RGBA | 76×24，[70,298] |
| `life-full.png` / `life-empty.png` | S6 三格生命的实槽/空槽；包含 1px 外缘 | 每格 38×14，[69,333] 起，间隔 40px |
| `outcome-top.png` | `source/console-panel.png`，[20,92,1734,100] | 288×16，[176,88] |
| `outcome-bottom.png` | 同原图，[20,674,1734,100] | 288×16，[176,220] |
| `fusion-pixel-12px-proportional-zh_hans.otf` | 原字体不改字节，SHA256 `e84b6d1ab8f2e25084761eb61c88b373bf1fa0b0c5e9b559d5b1d90e4d658c86` | 普通字 12px，标题 24px |

头像、枪图和金属原图均为项目已有 ImageGen 原创辅助资产；完整提示词分别保留在 `prototypes/issue-27-ui/throwaway-ab/source/`、`throwaway-portrait-match/source/PROMPT.md` 与 `source/PROMPT.md`。本票没有生成新美术，也没有使用第三方图包。原有项目图形来源及 MIT 许可沿根目录 LICENSE；不声明手绘或独占权利。

图标/边沿保留原 RGBA 切片，在运行时一次 nearest 采样，避免透明图二次烘焙。上下金属边沿乘色 (0.8,0.85,0.9,1)。全屏均匀深蓝遮暗 36%；结果、原因、R 提示以 x320 居中，基线 y138 / y170 / y208。失败标题琥珀、完成标题青色；原因和 R 白色，结算隐藏战斗 HUD。

字体为 TakWolf Fusion Pixel Font 2026.09.25，原始下载、版本与来源见 `prototypes/issue-27-ui/source/fonts/README.md`。字体使用 SIL OFL 1.1，不能按项目 MIT 重授权；同目录 `OFL.txt` 与 `LICENSES/` 保留字体及上游完整版权/许可通知。Windows 现有打包流程会复制 `docs/assets-manifest.md`，该文档也携带这些完整通知，确保发行包随附许可。字体导入关闭抗锯齿、hinting、MSDF、系统回退和亚像素定位，oversampling=1。

在仓库根目录用 Godot 4.7.2 重建：

```powershell
& Godot_v4.7.2-stable_win64_console.exe --path . --audio-driver Dummy --rendering-method gl_compatibility --script tools/build_ui_assets.gd
& Godot_v4.7.2-stable_win64_console.exe --headless --editor --path . --import
```

工具直接读取项目既有原图，并离线生成原生边框/生命格；不是游戏组件。运行结果及实机比对见 `docs/art/issue-30/README.md`。
