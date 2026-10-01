# 轨道基地 · v0.1.1

用户于2026-09-30明确确认“大部分和之前一样，然后bug也没有了，可以通过了，封板吧”，v0.1.1验收通过。残骸遮人#34、跑射枪口#35、火光接缝/枪身闪烁#36均接受，其他项沿用[rc.1人审](https://github.com/immorcoding/hundouluo/issues/31#issuecomment-5911543601)，真人机甲时间仍为“时间差不多”，不补造秒数。已填[试玩记录](docs/acceptance-v0.1.1.md)和[定点复测单](docs/retest-v0.1.1-rc.3.md)，[已知事项](docs/known-issues-v0.1.1.md)保留历史工程条件及延期项。

正式[GitHub Release](https://github.com/immorcoding/hundouluo/releases/tag/v0.1.1)提升已确认的rc.3原包，构建/source_commit仍为67184574eb4e73735eafc42f5aee50762f6f7c29；ZIP/EXE字节及SHA不变，包内仍标0.1.1-rc.3/Windows0.1.1.3。这是候选提升，不是新构建；封板提交仅更新验收/发布文档。旧包与原人审保留，具体身份与SHA见[发布记录](docs/release-v0.1.1.md)。

本仓库是正式的 Godot 4.7.2 标准版 / GDScript 源项目，与 `.scratch/` 中的抛弃式手感灰盒分开。主场景 `scenes/level.tscn` 是五段关卡：行动员可跑跳射击、跨越唯一缺口，五名机械兵可击败或绕过；终点防御机甲完整入镜后激活，必须击败它才能显示任务完成并开启门挡。HUD 展示生命及终点机甲血量。生命耗尽与跌落显示不同死因，按 R 可无限次从起点重载整关。`tests/mechanical_encounter.tscn` 和 `tests/defense_mech_encounter.tscn` 仍可单独观察战斗组件。

## 打开与运行

1. 使用 Godot **4.7.2 标准版**，在项目管理器选择本目录中的 `project.godot` 导入。
2. 在编辑器按 **F6** 运行当前 `scenes/level.tscn`，或按 **F5** 运行配置好的主场景。
   要试玩当前机械兵模块，请打开 `tests/mechanical_encounter.tscn` 并按 **F6**；行动员从左侧接近，按住 J 射击或跑跳绕过。
   默认窗口为 1280×720，内部 640×360、整数倍像素显示。死亡或击败机甲后按 R 完整重试，无检查点。
3. 命令行可用 `Godot_v4.7.2-stable_win64_console.exe --path <本目录> --editor` 打开编辑器；`--headless --path <本目录> --quit-after 2` 可做无界面启动检查。

目前的输入动作都在 `project.godot` 的 Input Map 中配置为**物理键位**（不随键盘布局的字符变化）：

| 动作 | 键位 |
| --- | --- |
| 向左移动 `move_left` | A / ← |
| 向右移动 `move_right` | D / → |
| 跳跃 `jump` | Space |
| 射击 `shoot` | J |
| 重试 `retry` | R |

移动、跳跃、射击分别使用独立动作，可以同时按住；行动员按当前面向方向连续开火。rc.1已通过用户设备的按键组合与操控验收，本轮不要求重验。

## 关卡接缝

唯一主场景 `scenes/level.tscn` 保留 `Operative`、`Enemies`、`BossSlot`、`Projectiles` 四个 2D 实例槽，以及屏幕空间的 `HUD` 槽。行动员、机械兵和机甲通过 `projectile_fired(projectile)` 信号交由关卡安置弹丸。关卡只在敌人完整入镜后允许攻击；机甲此时才可受击。行动员公开 `health`（初始 3）、`receive_hit()`、`health_changed(health)` 与 `died()`；短暂无敌由行动员自行判定。关卡接收死亡与机甲击败信号，决定失败/通关状态和重载；HUD 只显示，不改变伤害规则。

碰撞层约定：行动员为第 1 层、普通敌人和机甲为第 2 层、地形为第 3 层、己方弹丸为第 4 层、敌弹为第 5 层。青白短光束与橙红实体弹在颜色、形状上可区分；机械兵亮起枪口、机甲蓄力预告。镜头水平跟随行动员、留出前方空间，闭门后锁定。速度、生命、预告和射击间隔等沿用已人审通过的参数，本轮不调平衡。

运行时反馈由 `CombatFeedback` 观察关卡事件，不参与伤害判定：八个 `assets/audio/` 原创 WAV 分别用于轻己方射击、敌弹、击中、行动员受击、单兵预告、机甲蓄力与两种死因；没有背景音乐。弹丸击敌或击墙产生 0.16 秒局部标记。行动员受伤后以稳定暖色表示短暂无敌，低血量 HUD 改色，机甲枪口在蓄力期间逐渐放大，血量条随有效命中下降；失败遮罩明确区分死因且保留 R 重试。没有全屏闪烁或持续镜头震动。音量初值由 `scripts/combat_feedback.gd` 调整，资源来源见 [素材清单](docs/assets-manifest.md)。

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
& '<Godot 4.7.2 console.exe 路径>' --headless --path . --script tests/level_boss_wiring.gd
& '<Godot 4.7.2 console.exe 路径>' --headless --path . --script tests/level_outcomes_retry.gd
& '<Godot 4.7.2 console.exe 路径>' --headless --path . --script tests/level_feedback.gd
python -m unittest discover -s tests -v
```

首次在新目录运行脚本前，先用 `--headless --editor --path . --import` 导入资源。上方仅列部分入口；完整44脚本（含间接继承）由`tools/check_issue_31.py --clock paced`统一发现，`mechanical_encounter.gd`与`defense_mech_encounter.gd`是场景fixture。完整检查须用干净隔离Git副本和位于副本外的E盘临时目录；固定模拟60fps加17ms明确墙钟等待，终局120Hz/30fps。默认headless音频/相机fixture失败另记，不宣称无条件全绿。
release的显式`--rc3-render-verification=<固定模式>`在EXE入口自身校验输出：以Godot解析后`OS.get_cmdline_user_args()`为参数边界，唯一非空`--out`须为规范化绝对E路径，位于本E工作树`.godot/issue31-rc3`或`E:/Projects/game_hundouluo_codex_artifacts/v0.1.1-rc.3`内，父目录既存且祖先无链接，目标文件/目录必须不存在。入口先原子创建新目录才加载固定fixture，拒绝时exit1、不进入fixture；普通无flag启动保持原main。Godot先裁去原始参数两端空白，再解码`%20`；守卫不声称能拒绝引擎已裁去的原始字节。编码尾空格实际送达API后拒绝；原始尾空格被引擎规范化后仍按新目标／已有目标分别校验。原封EXE契约CLI为`tools/check_rc3_output_boundary.py`，独立于21项Python unittest。f208旧包覆盖哨兵的失败、此前仅依赖调用者校验的审查误判以及eb2原33/34预期不匹配均保留。

自动化不代替真人结论；rc.1通过项与本次三bug/整包明确接受分别记录，机甲真人时间沿用“时间差不多”。本次封板不改玩法、不重新有声/静音整包验收；实机证据见`docs/art/issue-31-rc3/`及持久rc.3目录，后续通过不重写历史失败。
