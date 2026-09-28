# #17 防御机甲组件与接线记录

本分支只提供独立组件和 `tests/defense_mech_encounter.tscn` 平地试验场；正式关卡终点、HUD、通关门槛须待 #16 合入后接线。本记录不是 30–45 秒真人试玩验收。

## 接线接口

- 实例化 `res://scenes/defense_mech.tscn`，脚本全局类 `DefenseMech`，原点是脚底中心；放在无缺口的终点平地上。图集为现有原创 `assets/pixel/defense_mech.png`，单帧 136×90，受击 `Body` 为 88×80（机械兵 20×40）。静止机甲使用敌人碰撞层 2，己方弹丸的既有命中逻辑会调用 `receive_hit()`。接触 `Area2D` 仅在完整入镜激活后向行动员的 `receive_hit()` 提交伤害；行动员自身负责短暂无敌。
- 关卡把 `mech.target` 设为行动员；连接 `projectile_fired(projectile: Area2D)`，先保存未入树弹丸的 `global_position`，放入关卡 `Projectiles` 后恢复该位置，与机械兵及行动员的接线方式相同。敌弹仍用现有第 5 层，只伤行动员和地形。
- 每个物理帧用镜头当前世界坐标矩形调用 `mech.update_visibility(view_rect: Rect2)`。矩形可按 `Camera2D.get_screen_center_position()`、`get_viewport_rect().size / zoom` 计算，完整示例在独立 fixture 的 `tests/defense_mech_encounter.gd`。它只在整个 136×90 图集帧进入镜头后令 `attack_enabled` 为真；离镜取消尚未完成的弹丸组，再入镜重新蓄力。未完整入镜不能 `receive_hit()`，防止从屏外用长射程己方弹丸磨血；入镜后在蓄力、发弹和空档全程可受击。
- `health` / `max_health` 供 HUD 初始化进度；每次有效命中发 `health_changed(health: int)`，归零再发一次 `died()`。关卡通关条件应监听 `died()`，不可仅靠抵达终点触发。死亡保留倒地帧并停止攻击；重新实例化场景即复位生命和攻击状态。

## 试玩前参数初值

| 场景脚本导出参数 | 初值 | 意图 |
| --- | ---: | --- |
| `max_health` | 120 | 机械兵 3 点；不设置无敌阶段，需通过真人试玩调整。 |
| `attack_range` | 420 px | 完整入镜且行动员进入平地战区后才预告。 |
| `charge_duration` | 1.00 s | 图集两张蓄力帧交替，并以低位橙色枪口作静音预告。 |
| `shot_spacing` | 0.22 s | 一组三发既有敌弹，水平向左从脚底上方 18 px 发射。 |
| `recovery_duration` | 2.40 s | 最后一发后不发弹，供躲避后连续射击。 |

整轮约 3.84 秒（1.00 + 0.44 + 2.40）；行动员目前连射间隔 0.16 秒，假设每发都命中，120 点生命的理想下限约 19 秒。若实际射击命中/空档利用率约一半，战斗可能落在 30–45 秒附近，但这是调参假设，**不是**测试结果。#16 的最终地形、镜头与玩家真人试玩后应记录实际耗时、被击次数和失败原因，再调整生命、预告、弹组与空档。不要用脚本倒计时硬性强制时长。

可运行 `tests/defense_mech_encounter.tscn` 单独观察；自动检查为 `tests/defense_mech_behavior.gd`、`defense_mech_cycle.gd`、`defense_mech_damage.gd`、`defense_mech_dodge.gd`、`defense_mech_contact.gd`。它们验证组件接口与低弹规避，不验证正式关卡通关、HUD 或真人手感。
