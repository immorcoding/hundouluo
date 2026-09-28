# 轨道基地 · v0.1.0 工程入口

本仓库是正式的 Godot 4.7.2 标准版 / GDScript 源项目，与 `.scratch/` 中的抛弃式手感灰盒分开。行动员的移动、射击、受击及机械兵的巡逻、预告、敌弹与接触伤害模块已具备。主场景现为 #22 的救援机库**美术验收片段**：可跑、跳、射击并跨越一个真实缺口；其中机械兵和防御机甲仍是无碰撞、无 AI 的画面比例展示体。可运行 `tests/mechanical_encounter.tscn` 体验机械兵交战或绕过；#16 将把敌人接入五段正式关卡。守关敌人、HUD、死亡重试与通关尚未实现。

## 打开与运行

1. 使用 Godot **4.7.2 标准版**，在项目管理器选择本目录中的 `project.godot` 导入。
2. 在编辑器按 **F6** 运行当前 `scenes/level.tscn`，或按 **F5** 运行配置好的主场景。
   要试玩当前机械兵模块，请打开 `tests/mechanical_encounter.tscn` 并按 **F6**；行动员从左侧接近，按住 J 射击或跑跳绕过。
   默认窗口为 1280×720，内部 640×360、整数倍像素显示。跌落缺口后目前须用 F5 重启片段；R 的死亡重试行为属于后续票据。
3. 命令行可用 `Godot_v4.7.2-stable_win64_console.exe --path <本目录> --editor` 打开编辑器；`--headless --path <本目录> --quit-after 2` 可做无界面启动检查。

目前的输入动作都在 `project.godot` 的 Input Map 中配置为**物理键位**（不随键盘布局的字符变化）：

| 动作 | 键位 |
| --- | --- |
| 向左移动 `move_left` | A / ← |
| 向右移动 `move_right` | D / → |
| 跳跃 `jump` | Space |
| 射击 `shoot` | J |
| 重试 `retry` | R |

移动、跳跃、射击分别使用独立动作，可以同时按住；行动员按当前面向方向连续开火。不同实体键盘可能有 ghosting，真实按键组合须在后续试玩中复核。

## 关卡接缝

唯一主场景 `scenes/level.tscn` 保留 `Operative`、`Enemies`、`Projectiles` 三个 2D 实例槽，以及屏幕空间的 `HUD` 槽。行动员通过 `projectile_fired(projectile)` 信号交由关卡安置己方弹丸；机械兵也用此信号交由关卡安置敌弹。关卡只在机械兵完整入镜后允许它攻击。行动员公开 `health`（初始 3）、`receive_hit()`、`health_changed(health)` 与 `died()`；短暂无敌由行动员自行判定。机械兵拥有自身巡逻、生命、枪口预告和死亡逻辑，己方弹丸可通过 `receive_hit()` 击败它；敌弹和接触同样经行动员的受击入口，各只提交一次碰撞伤害。

碰撞层约定：行动员为第 1 层、普通敌人为第 2 层、地形为第 3 层、己方弹丸为第 4 层、敌弹为第 5 层。己方弹丸检测敌人和地形，敌弹检测行动员和地形。青白短光束与橙红实体弹在颜色、形状上均可区分；机械兵以亮起枪口预告。速度、生命、预告和射击间隔等是场景可调参数，尚未做真人手感验收。`Camera2D` 目前固定，后续关卡票据负责跟随与五段布局。
片段镜头水平跟随行动员、留出前方空间；正式五段布局仍属后续票据。碰撞层约定：行动员为第 1 层、普通敌人为第 2 层、地形为第 3 层、己方弹丸为第 4 层、敌弹为第 5 层。己方弹丸检测敌人和地形，敌弹检测行动员和地形。青白短光束与橙红实体弹在颜色、形状上均可区分；机械兵以亮起枪口预告。速度、生命、预告和射击间隔等是场景可调参数，尚未做真人手感验收。

当前美术采用 **ImageGen 原创生成辅助 + 分层／图集加工**，不是手绘：背景、支柱吊具、甲板和三个角色分别制作，原始 PNG、提示词与裁切配置保存在 `assets/art_source/`。运行 `python tools/build_pixel_art.py` 可离线重建正式资源；`tools/assemble_hangar_art.py` 负责缩放、透明边清理、有限调色板和脚底对齐。C 草图仅作对照，未作为整张可玩场景贴图。`scenes/level.tscn` 中两段地面碰撞矩形仍是坐标来源，`scripts/level.gd` 按形状裁出甲板、留出缺口并绘制警戒边缘。实际 Godot 截图、与 C 草图的对照、制作来源和待试玩事项见 [美术说明](docs/art/README.md)。

## 检查

在项目根目录分别运行：

```powershell
& '<Godot 4.7.2 console.exe 路径>' --headless --path . --script tests/project_smoke.gd
& '<Godot 4.7.2 console.exe 路径>' --headless --path . --script tests/input_smoke.gd
& '<Godot 4.7.2 console.exe 路径>' --headless --path . --script tests/scene_slots_smoke.gd
& '<Godot 4.7.2 console.exe 路径>' --headless --path . --script tests/operative_behavior.gd
& '<Godot 4.7.2 console.exe 路径>' --headless --path . --script tests/operative_shooting.gd
& '<Godot 4.7.2 console.exe 路径>' --headless --path . --script tests/operative_muzzle.gd
& '<Godot 4.7.2 console.exe 路径>' --headless --path . --script tests/friendly_projectile_hit.gd
& '<Godot 4.7.2 console.exe 路径>' --headless --path . --script tests/friendly_projectile_expiry.gd
& '<Godot 4.7.2 console.exe 路径>' --headless --path . --script tests/operative_damage.gd
& '<Godot 4.7.2 console.exe 路径>' --headless --path . --script tests/level_operative_wiring.gd
& '<Godot 4.7.2 console.exe 路径>' --headless --path . --script tests/mechanical_paths.gd
& '<Godot 4.7.2 console.exe 路径>' --headless --path . --script tests/mechanical_warning.gd
& '<Godot 4.7.2 console.exe 路径>' --headless --path . --script tests/mechanical_contact.gd
& '<Godot 4.7.2 console.exe 路径>' --headless --path . --script tests/mechanical_projectile.gd
& '<Godot 4.7.2 console.exe 路径>' --headless --path . --script tests/hangar_scene_smoke.gd
& '<Godot 4.7.2 console.exe 路径>' --headless --path . --script tests/hangar_play_smoke.gd
python -m unittest discover -s tests -v
```

首次在新目录运行脚本前，先用 `--headless --editor --path . --import` 导入资源。检查覆盖入口、输入和槽位、片段地形、行动员行为，以及机械兵交战与绕过、预告与镜头可见性、敌弹/接触单次受击和跳跃规避；它们不等同于真人试玩或完整关卡验收。实际视口截图可用 `& '<Godot 4.7.2 console.exe 路径>' --path . --rendering-method gl_compatibility --script tools/capture_hangar.gd` 重新生成（需要图形会话）。
