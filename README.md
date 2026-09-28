# 轨道基地 · v0.1.0 工程入口

本仓库是正式的 Godot 4.7.2 标准版 / GDScript 源项目，与 `.scratch/` 中的抛弃式手感灰盒分开。工程和输入骨架已具备；行动员的移动、射击、受击模块已接入主场景，但地形、敌人、正式关卡、HUD 和死亡重试仍属后续票据。主场景现在没有地面，不能当成可游玩的关卡；下方无界面行为检查提供可重复的模块验收。

## 打开与运行

1. 使用 Godot **4.7.2 标准版**，在项目管理器选择本目录中的 `project.godot` 导入。
2. 在编辑器按 **F6** 运行当前 `scenes/level.tscn`，或按 **F5** 运行配置好的主场景。
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

唯一主场景 `scenes/level.tscn` 保留 `Operative`、`Enemies`、`Projectiles` 三个 2D 实例槽，以及屏幕空间的 `HUD` 槽。行动员实例位于 `Operative` 槽，通过 `projectile_fired(projectile)` 信号交由关卡放入 `Projectiles` 槽；不操作 HUD 或镜头。行动员公开 `health`（初始 3）、`receive_hit()`、`health_changed(health)` 与 `died()`，敌弹和接触的后续实现均可调用同一个受击入口。短暂无敌由行动员自行判定。己方弹丸对具有 `receive_hit()` 的碰撞对象提交一次命中后消失；未命中也会在有限距离后消失。

碰撞层约定：行动员为第 1 层、普通敌人/受击目标为第 2 层、地形为第 3 层、己方弹丸为第 4 层。行动员检测敌人和地形，己方弹丸检测敌人和地形；后续敌人与关卡按此接缝布置。跑速、跳跃速度、射击间隔、无敌时长和弹丸速度/距离均是场景可调参数，不视为已完成真人手感验收。`Camera2D` 目前固定，后续关卡票据负责跟随与五段布局。

## 检查

在项目根目录分别运行：

```powershell
& '<Godot 4.7.2 console.exe 路径>' --headless --path . --script tests/project_smoke.gd
& '<Godot 4.7.2 console.exe 路径>' --headless --path . --script tests/input_smoke.gd
& '<Godot 4.7.2 console.exe 路径>' --headless --path . --script tests/scene_slots_smoke.gd
& '<Godot 4.7.2 console.exe 路径>' --headless --path . --script tests/operative_behavior.gd
& '<Godot 4.7.2 console.exe 路径>' --headless --path . --script tests/operative_shooting.gd
& '<Godot 4.7.2 console.exe 路径>' --headless --path . --script tests/friendly_projectile_hit.gd
& '<Godot 4.7.2 console.exe 路径>' --headless --path . --script tests/friendly_projectile_expiry.gd
& '<Godot 4.7.2 console.exe 路径>' --headless --path . --script tests/operative_damage.gd
& '<Godot 4.7.2 console.exe 路径>' --headless --path . --script tests/level_operative_wiring.gd
```

首次在新目录运行脚本前，先用 `--headless --editor --path . --import` 导入 PNG。检查覆盖入口、输入和槽位，以及行动员跑跳、左右连续射击、弹丸单次命中与清理、受击无敌和死亡信号；它们不等同于真人试玩或正式关卡验收。
