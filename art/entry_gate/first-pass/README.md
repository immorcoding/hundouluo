# #32 入口闸门 · 原创设计待确认

基准：`3f970aafdd4628d0da931997197e630a7736735b`（#28 后 main），沿用 #22 已认可的救援机库。仅提供独立美术和真实关卡上的临时预览；未接入正式 CombatEntry。需求权威：[GitHub #32](https://github.com/immorcoding/hundouluo/issues/32)，后续工程接入为 #33。

## 设计

窄幅分节钢闸：顶部卷收机匣、短导向叉、冷灰旧钢板、凹槽与铆点、两道黄铜锁栓。钢板与现有机库支柱共用冷暗材质方向，用少量琥珀光说明动作，不增加大型发光面、底部泛光或遮住战斗区的门框。门板不是 HUD。

| 状态 | 画面信息 | 美术姿态 |
| --- | --- | --- |
| 开放 | 两个暗青定位灯，机匣下为空；没有落地导轨假装封路 | `open.svg/png` |
| 警告 / 下降 | 琥珀灯常亮、向下小箭头、带亮边的门靴逐步下降；不频闪 | `warning-0` 到 `warning-5` |
| 关闭 | 连续钢板落到甲板，两个黄铜横栓；没有透空的“可通行”中缝 | `closed.svg/png` |

每帧 40×176，透明像素仅 alpha=0/255，最近邻 1:1 显示。脚底锚点为 `(20,176)`，放在世界 `(3444,252)`；门板在本地 x=[13,27)、y=[28,176)，对应现有 14×148 碰撞范围。顶部机匣比门板宽，最大 36px，仅位于通道上方。静止状态主色饱和度低于行动员与炮口。

六个警告姿态露出深度为 8/16/28/44/62/80px，末帧仍保留 68px 下方通道，能容纳 52px 高身体。**真正碰撞闭合时才切换落地姿态**；最后 68px 是快速落锁，不能把这段图稿解释成提前关闭碰撞或延长警告。预览仅观察原有关卡计时和碰撞，视觉不控制它们。取消时直接回到卷收态；若用户不喜欢最后落锁的速度或取消读数，应在本票修改视觉稿，不能暗改 0.22s 窗口。

## 原生实景与短循环

以下截图由 Godot 4.7.2 OpenGL Compatibility 图形会话直接保存视口，**每张 640×360、未重绘合成**。关卡、机甲、行动员、弹丸和碰撞为真实实例。预览脚本只在临时实例隐藏旧入口图形、把新图形放在行动员/弹丸后面；初始站位由脚本设置，随后射击与退避使用 Input 动作。不是真人试玩录像。

| 核对 | 文件 |
| --- | --- |
| #28 原竖条，同机位同姿态 | [baseline-closed.png](baseline-closed.png) |
| 开 / 警告 / 关 | [scene-open.png](scene-open.png) · [scene-warning.png](scene-warning.png) · [scene-closed.png](scene-closed.png) |
| 贴近封锁边界 | [boundary-closed.png](boundary-closed.png) · [boundary-combat.png](boundary-combat.png) |
| 实际弹道 | [scene-combat.png](scene-combat.png) |
| 警告期左退取消 | [retreat-warning.png](retreat-warning.png) · [retreat-cancelled.png](retreat-cancelled.png) |
| 六图同尺度对照，每格保留 640×360 | [review-sheet.png](review-sheet.png) |

三段各 2.2s 的原速循环：[正常闭合 GIF](scene-loop.gif)、[边界 GIF](boundary-loop.gif)、[左退取消 GIF](retreat-loop.gif)。每段循环的尾部跳回开放，是重新播放拍摄序列，**不表示同一次战斗内自动开门**。GIF 为共享 256 色调色板，20/10/20ms 三帧共 50ms；全色 APNG 使用 17/16/17ms 三帧共 50ms，以毫秒精度表达 60Hz 采样，分别为 [scene-loop.png](scene-loop.png)、[boundary-loop.png](boundary-loop.png)、[retreat-loop.png](retreat-loop.png)。支持 APNG 的浏览器可直接播放；编码器会合并连续相同画面并保留停留时长。

![原生同尺度核对](review-sheet.png)

## 可编辑源、来源与许可

本票采用代码逐像素设计，没有调用 ImageGen，没有输入或借用外部游戏图像、字体、素材包。`build.py` 是主制作源，显式保存调色板和几何；生成的八张 SVG 包含分组的门板、机匣与指示灯，可在矢量编辑器中独立编辑。PNG 是同源的透明导出。需要继续可重复构建时，修改 `build.py`；直接编辑 SVG 后须自行同步导出，重跑脚本会覆盖 SVG。

| 实际使用内容 | 来源 / 权利记录 |
| --- | --- |
| 新门体几何、SVG、PNG、工具与本文 | 本项目原创代码制作，沿用根目录 [MIT LICENSE](../../LICENSE) |
| 实景中的机库、甲板、行动员、机甲 | 仓库 #22 已确认原创生成辅助资产；来源与限制见 [art_source/README](../../assets/art_source/README.md) 和 [PROMPTS](../../assets/art_source/PROMPTS.md)；本票没有重新授权或宣称独占版权 |
| 原竖条及现有关卡反馈 | 基准提交的项目代码，根目录 MIT LICENSE |
| Pillow / Godot | 制作与预览工具，不作为外部游戏素材；没有新依赖进入游戏运行时 |

所有交付文件已本地化，离线可重建。`art/entry_gate/.gdignore` 使审稿源与循环不被正式游戏导入。

## 重现

在指定工作树根目录运行（Python + Pillow 10.4.0，Godot 4.7.2）：

```powershell
python art/entry_gate/build.py
& Godot_v4.7.2-stable_win64_console.exe --headless --editor --path . --import
& Godot_v4.7.2-stable_win64_console.exe --path . --rendering-method gl_compatibility --fixed-fps 60 --script tools/preview_entry_gate.gd
python art/entry_gate/package_previews.py
```

逐帧原片保存在忽略提交的 `capture-frames/`，打包脚本不缩放画面。正式 F5 主场景仍显示 #28 原入口。预览读取原有关卡的私有计时字段，仅限本票观察工具；#33 应自行确定正式视觉接缝。

## 验证与人工确认边界

预览观察到：正常/边界序列警告从 frame 32 开始，frame 46 闭合，即 60Hz 下 14 帧约 0.233s；原代码仍为 0.22s，逐帧计时量化未改。左退取消序列通过真实向左输入跨回 x<3463，未发生闭合。边界序列关闭后向左走最终停在 x≈3463.075，机甲完整入镜。

目视核对：门关闭的连续边缘可见，材质不再是浅色平条；贴边行动员绘制在门前，枪管轮廓完整；门在机甲炮口左方，橙色危险提示与青色己方弹丸仍明显；没有把新图形伸入 y≥252 的低位甲板；警告态下方通道仍空，取消后不残留假门板。0.22s 本身较短，箭头和灯只能辅助读数，不能证明首次游玩的反应公平性。最后快速落锁、亮度与取消速度仍需用户观看原速循环确认。

自动验证记录见 [VALIDATION.md](VALIDATION.md)。用户明确确认外观与运动读数前，#32 保持开放，标记 ready-for-human；不合并，不接入正式游戏。
