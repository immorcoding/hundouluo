# #30 接入验证

基线 `main 2a3c76224ed021220c87be9b4f6e1ff509bdd13e`；分支 `codex/issue-30-ui-integration`。实施范围为 `scenes/level.tscn` HUD 子树、`scripts/level_hud.gd`、必要 UI 资源、切片/验收工具和相关测试、文档。地形、CombatEntry、`scripts/level.gd` 均保持基线。五个 HUD 调用契约保留，伤害、三点生命、通关及 R 整关重试仍由关卡决定。

## 实际 Godot 场景截图

这些图片来自当前正式 `scenes/level.tscn` 的真实运行视口，原生 640×360；同名 `-2x.png` 为 nearest 整数二倍。截取时只短暂冻结场景来对照同一底图，不改正式游戏逻辑。不是把获批截图作为场景背景。

| 状态 | 证据 |
| --- | --- |
| 起点，三格生命、机甲条隐藏 | [start.png](start.png) |
| 左侧缺口与危险边缘 | [gap-left.png](gap-left.png) |
| 机甲入镜，42/42 | [mech-full.png](mech-full.png) |
| 交火，28/42 | [combat.png](combat.png) |
| 真实受击，2/3 | [hurt.png](hurt.png) |
| 低生命，1/3 | [low.png](low.png) |
| 机甲最后一点，1/42 | [mech-one.png](mech-one.png) |
| 生命耗尽 | [failure.png](failure.png) |
| 跌落阈值触发“跌落深渊” | [fall.png](fall.png) |
| 击败机甲，任务完成 | [complete.png](complete.png) |
| 失败、跌落、胜利后分别按 R | [retry-failure.png](retry-failure.png)、[retry-fall.png](retry-fall.png)、[retry-complete.png](retry-complete.png) |

`*-approved-overlay.png` 使用 #27 原封不动的冻结绘制器，在同一帧的无 HUD 场景底图上生成，仅作测试 oracle；正式场景不引用它。S6 冻结文件 SHA256 会由资源测试复核。数值取当前关卡的实际生命和 42HP 上限，字体/位置/生命格/机甲条/结算三行及上下边沿对照获批定义。

对照记录为 [comparisons.json](comparisons.json)。文字和进度几何一致，包括 1/42 时 4px 填充；13 态没有超过局部允许误差的像素。结果不是逐字节相同：裁切后 GPU nearest UV 采样和透明混合/截图量化存在小差异，游玩 66 个像素、最大单通道 3/255；结算因底图先量化再遮暗，差异 1375–2617 个像素、最大 5/255。允许范围限定为原图透明切片和结算底图，文字/生命格/进度的位置不能借此漂移。

目视核对原生与二倍图：三格生命实空清楚，机甲条不遮弹道，失败原因明确区分，结果与 R 重试共用中轴，角色/机甲倒地仍可识别。S6 会遮住左侧缺口下部及部分竖向警戒边，这是 #27 已披露并接受方向中的取舍；顶部开口、地面边缘与跳跃危险仍可见。没有自动避让或改变批准布局。

## 重现

```powershell
& Godot_v4.7.2-stable_win64_console.exe --path . --audio-driver Dummy --rendering-method gl_compatibility --script tools/capture_issue_30.gd
& Godot_v4.7.2-stable_win64_console.exe --headless --audio-driver Dummy --path . --script tests/ui_hud_contract.gd
& Godot_v4.7.2-stable_win64_console.exe --headless --audio-driver Dummy --path . --script tests/level_outcomes_retry.gd
& Godot_v4.7.2-stable_win64_console.exe --headless --audio-driver Dummy --path . --script tests/level_feedback.gd
python -m unittest discover -s tests -p test_ui_assets.py -v
```

三轮 red→green 分别验证三格生命接线、机甲准确数字/最后生命点、结算隐藏战斗 HUD；旧文本生命断言迁移到实槽/空槽。两种死因、冻结游戏和无限整关重试的既有回归保留。早期测试退出曾产生 ObjectDB/resource 清理警告；本票涉及的测试已释放场景并等待异步音频清理，最近单项运行没有错误或警告。

完整测试与双轴 code-review 的最终结果将在完成后更新此处。截图与自动事件回归不等于真人运动可读性或听感验收；#31 仍需整包试玩，#33 的门体与镜头锁定不在本票实施。
