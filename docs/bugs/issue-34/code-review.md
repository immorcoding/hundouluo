# #34 增量代码审查

审查固定点：`d309625de50a167af83b550402da220411b1e16d`。两位审查者分别检查 Spec 与 Standards；审查对象是本次场景层级归属重构、回归测试、捕获工具和诊断证据。

## Spec

无可执行发现。`scenes/level.tscn` 的背景/甲板静态层级由 #34 独占；敌人死亡只降低自身 Sprite。改动覆盖背景与存活同屏画面的前后对照、残骸可见、站立/左右穿越、机甲胜利 HUD 和 R 重试恢复，未改玩法、HUD、门或相机规则。

## Standards

- 硬性规范违反：0。
- 剩余工具正确性问题：0。
- 非阻塞 smell 判断：`tools/capture_issue_34.gd` 和 `tools/capture_issue_34_scene_depth.gd` 各自保留局部实时节拍器，存在小段重复。按本次约束没有再引入共享模块。

首轮 Standards 审查发现全量运行器可能在脏工作树上把结果归到旧 HEAD。`tools/check_issue_34_paced.py` 现在先检查 `git status --porcelain`，只有干净提交才会记录 `tested_commit`；审查者复核该改动后确认此工具正确性问题已解决。
