# #34 敌人残骸遮挡行动员：诊断记录

## 反馈环与真实复现

沿用已批准的测试 seam：正式 `scenes/level.tscn`、正式行动员/敌人组件、直接调用敌人的公开 `receive_hit()` 命中事件作为状态 fixture、Godot 实际 640×360 视口截图。输入 fixture 和截图由代理无人值守执行；没有改 `level.gd`、`level.tscn`、行动员、碰撞或伤害值。

反馈环命令（Godot 4.7.2，OpenGL Compatibility，固定 60 Hz）：

```powershell
Godot_v4.7.2-stable_win64_console.exe --path . --audio-driver Dummy --rendering-method gl_compatibility --fixed-fps 60 --script tools/capture_issue_34.gd
```

工具载入正式关卡，击败 `Enemies/SoloSoldier`，将行动员站在残骸中心，依次捕获无两者、只残骸、只行动员和两者重叠四张真实视口图。像素反馈环将单体图相对背景的变化作为两张精灵的可见像素掩码，再逐像素判断合成图命中哪张精灵；它不读取层级数值来判定通过。

基线输出：

```text
ISSUE_34_PIXEL_COMPARISON {"native_size":[640,360],"overlap_pixels":243,"operative_front_pixels":0,"wreck_front_pixels":243,"operative_front_ratio":0.0,"wreck_visible_pixels":673,"soldier_health":0,"wreck_frame":6}
ERROR: Operative is visually behind the wreck at 0/243 distinguishable overlap pixels
exit_code=1
```

原命令连续两次给出同样的 243/243 像素结果。移除任一精灵可见层后，比较区域不再有这 243 个可判读重叠像素；最小复现保留正式关卡背景/甲板、一个真实机械兵残骸和一个站立行动员。基线截图为 [`soldier-standing/combined.png`](../../art/issue-34/before/soldier-standing/combined.png)，四张比较图和 JSON 同在该目录。

机甲的独立正式关卡 fixture 同样先用 42 次公开命中事件击败真实防御机甲，再将行动员放到残骸位置。基线输出为 `overlap_pixels=801, operative_front_pixels=0, wreck_front_pixels=801, wreck_visible_pixels=3315`；`exit_code=1`。结果态的既有胜利面板保持可见。原生图见 [`mech-standing/combined.png`](../../art/issue-34/before/mech-standing/combined.png)。

## 排序假设与单变量验证

| 顺序 | 可证伪预测 | 探针结果 | 结论 |
| --- | --- | --- | --- |
| 1. 关卡分支顺序决定同层遮挡 | 只将 `Enemies` 分支移动到 `Operative` 分支之前，合成像素应改由行动员获胜。 | `--probe branch-before-operative`：行动员前景 `243/243`；根节点分支索引从行动员 9 / 敌人 10 变为敌人 9 / 行动员 10。 | 证实同层时后绘制的敌人分支覆盖行动员。此探针也改变活敌的先后层级，因此不能作为最终修复。 |
| 2. 死亡状态没有改变精灵绘制顺序 | 固定场景与同位置，只把敌人从活着切换为死亡，胜出的仍应是敌方精灵。 | `live-state`：行动员前景 `0/664`；死亡态：`0/243`。两态 `Enemy Sprite.z_index=0`、`Operative Sprite.z_index=0`。 | 证实倒地帧沿用活敌所在的后绘制分支；死亡只换图帧，没有产生残骸层。 |
| 3. 单独把残骸设到 z=-1 可以解决遮挡 | 残骸应改在行动员之后可见；若世界背景和甲板仍为 z=0，精灵也可能被其覆盖。 | `--probe sprite-negative-z`：行动员/残骸可判读重叠变为 0，残骸可见像素从 673 变为 0。 | 证实孤立负层会把残骸压到现有 z=0 背景后，违反保留残骸要求。 |
| 4. 防御机甲使用不同的层级路径 | 机甲尸体可能不会复现机械兵遮挡。 | 正式机甲基线 `0/801` 行动员前景；将世界深度分成背景 -3、甲板 -2、残骸精灵 -1、行动员/活敌 0 后，行动员前景 `801/801`，残骸仍有 3315 个可见像素。 | 机甲也受相同分支顺序影响；世界中间层方案同时覆盖两类残骸。 |

