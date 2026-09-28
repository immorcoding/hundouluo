# 轨道基地 · v0.1.0 工程入口

本仓库是正式的 Godot 4.7.2 标准版 / GDScript 源项目，与 `.scratch/` 中的抛弃式手感灰盒分开。当前提交只完成 [Issue #13](https://github.com/immorcoding/hundouluo/issues/13) 的工程与输入骨架：主场景可运行，但行动员、战斗、关卡内容和 HUD 尚待后续票据接入。启动后看到深色背景是预期结果，并非已可游玩的关卡。

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

移动、跳跃、射击分别使用独立动作，可以同时按住；当前还没有行动员脚本，因此按键暂不会驱动画面。不同实体键盘可能有 ghosting，真实按键组合须在后续试玩中复核。

## 关卡接缝

唯一主场景 `scenes/level.tscn` 保留 `Operative`、`Enemies`、`Projectiles` 三个 2D 实例槽，以及屏幕空间的 `HUD` 槽。后续票据可在这些位置接入各自独立场景，关卡统筹流程；现有空节点不是角色、敌人或弹丸实现。`Camera2D` 目前只固定显示入口画面，后续关卡票据负责跟随与五段布局。铺满窗口的背景仅用于确认项目渲染；基础分辨率、缩放与像素渲染方式留待视觉和手感原型确定，不继承灰盒参数。

## 检查

在项目根目录分别运行：

```powershell
& '<Godot 4.7.2 console.exe 路径>' --headless --path . --script tests/project_smoke.gd
& '<Godot 4.7.2 console.exe 路径>' --headless --path . --script tests/input_smoke.gd
& '<Godot 4.7.2 console.exe 路径>' --headless --path . --script tests/scene_slots_smoke.gd
```

这些检查验证入口资源、输入映射及已约定的场景槽位；它们不等同于真人试玩或后续票据的行为验收。
