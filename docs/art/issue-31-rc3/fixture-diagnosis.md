# rc.3 固定镜头受击姿态覆盖诊断

首次固定完整检查提交134dd3385b7cc5aae5b029b9e29d921b0d5a1210：44 Godot、导入与两主场景均exit0零引擎诊断；21 Python中GL固定镜头矩阵报告`missing exercised pose 5:false`，Python实际exit1、strict_pass=false。不算通过，原始results/python及全部日志保留持久交付diagnostics/verification-first-134dd33。

按diagnosing-bugs先用失败的同一已导入独立fixture执行单镜头GL反馈环。3次原条件顺序、6次三并发重跑均绿，因此记录为时序敏感，没有把重试绿替代首次失败。诊断只读取公开health、Sprite与实际Engine.physics_frame。tick125公开receive_hit在这6次均health1→1，现存无敌期拒绝新受击；已有pose5不能证明这个调用成功。

排序预测：已有无敌期挡住强制受击导致右向hurt窗口缺席；配对暂停期间物理计数/恢复时序改变窗口；或角色早已死亡。只改变固定镜头初始等待，warmup额外0/4/12/16/20/24/28物理步，160采样步，12步变体独立复现相同`5:false`缺席。随后该12步变体连续3次exit1，tick125 health2→2/pose5；其余变体保留真实绿，不挑选删除。没有死亡，不是火光shader像素失败；是测试动作计划依赖一次会被挡住的public hit及偶然方向窗口。

实际最小红命令（fixture为首次Python生成且保留的同实现runtime；shift继承原捕获，仅初始wait增加12；observe只读公开字段）：

```powershell
Godot_v4.7.2-stable_win64_console.exe --path E:/Projects/game_hundouluo_codex_worktree/issue-31-v011-acceptance/.godot/issue31-rc3/full-temp/issue36-source-m_tw5e3p --rendering-method gl_compatibility --fixed-fps 60 --script E:/Projects/game_hundouluo_codex_worktree/issue-31-v011-acceptance/.godot/issue31-rc3/pose-diagnosis/shift.gd -- --full --ticks=160 --scenario=fixed --extra=12 --out=E:/Projects/game_hundouluo_codex_worktree/issue-31-v011-acceptance/.godot/issue31-rc3/pose-diagnosis/red-shift12-1
```

修复仅`tools/capture_issue_36.gd`：监听真实公开health_changed首次非致命生命下降，在正常0.7s受击窗口内继续shoot，用Input右两步/左两步，再恢复原方向及计划转向；回调只标记下一步，不直接设帧。原tick125公开hit/跳跃调度/180步/全部姿态、枪身0变化、可见后沿≤1px、相机及退出/诊断assert全保留，并新增必须观察真实非致命事件的assert及trace。没有改生产、生命、无敌期、伤害、动画、敌人攻击或视觉资源。

完全相同12步/160采样的原红环在新runtime副本连续3次exit0且零诊断，tick125仍被拒绝，但真实伤害事件后的左右Input确实覆盖5:false/5:true；这是fixture条件修复，不把无效hit包装成通过。原180步三镜头与固定源码完整21Python/44Godot还要随后实跑，不以这三次定点代替。

所有诊断argv、原始log、trace/PNG及唯一[DEBUG-rc3-pose]只读wrapper保留E盘.godot/issue31-rc3/pose-diagnosis，标为诊断；没有调试代码进入生产或正式捕获。持久交付复制日志/results与关键trace，失败不修剪。旧#36缓存/import未知异常、旧默认相机/音频失败及#35三inconclusive仍独立保留，不借本次fixture修复宣称它们已定位或默认全套通过。

另经独立Spec P3指出，新rc3合法模拟入口继承旧报告读取mech._phase；已以公开_state覆盖移除。新capture参数强制source==本ROOT，Windows无project且BUILD_INFO commit一致，结束只容许.import无归一/staged变化；legal抽样记录实际物理帧并验证相邻12才标5fps。均为诊断/审查后最小工具收敛。