调整分支顺序确认了原因但不满足“活敌层级保持原状”；只改残骸为负层级又让它消失。最小可行的分层是为现有背景、甲板与死亡精灵分别留出 -3、-2、-1 三个深度带；行动员、活敌、门和弹丸继续保持原有 z=0 与树顺序。实机像素探针确认背景/甲板仍压在残骸后、残骸仍可见、行动员身体在残骸前。

诊断期间的 `--probe` 分支只用于以上单变量试验，已从最终捕获工具移除；永久回归只运行生产死亡/输入路径并比较实际渲染像素。

## 根因

`Level` 将 `Operative` 分支放在 `Enemies` 分支之前；双方画布层级默认为 0，Godot 按分支顺序合成时后画出的敌人精灵覆盖行动员。`MechanicalSoldier.receive_hit()` 与 `DefenseMech.receive_hit()` 只切换死亡图帧，不为残骸安排独立绘制深度。把残骸单独降到 -1 也不安全，因为当前背景和甲板同为 0，会将它们遮掉。修复须让环境继续在残骸后、行动员继续在残骸前，并只在敌人死亡时生效。

## 修复后回归

绘制层级由各自所有者负责：正式场景在初始配置中把六个机库背景节点设为 z=-3，把 Ground 设为 z=-2；机械兵或防御机甲死亡时只把自己的 Sprite 设为 z=-1。行动员和存活敌人维持 z=0。敌人脚本不再查找或修改关卡背景节点。重试重载场景后，背景/甲板仍保持正式场景的静态深度，机械兵与防御机甲 Sprite 恢复为 z=0。

真实渲染捕获现通过 process-frame 节拍器补足每帧到 16,667 微秒；与 `--fixed-fps 60` 配合，避免固定步长在无节拍时高速模拟。左右移动各采集 27 张原生 640×360 帧，PNG 写盘在运动采样后执行。

像素回归命令：

```powershell
Godot_v4.7.2-stable_win64_console.exe --path . --audio-driver Dummy --rendering-method gl_compatibility --fixed-fps 60 --script tools/capture_issue_34.gd -- --enemy soldier --output res://docs/art/issue-34/after/soldier-standing
Godot_v4.7.2-stable_win64_console.exe --path . --audio-driver Dummy --rendering-method gl_compatibility --fixed-fps 60 --script tools/capture_issue_34.gd -- --enemy mech --output res://docs/art/issue-34/after/mech-standing
python tools/present_issue_34.py
```

修后机械兵站立 `243/243`、向右跑 `124/124`、向左跑 `170/170` 的可判读重叠像素均由行动员获胜；残骸各有 673 个可见像素。移动的 26 个物理帧分别耗时 423.607ms 与 429.154ms，平均每物理帧 16.293ms 与 16.506ms。机甲站立重叠为 `801/801`，残骸有 3315 个可见像素；正式胜利 HUD 保持可见。重试后静态世界层维持 -3/-2，机械兵与机甲恢复 z=0。

另以提交 `d309625` 的场景渲染为参照，在 30 帧真实节拍后分别捕获背景、存活机械兵、行动员及两者同屏。重构后的四张 640×360 图片相对参照都为 0 个变化像素。两次测量的平均 process-frame 间隔为 16.566ms 和 16.647ms。对照图、层级 JSON 和复现说明位于 [`scene-config-comparison`](../../art/issue-34/scene-config-comparison/README.md)。

原生图：修前机械兵 [combined.png](../../art/issue-34/before/soldier-standing/combined.png)、修后 [standing.png](../../art/issue-34/after/soldier-standing/standing.png)、[move_right.png](../../art/issue-34/after/soldier-standing/move_right.png)、[move_left.png](../../art/issue-34/after/soldier-standing/move_left.png)；原速循环：[walk-right-loop.png](../../art/issue-34/after/soldier-standing/walk-right-loop.png)、[walk-left-loop.png](../../art/issue-34/after/soldier-standing/walk-left-loop.png)。修前机甲 [combined.png](../../art/issue-34/before/mech-standing/combined.png)、修后 [standing.png](../../art/issue-34/after/mech-standing/standing.png)。机甲截图保留正式胜利 HUD；其身体层级结论来自截图上逐像素合成比较。
