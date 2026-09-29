# 验证记录 · 2026-09-29

## 人审返工复验

返工基线 `46d09b48e760ba18f69c7d0acf5c2ff9a03dd653`，修复提交 `3004d42`。

- 回归信号：旧图集充能环范围为 32×26，新增完整比例断言在旧产物上失败；改用实际末行裁切后为 32×32，通过。新增机械兵发射瞬间截图的枪口暖色像素检查，限定 y=215 的实际枪口区域，避免再次落到旧 y=234 高度。
- 重新构建、Godot 原生 640×360 采集、两段 4 秒 GIF 编码及全部素材验证通过；原始生成源图未修改，图集前七行未修改。
- 28 个现有 SceneTree 行为检查均打印 PASS、退出码 0；与初版相同的 6 项存在退出资源清理 ERROR，不能称日志全部无错误。
- Python 发现全部 12 项：11 项通过，1 项外部打包端到端因本票仅允许写入指定 worktree 而显式跳过（其工具要求项目外输出）。没有改动测试文件。此前协调会话已在初版干净提交完成过 12/12，见 [议题复核](https://github.com/immorcoding/hundouluo/issues/26#issuecomment-5883083253)；该结果不冒充本次返工测试。
- Standards 复审：0 明确违例、0 待改 smell；Spec 复审：0 阻塞发现，确认枪口贴合、环完整、文件范围正确。Spec 建议在人审评论特别提示机甲短暂下移仅为美术提案。正式运行逻辑、场景与旧图集未改。

## 初版记录（历史）

基线 `6b4505ae6910f77b10137ee2fa98fc504d7a7cd2`；Godot 4.7.2，OpenGL compatibility，NVIDIA RTX 4060 Laptop GPU。

- `verify.py`：通过。源 alpha、32 个非空帧、边距、元数据、640×360 截图与 4 秒循环。
- 实际图形视口采集：普通交火与机甲战各 48 帧成功，另保存蓄力静帧。
- 所有 28 个 `extends SceneTree` 的现有 Godot 检查已执行，各自打印 PASS。6 个完整关卡检查退出时有 `resources still in use at exit`：level_boss_wiring、level_enemy_fire、level_feedback、level_operative_wiring、level_outcomes_retry、level_progression。严格按无 ERROR 日志口径是 22/28；不得称完全无警告通过。这些检查与被测运行文件均未改动，本票不修复其退出清理。
- `python -m unittest discover -s tests -v`：12 项执行，11 项通过，1 项打包端到端失败。打包工具拒绝未提交的工作树，并要求将 OutputDirectory 放在项目外。本票只允许在指定 worktree 写入，因此不另建外部打包输出。预检已通过；不能宣称打包测试通过。
- 正式关卡脚本、场景、HUD、角色与环境图集相对基线无改动。Godot 导入改写的旧 `.import` 文件已恢复，仅提交本票两个独立目录。
- 本票为生成辅助美术与预览，无正式行为修改，没有为低风险制图脚本引入 TDD 流程。
- 仍需用户按 1× 静音审看小弹丸与机甲蓄力；尚未完成新美术的真实玩法接入、手感或舒适度验收。
- code-review 两路审查：Standards 无明确标准违例，Spec 素材及范围符合要求；两路均发现干净检出缺少 `frames/` 会导致重建失败，已在采集入口自动创建目录并检查返回值，重新采集和素材验证通过。README 代码块、引号与反引号完整。
