# #36 枪口火光接缝与枪身合成

规格：[GitHub #36](https://github.com/immorcoding/hundouluo/issues/36)，完整正文快照见 [spec.md](spec.md)。基线 `eec9adfbf4fc045a24ab7630f26318907d7367c7`。只在 `E:\Projects\game_hundouluo_codex_worktree\issue-36-muzzle-flash-compositing` 实施；本票保持 OPEN，交协调集成后由用户在新候选中复测。

参考包 BUILD_INFO 实际读取为 rc.2 / `fc3cf32c1990852b0866c91c9c2f922996bf324a`；基线 tree 与它相同。没有据此断言用户实际启动了哪个文件。本轮启动的是基线源码的正式 level 场景，Godot `4.7.2.stable.official.ed1daf0bf`、OpenGL / RTX4060、真实 640×360 绘制。

## 红色反馈环与最小化

已实际执行的快速命令：

```powershell
& (Get-Command Godot_v4.7.2-stable_win64_console.exe).Source --path . --rendering-method gl_compatibility --fixed-fps 60 --script tools/capture_issue_36.gd -- --ticks=1 --out=docs/bugs/issue-36/red-repeat1
```

最早的差分只隐藏行动员枪口短帧。普通 `Input.action_press("shoot")`、站立朝右、一个绘制帧即可红：枪身改变23像素，可见后沿向枪口内偏6px，exit1；连续三次相同，约1.5秒。无射击 exit0。两帧缩为一帧仍红；不需要跑动、跳跃、相机跟随或敌人参与。正式完整关卡和独立原速180帧循环均先保存，之后才最小化。最早判定把大于20RGB的变化视为明显可见；最终回归进一步检查所有实际像素差异。

`red-results.json` 与 `red-repeat*.log` 保留原始重复结果；`no-shot.log` 保留移除触发的结果。最早PNG后移入各目录的 `frames/`，原命令/trace保持不变。

## 排序假设与单变量探针

1. 图集中心与可见后沿不一致：仅平移火光应改善接缝。
2. 火光绘制在枪身前：仅置于角色后应消除枪身改变，但不保证接缝。
3. 姿态枪口点不正确：不同姿态应出现不同误差。
4. 弹丸也参与闪烁：仅排除弹丸应改变差分。

排序在本会话 commentary 公布后才运行探针。`probe-results.json` 和原始日志：置于角色后，枪身变化0但后沿仍内偏3px；仅平移6px，后沿对齐但仍改变2个枪身像素；隐藏弹丸，原火光差分仍为23像素/6px。两种因素都必须处理，弹丸不是火光差分的根因。

随后独立把无火光画面的枪管与批准角色原图比较，发现新生弹丸尾部还覆盖约14个枪管像素，首帧源图匹配74/88，而后续清空时88/88。因此仅修火光会保留另一种开火枪身变化；这是修改 friendly_projectile 的必要性证据。最终配对的无己方反馈画面同时暂时隐藏本轮真正发出的己方弹丸，敌方、背景、角色、镜头及其他效果保持同一冻结姿态。这种隐藏只存在于诊断测量，不在生产运行中。

## 根因与工程修复

- 四个48×40火光画格可见后沿是源图x `[18,14,17,18]`，原来画格中心x24直接落在枪口，后沿伸入枪管；画格0/2前面还有近乎透明的导出残留。
- 行动员创建的短帧启用专属接缝选项，逐帧偏移绘制区域，使可见后沿从当前枪口开始。专属采样裁掉后沿之前的导出残留，避免受击半透明枪身透出微弱火光；Muzzle在Sprite之前绘制，枪身在前。
- 行动员发出的弹丸只在刚离开枪口时裁掉伸回枪管的绘制尾部。裁剪平面跟随当前公开Muzzle，弹丸中心超出20px即恢复普通绘制。半像素边界也裁掉，避免首帧仍压住3个枪口像素。
- 未移动枪身，未重绘或替换素材。弹丸的坐标、520px/s运动、960px射程、碰撞、伤害与0.16秒射击间隔未修改。通用 CombatFlash 与独立弹丸默认不启用上述选项。

生产范围仅 `scenes/operative.tscn`、`scripts/operative.gd`、`combat_flash.gd`、`friendly_projectile.gd` 与两个接缝 shader。正式 level、敌人、闸门、HUD、版本/打包文件均未改；背景-3/Ground-2/残骸Sprite-1/行动员与活敌0保持。火光仍完整可见于枪口外，保持原像素簇和色阶。

## 实际像素判定

预期来自人工检查批准的72×60角色画格枪管源像素。可见前缘源坐标依次为 `(64,22),(67,24),(67,24),(59,23),(57,23),(62,20)`；枪身掩码为各画格枪管矩形内不透明像素。回归不读取或重算生产 `muzzle_offsets`。

`_register_mask` 在无己方反馈的实际屏幕画面中，将角色原图枪身匹配到相邻四个栅格位置。这处理镜像/半像素边界的真实采样约定；早期简单取整曾使测试掩码偏一格，失败开发副本保留在 `.scratch/issue-36/`，没有改生产坐标来迎合掩码。正常未受击时要求源图匹配至少90%，防止采样到空背景；受击与结算遮罩按实际姿态使用同一掩码，差分仍要求0。

有反馈/无反馈图片均经过真实 `frame_post_draw`，暂停整个场景后才取第二张，确认姿态/屏幕位置未改变。枪身要求逐像素0变化；枪口周围13×29区间内的最靠后可见差分，距独立可见枪管前缘必须≤1px，1000的“完全不可见”哨兵直接失败。外沿发光在枪管掩码之外；不可用删火光或单纯z_index通过。

## 红→绿及兼容证据

同一个最终回归工具加入未经修改的基线 Git archive，只增加诊断工具，不修改其运行源码：

```powershell
python tools/check_issue_36.py --godot (Get-Command Godot_v4.7.2-stable_win64_console.exe).Source --baseline .scratch/issue-36/baseline
python tools/present_issue_36.py
```

`loop-results.json` 共18条：基线minimal/三种完整配对明确exit1，修后全部exit0；引擎诊断为0，合法PASS/FAIL与预期退出双门禁。站立、跑动、变向、双向起跳/落地、双向受击，跟随/固定镜头均通过。

| 正式场景 | 修前最大枪身变化 | 修前最大后沿误差 | 修后枪身变化 | 修后最大后沿误差 |
| --- | --- | --- | --- | --- |
| 起点 | 52像素 | 10px | 0 | 1px |
| 跟随镜头 | 51像素 | 10px | 0 | 0px |
| 固定镜头 | 51像素 | 10px | 0 | 1px |

修后三种配对各180个有火光画面、各214短帧。原始完整场景没有暂停测量，54发、642短帧、2783独立飞行样本，0失败；原#35节点跟随合同保持。终局使用公开设定初始传送/机甲受击降至1HP，真实Input赢弹碰撞前变向，120Hz物理/30fps冻结枪口；死亡使用公开受击fixture，胜利/死亡后均实体KEY_R重建并实际发射，枪身和接缝仍通过。

敌方及独立生成己弹的16帧前后原生PNG字节完全一致，覆盖左右方向、发射短帧、飞行及清理；默认效果合同未变化。

Python自动发现新增3项图形回归：站立接缝、三种镜头动作矩阵、真实终局/R。它们启动真实GL渲染，不能用headless坐标替代。完整全套结果在后续verification目录；本节定点结果不替代全套。

## 原生画面和原速循环

[修前/修后同姿态四图](native-paired-comparison.png)，上排开火、下排同姿态去己方反馈；[枪管像素放大辅助](gun-pixel-detail.png)。单独原生图为 `before-native-on.png` / `after-native-on.png`，均640×360。

六个 `before/after-original-{spawn,follow,fixed}-loop.png` 为真正无暂停的正式关卡180帧序列，每帧1/60秒、总3秒、640×360；解码逐帧与原始PNG逐像素一致，见 `presentation-results.json`。配对测量有额外暂停，未冒称它的播放速度是原速。完整原始PNG保留在本E盘worktree的各 `frames/`，未提交导入缓存。

固定/跟随fixture只在开头公开传送，随后关门与射击/移动/跳跃使用Input；tick125公开receive_hit使受击姿态确定。没有私有生产回调模拟成功，未调射速/血量/伤害。真实敌人交战、镜头、门/HUD都保留。

## 边界与保留记录

这仍是工程自动回归，不替用户最终视觉确认；本票与#34/#35/#31/#25保持OPEN，正式rc.3由协调随后制作。旧rc.1/rc.2、人审记录、其他worktree与#33缓存未删除。旧#35三个低置信atlas probe仍为inconclusive，本票不改它们。

默认旧fixture的相机/音频时序失败记录仍见 `docs/bugs/issue-35/clock-controls.json` 与 rc.2报告；完整检查沿用已披露paced条件，不声称默认全套通过。早期本票回归曾红于半透明残留、弹丸首帧覆盖、掩码取整和半像素裁剪边界，这些均在本会话逐项修正；相关开发图像/trace保留在 `.scratch/issue-36/`。最初archive未指定zip格式造成BadZipFile，改为显式 `--format=zip` 后才构建基线，不把失败副本当有效源。

首次完整检查74bcc83保留在 `verification-first-74bcc83/`：44 Godot与两种主场景均通过，但新增Python图形回归在统一入口的Python先行阶段缺少导入缓存，记录1024条诊断且失败；随后独立import异常退出3221225477，不能据其“完成导入”文本判通过。引擎异常本身未确定根因。本票新增测试现自行复制相同正式运行文件到TEMP中的独立fixture并先严格导入，原测试源码副本不受修改；证据目录用 `.gdignore` 排除出运行资源导入。没有改统一入口顺序或原测试断言。

默认时钟追加对照 `default-baseline/` 与 `default-implementation/` 分别从独立干净eec9adf与74bcc83 archive执行；本次两个定点（gap_camera、mech_tuning）都exit0/无诊断，属于subset，不推翻旧失败记录，也不代表默认全套通过。
