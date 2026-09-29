# 验证记录 · 2026-09-29

基线 `6b4505ae6910f77b10137ee2fa98fc504d7a7cd2`；Godot 4.7.2，OpenGL compatibility，NVIDIA RTX 4060 Laptop GPU。

- `verify.py`：通过。源 alpha、32 个非空帧、边距、元数据、640×360 截图与 4 秒循环。
- 实际图形视口采集：普通交火与机甲战各 48 帧成功，另保存蓄力静帧。
- 所有 28 个 `extends SceneTree` 的现有 Godot 检查已执行，各自打印 PASS。6 个完整关卡检查退出时有 `resources still in use at exit`：level_boss_wiring、level_enemy_fire、level_feedback、level_operative_wiring、level_outcomes_retry、level_progression。严格按无 ERROR 日志口径是 22/28；不得称完全无警告通过。这些检查与被测运行文件均未改动，本票不修复其退出清理。
- `python -m unittest discover -s tests -v`：12 项执行，11 项通过，1 项打包端到端失败。打包工具拒绝未提交的工作树，并要求将 OutputDirectory 放在项目外。本票只允许在指定 worktree 写入，因此不另建外部打包输出。预检已通过；不能宣称打包测试通过。
- 正式关卡脚本、场景、HUD、角色与环境图集相对基线无改动。Godot 导入改写的旧 `.import` 文件已恢复，仅提交本票两个独立目录。
- 本票为生成辅助美术与预览，无正式行为修改，没有为低风险制图脚本引入 TDD 流程。
- 仍需用户按 1× 静音审看小弹丸与机甲蓄力；尚未完成新美术的真实玩法接入、手感或舒适度验收。
- code-review 两路审查：Standards 无明确标准违例，Spec 素材及范围符合要求；两路均发现干净检出缺少 `frames/` 会导致重建失败，已在采集入口自动创建目录并检查返回值，重新采集和素材验证通过。README 代码块、引号与反引号完整。
