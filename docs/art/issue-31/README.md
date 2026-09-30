# #31 统一集成与 v0.1.1-rc.1 工程验收

工作树 `E:\Projects\game_hundouluo_codex_worktree\issue-31-v011-acceptance`，分支 `codex/issue-31-v011-acceptance`，基线 `3401e62334f42d829a59592dcb6f67634c774d78`。本轮实际 turn_context（2026-09-30T10:40:40.36Z）为 `approval_policy=never` / `danger-full-access` / `gpt-6.1-sol`。源代码、资源加工、测试和临时源码副本均在该 E 盘 worktree。最终交付在 `E:\Projects\game_hundouluo_codex_artifacts\v0.1.1-rc.1`，不是可清理的工作树。

此候选是工程收口，不宣布人工验收通过。#31/#25 保持 OPEN，未合并 main，未创建 tag/release 或关闭 milestone。源码和可玩包的精确 commit/文件名/SHA256、最后严格检查在交付目录 `DELIVERY.md` / `verification/`；它们指向同一个最终干净提交，避免构建后再改源码造成包与提交不一致。

## 设计闸门与批准溯源

GitHub原生依赖 #29/#30/#33 全部 CLOSED；#26/#27/#32 设计票 CLOSED，获批资产已顺序合并。完整读取 #31/#25 及设计/工程票的正文、评论。部分设计票最终待审评论后由用户直接关闭，GitHub未额外补最后一句人审，不能据旧评论误称未批准，也不编造新的用户审美结论。

可信人类原始记录在协调会话 `01a0e758-f953-78e2-8008-3e848c610833`：2026-09-29T08:23:25.875Z 用户明确说“这三个我都close掉了，你先合并到主分支”，上下文即 #27/#29/#32；#26设计已先关闭，#29接入采用批准的 `afc81bd`、环修订 `3004d42`。2026-09-29T07:37:06.291Z 用户说“左边这个图好看点…暂时先收口”，#27 S6部分批准另在 [5885875724](https://github.com/immorcoding/hundouluo/issues/27#issuecomment-5885875724) 归档。结算冻结 `4c009ad`，S6 `2092f70`，门 B-left16 `880af1d`。2026-09-29T07:07:20.915Z 用户将进入机甲战后锁镜头明确交给后续工程票；#33接入与公平性复核后已合并。这些局部批准均不代替本轮整包人工验收。

## 跨线接线审查

- `level.tscn` 五个 2D槽/HUD子树保留，三类弹丸通过 projectile_fired进入同一 Projectiles，保持世界坐标；impacted接CombatFeedback，信号只传事实，HUD只展示。41条唯一运行资源引用全部存在。
- 42HP/420px机甲保留1s蓄力、0.22s三发间隔、2.4s恢复的单一循环。机械兵归零关闭伤害/攻击、保留帧6惰性残骸；R重载整场恢复。
- 行动员/机甲图锚点和地面y252不变。门图与14×148屏障同步x3396，y104..252；末行y263为装饰。x3463进入/退避阈值、0.22s警告不变，闭门固定中心x3580。止退约3415.075，420px射程余量约5.075px；完整机甲右侧余量6px，后续不能随意再移门/锚点。
- S6仍192×68、左下6px；结果态隐藏战斗HUD，生命/机甲进度、两死因、胜利与R契约保持。没有枪械切换、库存、倒计时、新攻击或新关卡。

## 诊断及最小修复

[cleanup-results.json](cleanup-results.json) 保留五项fixture修前/后精确诊断。原断言全部PASS、退出0，但verbose证明 AudioStreamWAV及AudioStreamPlaybackWAV仍占用：tuning=蓄力、boss_wiring=敌射/蓄力、enemy_fire=敌射、operative_wiring=己射、progression=跌落。仅补释放level、处理帧/100ms音频退出等待、延后quit；首帧operative发射先多处理一帧。没有改正式音效/玩法、不放宽断言、不过滤ERROR当成功。

首次完整合法模拟另外暴露真实弹丸碰撞致死/胜利时 `_stop_gameplay` 直接禁用CollisionObject的错误。既有 `level_outcomes_retry.gd` 扩展到真正敌弹致死与正常J输入最后一弹击败机甲；修前两条 `_apply_disabled` ERROR，修后无诊断。只将四个玩法子树process_mode改为set_deferred，状态/结果立即确定，碰撞层/掩码原延后保护保留；原冻结/重试断言仍通过。

