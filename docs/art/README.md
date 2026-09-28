# Issue #19 — 原创像素资产交付

这里仅交付美术资源，不是可运行的 Godot 场景、关卡构图或战斗反馈实现。

![原生 384×216 预览](scene-native.png)

## 正式可导入文件

`assets/pixel/` 下的四张透明 RGBA PNG 是正式资产；`atlas.json` 是帧名、列序和锚点的机器可读清单。所有图集单行排列、无边距、无帧间隔，透明处 alpha=0，像素边缘未做抗锯齿。源文件为 `tools/build_pixel_art.py` 中的逐像素形状与色板，运行 `python tools/build_pixel_art.py` 可重建 PNG、清单及预览；需要 Pillow 10+。不要把 `concepts/` 的高分辨率概念图直接当作精灵导入游戏。

| 图集 | 单帧 | 列数／帧序（从 0 起） | 正面方向 |
| --- | --- | --- | --- |
| `operative.png` | 36×48 | idle, run_a, run_b, jump, fire, hurt, down | 右 |
| `mechanical_soldier.png` | 36×48 | idle, walk_a, walk_b, windup, fire, hurt, down | 左 |
| `defense_mech.png` | 80×72 | idle, charge_a, charge_b, fire, hurt, down | 左 |
| `base_tiles.png` | 24×24 | floor, floor_vent, gap_left, gap_right, wall, wall_vent, repair, rescue_sign, beacon_off, beacon_on | 不适用 |

行动员站姿、跑步两帧、跳跃、开火、受击与倒地；机械兵站姿、巡逻两帧、预告、开火、受击与倒地；防御机甲站姿、两段蓄力、开火、受击与损毁。机械兵胸前与机甲肩部共享橙红安防尖角标记，但各自体型仍能独立识别。机甲保持固定，蓄力核心增亮同时出现四边框，静音时也具有形态变化。`fire` 是射击瞬间姿态／枪口闪光，不包含弹丸贴图；受击帧不是无敌持续效果，反馈集成属后续票据。`down` 为终态，停留在原地；它不构成死亡／通关逻辑。

基地底板采用低饱和蓝灰。十字形救援标识、维修管线标记、可闪烁警戒灯、两种相反方向的黄色缺口边缘都自制。`gap_left` 放在缺口左侧最后一块实地，`gap_right` 放在右侧第一块实地；缺口本身保持空白，不使用伪装成地板的贴图。`repair` 和 `rescue_sign` 是覆盖层；`beacon_*` 具有透明背景。地板和墙图块按需重复，最终关卡布局需由关卡票据决定，示意图并不是关卡方案。

## Godot 4 导入建议

将 `assets/pixel/` 复制进项目 `res://`，Sprite2D 使用对应 PNG，启用 `hframes` 为列数、`vframes=1`，按照 JSON 的序号设置 `frame` 或定义 SpriteFrames 的 AtlasTexture 区域。纹理过滤设 `Nearest`，不使用压缩引起的边缘混色；整数倍放大。角色统一以单帧底边中心为站立锚点，建议用 Sprite2D 的 offset 将这一点对齐角色脚底；`down` 仍占原有 36×48 或 80×72 单元。敌人反向面对目标时可使用水平翻转，注意左右枪口、背包不对称细节也随之镜像。透明像素不是碰撞形状；碰撞体、可受击区域、机甲蓄力时长、动画时序和地图碰撞仍须在正式工程按试玩调试。

24px 图块是为角色约 1.5–3 格高的画面判读选择，预览的原生画布为 384×216。对照 `scene-native.png` 检查实际显示大小，`scene-3x.png` 和四张 `*-frames-3x.png` 仅用于审看硬边和所有帧。受击、弹丸、静音可判读与关卡公平性不能仅据静态预览宣布验收通过。

## 制作来源与权利边界

- 可编辑的正式图集源是本仓库 `tools/build_pixel_art.py`；本文、`atlas.json`、四张小图集和预览均由该源制作。代码中色板、轮廓坐标和动画变体是本次为本项目绘制，并受仓库根 `LICENSE` 约束。
- `concepts/` 下四张大图是本次用内置 image generation 按下列原创描述产生的概念参考（2026-09-28）；不从图中自动采样颜色、缩小或切帧。生成图自身存在软边、非统一像素尺寸和复杂照明，故不用于游戏运行资源。最终像素图集按概念方向重新绘制。生成过程未输入第三方角色、商标或现成游戏截图。
- 本票没有下载或打包 Kenney、字体、音效或其他第三方素材，因此没有需要登记的第三方实际入包文件；将来使用它们时仍需按 [许可研究 #4](https://github.com/immorcoding/hundouluo/issues/4) 逐文件审查。不得把概念参考误标为第三方许可证明。
- 需求依据：[本票 #19](https://github.com/immorcoding/hundouluo/issues/19)、[父规格 #12](https://github.com/immorcoding/hundouluo/issues/12)、[原创视觉决策 #7](https://github.com/immorcoding/hundouluo/issues/7)、[许可研究 #4](https://github.com/immorcoding/hundouluo/issues/4)。只借鉴横向跑跳射击类型，不借用经典作品的造型、标志或关卡排列。

### 概念参考的生成提示（内置工具，非游戏最终图）

四张图分别要求透明背景、无文字／商标／水印、硬边有限色板的游戏概念：

1. `operative-concept.png`：轨道基地救援维修行动员；青白色、紧凑偏圆、亮面罩、单侧工具背包；朝右全身姿势。
2. `mechanical-soldier-concept.png`：失控安防机械兵；橙红色、尖角装甲、窄暗传感器、前向发射器；朝左全身姿势。
3. `defense-mech-concept.png`：固定宽体深蓝炭色防御机甲；橙色蓄力核心、低位炮口、两侧支撑；朝左全身姿势。
4. `base-concept.png`：蓝灰轨道基地维修通道，救援标识、警戒灯、缺口黄色边缘；侧视、无角色。

共同排除：经典游戏人物／关卡／Boss、已有标志、文字和水印。概念图仅供原创方向检查；正式图集全部在可编辑源中单独绘制。
