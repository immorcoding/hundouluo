# #31 v0.1.1-rc.2 增量集成证据

基线main `148d74f9069c80bed7f1f7f0cfc471b814815fbb`；工作树 `E:\Projects\game_hundouluo_codex_worktree\issue-31-v011-acceptance`，分支`codex/issue-31-v011-acceptance`。实际本轮权限记录2026-09-30T15:14:03.138Z为danger-full-access/never、gpt-6.1-sol。主目录代理/领域配置只读沿用，已setup；所有源码、证据加工、测试、临时独立Git克隆都在该E盘工作树，旧#33/#34/#35工作树不清理。

## 人工验收承接

[原文存档](rc1-human-record.md) 与 [GitHub人审](https://github.com/immorcoding/hundouluo/issues/31#issuecomment-5911543601) 已通过其他全部项；真人机甲战只记录“时间差不多”，保留原话不造具体秒数。rc.1包/用户填写记录保留。本轮仅#34残骸遮人、#35跑射枪口亮点错位，附必要通关/R防退化，[复测单](../../retest-v0.1.1-rc.2.md) 不重开旧美术、声音、手感或平衡验收。

两个bug已由协调复核合入main：#34 `b50d28c5fa16c617bcfd3946c9d1a4c30a943506`，#35 `86e2fd49ca3fdb435ba566e02803ce2a8f3b43bb`。原生依赖#34/#35仍OPEN/ready-for-human是用户复测闸门，不阻止为已合并修复打包。#34/#35/#31/#25均保持OPEN，不合并main、不创建tag/release/封milestone，交协调最终复核。

## 同一正式关卡的交叉核查

- #34场景拥有背景z=-3/Ground=-2；归零只改敌人自身Sprite=-1，行动员/活敌0。残骸惰性保留到R，未重排门/HUD/弹道的既有序。
- #35已有200ms短帧挂行动员Muzzle，随可见枪姿/朝向同步；弹丸仍独立520px/s及原射程，死亡隐藏Muzzle，物理即刻同步覆盖胜利前变向冻结。没有新位图/声音/字体/许可依赖。
- 当前增量不改正式scripts/scenes/assets；机甲42HP/420射程、1s蓄力/原三弹循环、x3396门/14×148/y263装饰、x3463阈值/0.22s警告、x3580闭门水平镜头、三生命/原射速/R规则保持。版本仅app0.1.1-rc.2、Windows数值0.1.1.2。

## 固定实现的实际渲染

`f17973ccc3e4cb7f25e0a6eb2587996a9517a09c`固定实现上最后重跑Godot/Python均实际exit0，完整原始日志 [capture.log](capture.log)、[presentation.log](presentation.log)，无ERROR/SCRIPT ERROR/WARNING。[run-record.json](run-record.json) 记录前后HEAD/源码状态、argv/条件/工具和日志SHA256；前后tracked diff为空，只有本目录生成。后续差异为证据/审查文档，不混构建；最终构建与全量检查均使用同一最终干净提交，精确commit/日志在持久交付DELIVERY/verification。

640×360 OpenGL/Compatibility，物理60Hz、固定显示60fps、每process_frame明确等待17ms给混音真实时间。两条真实Input运动APNG各180帧/60fps/3s，Python逐帧像素及准确时长验证无损。全关录像每12物理帧抽样，116帧/5fps，明确是抽样录像，不冒称60fps。

| 证据 | 核查结果 |
| --- | --- |
| 四层组件：站立、右跑姿、左跑姿、机甲倒地 | 可判读重叠243/243、130/130、97/97、1154/1154均行动员前景；尸体仍有673/3687可见像素。跑姿组件是公开Sprite设姿的静态fixture，实际左右移动由Input录像另证，不伪称运动像素probe |
| [corpse-follow-loop.png](corpse-follow-loop.png) | 残骸、枪口、独立弹道与HUD同屏，左右连射/变向/跳跃/受击；镜头实际x825.533..1000.533移动 |
| [gate-fixed-loop.png](gate-fixed-loop.png) | 门/HUD/枪口/敌我弹道同画面，实际输入封门后camera min=max3580 |
| 可见枪口/新生/飞行 | 428个实际短帧样本<=1px锚点误差；新生弹丸对可见枪管端点<=1px；1717独立飞行样本最大误差0.003662px（允许0.05px累计浮点误差） |
| [legal-run-loop.png](legal-run-loop.png) / legal-victory、legal-retry | 正常起点仅合法Input全关，五兵全灭、42机甲有效命中、剩一生命胜利，物理R恢复140起点/三生命/42机甲；机甲模拟7.2667s，仅防退化，不替换已人审时间 |
| victory-freeze/fixture-retry | 终局冻结与R状态通过；最后机甲fixture以公开receive_hit准备结局并传送重叠，明确不是另一条真人或合法Input完整通关 |

初始传送/公开受击/组件可见性与设姿均在capture-results.json披露；未调用生产私有方法控制状态。BARRELS字面量来自既有获批枪管端点，未用生产muzzle_offsets算预期。[presentation-results.json](presentation-results.json)区分几何/飞行证据与像素probe；#35原三帧低置信atlas probe保持inconclusive，不改写为通过。两次辅助fixture错误（类型推断、机甲局部/世界坐标）原始日志保留E盘.godot，修后才记录成功。

## 完整检查的统一条件与默认失败

统一入口`tools/check_issue_31.py`递归解析继承：43直接SceneTree+1继承式operative_running_muzzle=44；两Node2D为独立场景fixture，不直接--script。未知/缺失/循环继承明确失败，不静默漏测。#34/#35历史入口转发。开始拒绝脏树，末尾记录HEAD/status/归一内容与staged diff；只允许已说明的.import行尾/stat标志，绝不stage掩盖真实源码改变。

正式完整条件`--clock paced`：原测试/全部断言不动，继承wrapper先连接process_frame17ms墙钟再调用原_initialize；固定模拟60fps，operative_muzzle_victory保持脚本120Hz物理/CLI30fps显示特例。Python18项/Windows端到端先消费未导入的原封干净Git提交，再导入和44Godot，另有两主场景90帧启动，合计48条。退出、PASS记录（含PASS passage）及全部诊断同时作闸门，不跳过/过滤。

默认合并定点在4ab438b：tuning exit0/PASS但2条WAV/playback退出诊断；其余本次所选boss/gap/progression无诊断，不能据此将以前默认失败抹掉或宣告默认全套通过。同副本还缺旧34工具UID，结束source-state门禁据实失败；该UID已作为缓存身份入实现提交。默认四项原始日志/results仍以strict_pass=false保存，历史#34/#35默认相机/音频失败原文继续保留。

实现f17973c的六项定点（以上四个+继承式running_muzzle+120/30victory）在paced条件全部无诊断通过；complete_suite=false明确不是全套。包契约TDD先在4ab干净克隆真实产包后因缺“两项复测单”失败，补入包文件/人审承接BUILD_INFO后在f179干净克隆2/2通过，保留红/绿原始日志。

最终完整48条、Windows内嵌包、全新解压实际进程与源码独立导入/Git核对、所有SHA256留在`E:\Projects\game_hundouluo_codex_artifacts\v0.1.1-rc.2`的DELIVERY/verification（创建前再核对无既有目录）；不以这里的早期定点替代最终结果。原始日志尾部空行保留，普通git diff --check若因此报空行会单独记录，不假称全部无格式诊断；代码与非日志文档检查单列。独立两轴审查见code-review.md。