Windows公开包边界TDD：既有端到端检查增加本轮验收单/已知事项/引擎通知及说明版本要求。在干净E盘源码副本上，旧脚本真实产包后因缺少 `docs/acceptance-v0.1.1.md` 失败（不是工作树保护的伪红）。打包脚本补齐这些内容，并在退出码之外检查Godot错误/警告。完整源/可玩包同时随附项目MIT、完整字体OFL/上游通知、实际Engine API引擎及第三方许可。

## 实机与自动模拟证据

`capture-results.json` / `simulation-results.json` 记录fixture设置、实际生命/发弹/门/镜头/时序；原生PNG和无损原速 `*-loop.png` APNG均为正式场景渲染，没有后期抹图或重绘资源。`presentation-results.json` 核验640×360、动画时长与逐帧无损。图形脚本固定60Hz；fixture中的传送/直接受击仅用于指定状态，记录逐项披露。

`legal-run-loop.png` 是低采样率原速全关模拟，`legal-victory.png` / `legal-retry.png` 展示真弹丸通关和物理R恢复；从正常起点开始，只用移动/跳跃/射击/R，没有传送、直接伤害、无敌或数值调整。策略按已知地面坐标和可观察敌弹位置安排输入，比真人首次反应更理想。

自动机甲战约7.27秒，较30秒下限少22.73秒、较45秒上限少37.73秒；42有效命中、胜利剩1生命，明确远低于目标区间。旧42HP×约1有效命中/s模型推算42秒与此自动策略差异很大。**真实首次成功时长未测**，不为了模拟达到目标改数值；用户应在 [人工记录单](../../acceptance-v0.1.1.md) 判断是否调参。

静音检查使用形状/运动证据：己弹短青白、机械兵小橙红、机甲较宽低位三发；枪口预告/蓄力环/下降灯及屏障先于危险。贴门等待与一帧探身再退回均产生真实敌我命中，闭门推进固定镜头。PNG/APNG不证明真人阅读舒适或听感，声音由用户验收。

获批画面对照在当前集成场景重新运行#30/#33既有oracle（仅将输出重定向到被忽略的E盘目录）。`approved-ui-comparisons.json`的13态超出既有局部采样/量化容差的像素均0；`approved-gate-comparisons.json`四次门源替换渲染逐像素相同，未放宽容差。实际弹丸敌人/墙面碰撞补图为`impact-enemy-hit.png` / `impact-wall-hit.png`，枪口/完整环与低位三发在`impact-*.png`。这些仅设初始位置/创建真实弹丸，不伪造命中。

## 最后检查与复现

运行 `tools/check_issue_31.py --godot <4.7.2-console> --output <日志目录> --temp <E盘临时目录>`；对干净最终提交的隔离E盘副本执行（temp在副本外、仍在本worktree），完整枚举所有extends SceneTree脚本、Python全部检查、导入、主场景headless与有图形90帧。严格要求每项exit0且无ERROR/SCRIPT ERROR/WARNING；完整日志、准确测试数和tested_commit留在交付verification。定点修复日志为上面的red/green证据；后续不无理由重复全套。

运动采集：`Godot ... --path . --rendering-method gl_compatibility --fixed-fps 60 --script tools/capture_issue_31.gd`，然后 `python tools/present_issue_31.py`。raw frames保留在本worktree被忽略目录，精选静图/APNG入源码；APNG为证据动画，不是新运行素材。

补图复现：`Godot ... --path . --rendering-method gl_compatibility --fixed-fps 60 --script tools/capture_issue_29.gd -- --output-prefix res://docs/art/issue-31/impact-`。既有工具只增加输出位置与正确退出清理，默认旧证据位置保留。

独立双轴审查见 [code-review.md](code-review.md)。整体像素风逐项审视见 [style-audit.md](style-audit.md)，公开人工清单/已知问题随包。工程阻塞与用户需判断项目明确区分；未尝试清理被自动策略拒绝的#33旧worktree/cache。
