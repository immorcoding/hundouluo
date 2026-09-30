# #36 独立两轴审查

固定点 `eec9adfbf4fc045a24ab7630f26318907d7367c7`。初审HEAD `de937d6bc4d504eb00af53ec3f92259072684a78`，增量 `74bcc83c63284a3b7402a28c7dd73978f2b7126b`。diff为 `git diff eec9adfbf4fc045a24ab7630f26318907d7367c7...HEAD`，提交列表为 `git log eec9adf..HEAD --oneline`。

两名独立gpt-6.1-sol/high只读子代理，分别Standards / Spec，未由实施者自评替代。均完整读取code-review技能；Standards提示含全部12项smell基线。规范为主目录只读AGENTS/CONTEXT/domain/issue-tracker/triage文档及worktree STYLE_GUIDE；Spec读取GitHub#36完整正文/评论与#31/#35背景，TDD及required references。ADR不存在，继续审查。

## Standards

初审0项硬性违规，1项低优先级判断性建议。

可能的Duplicated Code（P3）：capture_issue_36重复源图像素到屏幕像素的镜像/居中换算，例如 `Vector2i(35 - x if sprite.flip_h else x - 36, y - 30)`；注册枪械掩码、检查像素、定位枪口必须遵循同一换算，建议抽成工具内部 `_source_pixel_offset(point, mirrored)`，保持独立于生产枪口计算。

已解决。74bcc83增量确认0项新增发现；共享函数统一测试内部换算，仍独立于生产代码。未发现术语、公开事件接缝、硬边像素/原生截图要求的硬性违规，未改运行位图。

代理独立解码六个APNG确认640×360、180源帧、精确3秒，并逐帧核对原始PNG一致；trace与文档修前52像素/10px、修后0像素/≤1px一致。18项定点门禁与16帧独立敌我弹丸一致性准确。完整全套当时仍在运行，未以审查代替完成。

## Spec

初审0个可行动发现。生产修改符合范围：逐帧调整火光可见后沿、保留枪身前景像素，且仅裁掉新生弹丸遮住枪身的绘制部分。发射坐标、运动、碰撞、伤害及数值未改。

代理独立复算556个有火光的配对画面，枪身变化均0、端点最大1px，覆盖双向动作/受击、镜头与终局/R；独立敌我效果16帧相同，源图支持后沿 `[18,14,17,18]`。

74bcc83增量0个可行动发现。工具辅助函数、UID、诊断和展示工具均属#36范围，运行代码未变。文档区分暂停测量/无暂停原速、公开fixture/人工确认，保留旧失败与低置信记录。独立解码六APNG：全部640×360、精确60fps/3秒、展开180帧与原始PNG逐像素一致。18条strict_pass与原始数据一致。

完整Godot/Python当时仍在运行，该审查不提前宣告全套通过、关闭议题、封版或新包交付。

Standards：硬性违规0，P3已解决，未解决0。Spec：未解决可行动项0。首次全套发现的测试准备问题随后由主代理修正，相关增量复审及最终全量记录另补，不能用本报告掩盖首次失败。

## 测试准备与最终固定提交增量

两轴独立复审 `74bcc83...1f85c45` 均0个可行动发现：新增setUpClass复制同一正式运行源码到独立E-TEMP，严格导入后执行原真实GL/Input断言，未改seam、统一入口、原测试或包守卫；`.gdignore`仅排除本票证据导入。首次1024诊断/Python失败、import异常退出及默认两项subset均如实保留。

两轴独立复审 `1f85c45...a176c9a` 均0个可行动发现：21项Python的行为断言完成后，Windows删除目录失败仍保留为整体失败；显式保留导入fixture用于诊断属于授权范围，没有ignore_cleanup_errors或放宽断言。Standards提醒缓存写入竞态应视为推断，README已区分它与日志中的WinError145事实。

最终主代理实际完成a176c9a干净archive的统一全量：44 Godot、21 Python无skip，导入/两种90帧主场景，共48条全exit0、零诊断、strict_pass=true/complete_suite=true。审查未代替该执行；完整最终记录在verification-final。a176c9a之后只有本票文档/日志证据差异，没有运行或测试源码变化。

Standards：硬性违规0、未解决判断建议0（初审P3已解决）；Spec：未解决可行动项0。
