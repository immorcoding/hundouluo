# #32 验证记录

2026-09-29，Windows，Godot 4.7.2 / OpenGL Compatibility / NVIDIA RTX 4060 Laptop，Python + Pillow 10.4.0。

## 美术交付接缝

- 八组 SVG + RGBA PNG 重建前后 SHA-256 一致；无生成缓存依赖。
- 返工素材每张 96×252，活动门板仍为 x=[57,71)、y=[104,252) 的 14×148；复用柱的 alpha 保持原样，新增几何为整像素。
- 警告末帧在 y=[184,252) 与开放态像素一致，未提前绘制落地门板；静态导轨/柱座是后景结构，不作为新碰撞。
- 原生静图 640×360；三段循环各 2200ms。六格对照每格原生 640×360，无缩放。
- 正常与贴边捕获均读到 warning frame 32 / closed frame 46，14 个 60Hz 物理帧（0.233s）；原 0.22s 常量不变。
- 贴边闭合后实际左移停在 x=3463.074707；警告中实际左移到 x=3460.5，闭合被取消，预览回到开放。
- `git diff --exit-code 3f970aa -- scenes scripts assets project.godot tests` 通过；正式资源、玩法、场景和测试没有改动。

## Godot 回归

执行全部 `tests/*.gd` 中首行 `extends SceneTree` 的 32 个独立入口。32 个均输出行为 PASS，25 个无退出错误；另 7 个有 ObjectDB / resource 退出清理日志，严格把 ERROR 日志算失败的检查结果为 7 项未全绿：

`defense_mech_tuning.gd`、`level_boss_wiring.gd`、`level_enemy_fire.gd`、`level_feedback.gd`、`level_operative_wiring.gd`、`level_outcomes_retry.gd`、`level_progression.gd`。

这些检查运行的是未修改的基准测试和正式场景，不加载新预览脚本；本票不以修改玩法代码或测试清理来消除日志。`level_combat_entry.gd`、`visual_grounding.gd`、`operative_muzzle.gd` 等本票相关检查通过且无 ERROR。美术图形捕获脚本三种序列退出 0，无脚本解析或渲染错误。

## Python / 打包

首次 `python -m unittest discover -s tests -v`：11/12 通过；打包端到端因未提交工作树被其干净提交门槛拒绝。提交 `9fc86e4` 后，为同时满足用户「所有工作在指定工作树」和打包脚本「输出在项目检出外」，在忽略的 `capture-frames/package-check/source` 克隆同一提交，临时输出仍置于本工作树的 `.godot/t`。两项打包检查均通过（15.739s），包括源码与 Windows ZIP、解压后的 EXE 启动。最初过深临时路径上的 Godot 导入曾退出 -1073741819；改用上述短临时路径后通过，没有改动打包器。新版最终复核结果见 #32 交付评论。

## 人工目视

检查原生开/警告/关、相同姿态旧入口对照、贴边与射击截图：行动员及枪管、防御机甲炮口、青色己方弹丸和橙色危险提示保持可辨；门板下端不覆盖低位甲板。灯亮与下降只作视觉提示。短窗口能否被首次玩家及时理解、最后落锁速度是否舒服仍需用户按原速审看；没有把脚本序列当作真人公平性验收。
