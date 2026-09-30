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

最终层级设置只在真实敌人死亡时运行。背景降到 -3、整段甲板降到 -2、尸体 Sprite 降到 -1；行动员和仍存活的机械兵维持原来的 0。死亡组件仍留在原位置，使用原 Sprite 节点和死亡帧，不改碰撞、攻击、伤害或美术素材。场景重载会自然恢复全部默认层级。

像素回归命令：

```powershell
Godot_v4.7.2-stable_win64_console.exe --path . --audio-driver Dummy --rendering-method gl_compatibility --fixed-fps 60 --script tools/capture_issue_34.gd -- --enemy soldier --output res://docs/art/issue-34/after/soldier-standing
Godot_v4.7.2-stable_win64_console.exe --path . --audio-driver Dummy --rendering-method gl_compatibility --fixed-fps 60 --script tools/capture_issue_34.gd -- --enemy mech --output res://docs/art/issue-34/after/mech-standing
python tools/present_issue_34.py
```

修后机械兵站立 `243/243`、向右跑 `124/124`、向左跑 `170/170` 的可判读重叠像素均由行动员获胜；三态残骸各有 673 个可见像素。两次相同命令给出相同结果。机甲站立重叠为 `801/801`，残骸有 3315 个可见像素。活动状态的机械兵及行动员精灵仍在 z=0；R 重试后背景、甲板、机械兵和机甲均恢复原始状态。左右各保留 27 帧、约 60 Hz 的原生 APNG 短循环。修前/修后的背景比较图在两类场景下均为 0 个变化像素，确认没有重绘或移动美术。

原生图：修前机械兵 [combined.png](../../art/issue-34/before/soldier-standing/combined.png)、修后 [standing.png](../../art/issue-34/after/soldier-standing/standing.png)、[move_right.png](../../art/issue-34/after/soldier-standing/move_right.png)、[move_left.png](../../art/issue-34/after/soldier-standing/move_left.png)；原速循环：[walk-right-loop.png](../../art/issue-34/after/soldier-standing/walk-right-loop.png)、[walk-left-loop.png](../../art/issue-34/after/soldier-standing/walk-left-loop.png)。修前机甲 [combined.png](../../art/issue-34/before/mech-standing/combined.png)、修后 [standing.png](../../art/issue-34/after/mech-standing/standing.png)。机甲截图保留正式胜利 HUD；其身体层级结论来自截图上逐像素合成比较。
