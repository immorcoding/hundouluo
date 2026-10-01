# v0.1.1 正式封板

2026-09-30用户明确接受三bug修复及整包，并授权封板。正式发布直接提升已试玩rc.3原包，source_commit仍为67184574eb4e73735eafc42f5aee50762f6f7c29；不重新构建、不改游戏内容或数值。正式tag所在main只新增验收/发布文档，包内0.1.1-rc.3及Windows0.1.1.3身份不改写。正式版SHA、验收来源与构建/文档差异见[发布记录](release-v0.1.1.md)。完整回归/实际EXE验证沿用同一原包已完成的证据，不声称封板文档后又重跑。

## rc.3制作说明（历史，保留构建与失败条件）

本轮使用 [定点复测单](retest-v0.1.1-rc.3.md) 和 [已知事项](known-issues-v0.1.1.md)，#36火光可见接缝/枪身不闪为主项，保留尚未确认的#34/#35及最小通关/R。承接rc.1其他通过项与“时间差不多”，不重开美术/声音/手感/时长验收。旧rc.1/rc.2及原文保留，包身份以 `BUILD_INFO.txt` 的 package_label/source_commit 及交付校验清单为准。

游戏候选版本为`0.1.1-rc.3`；Windows数值file/product version为`0.1.1.3`（原生格式不接受rc字符串），不代表已正式发布。

在本轮指定 E 盘 worktree 中，先将进程 TEMP/TMP 设置为 worktree 的 `.godot/issue31-rc3/temp`；所有源码副本/导入/导出中间产物均落在该目录。最终输出指定 `E:\Projects\game_hundouluo_codex_artifacts\v0.1.1-rc.3`，`-PackageLabel v0.1.1-rc.3`；创建前检查不存在，不覆盖旧交付。脚本从干净 HEAD 制作匹配源 ZIP 和内嵌资源 EXE，真实进程退出码与 ERROR/SCRIPT ERROR/WARNING 日志双门禁；最终从全新目录解压作headless/graphical90帧及源码独立Git/导入/启动检查，并在实际Windows EXE的GL画面检查新增shader、枪身与火光，不能只认无头启动。日志保留尾部空行，不把它视为引擎错误。

统一完整检查入口为`tools/check_issue_31.py --clock paced`：44行为脚本（包含继承式operative_running_muzzle）及21项Python无skip（含2项Windows端到端、3项#36真实GL），导入与两主场景90帧，合计48条记录。固定60fps模拟加每process_frame17ms明确墙钟等待；终局测试120Hz物理/30fps显示。Python/Windows测试先消费原封干净Git提交；新增GL测试自行严格导入相同运行文件的E-TEMP fixture并保留诊断副本，再导入/运行Godot，开始/结束HEAD/status与完整命令记录。默认旧相机/音频失败及#36早期导入异常/清理失败另留记录，未知异常不冒称已确认根因；不称默认全套严格通过。旧#34/#35运行器转发该入口，精确历史复现仍使用历史Git提交。

官方release模板无独立`--script`入口且禁止scene路径覆盖。实际探针的180秒timeout及路径覆盖错误均保留失败，不能把源码捕获冒称EXE。项目增加纯tools验证Node及autoload注册：无显式flag立即释放；`--rc3-render-verification=pixels|motion|outcomes|integrated`仅选择固定嵌入工具，不接受任意资源路径，不修改模板或生产场景。Windows捕获经正常EXE用户参数进入，同源码工具执行真实GL/原断言/进程退出与原始日志门禁。这个启动配置变更必须在最终完整测试提交中；普通无参数启动也重新检查，不以文档差异豁免。

包内含中文记录单、已知事项、项目MIT、完整字体/上游OFL通知。`tools/export_engine_notices.gd` 从实际 Godot 二进制的 Engine API 导出 `GODOT_LICENSE.txt`、`GODOT_COPYRIGHT.json` 和 `GODOT_THIRD_PARTY_LICENSES.json`，包含引擎版权及第三方声明/许可原文，随 Windows 包分发。[Godot官方分发许可说明](https://docs.godotengine.org/en/stable/about/complying_with_licenses.html) 与 [引擎许可](https://godotengine.org/license) 为来源。

玩家拿到 Windows ZIP 后应完整解压，阅读包根目录的 `试玩说明.txt`，双击 `轨道基地.exe`；A/D 或方向键移动、空格跳跃、按住 J 射击，死亡或任务完成时按 R 重试。无需在玩家电脑安装 Godot。

使用 Godot 4.7.2 stable 标准版。Windows x86_64 模板来自 [Godot 官方 4.7.2 发布包](https://godotengine.org/download/archive/4.7.2-stable/)（`Godot_v4.7.2-stable_export_templates.tpz`）；在本机仅提取 `templates/` 下的四个 Windows 文件到 `%APPDATA%\Godot\export_templates\4.7.2.stable\`。本项目不把模板二进制纳入源包。模板 SHA-256：

| 文件 | SHA-256 |
| --- | --- |
| `windows_debug_x86_64.exe` | `51498B72B3A237F882EBD7D1787F06A4BC1EAF0572DAAB93837ADCFD3CFDC107` |
| `windows_debug_x86_64_console.exe` | `5514C7645EE897A01F540D3CF22EDE5BADF92394521A08BFAB66A54D7369E6E6` |
| `windows_release_x86_64.exe` | `D34D36F3BE1A6C49C56525AE86469B92E4F417DDF0B43CF00DD80C385C4B0562` |
| `windows_release_x86_64_console.exe` | `52BDCAE9068E8D23B840E5C63B0C1798FFE2CB66144E5C4BC7AF11FB8C8600DF` |

在干净的已提交工作树中执行：

```powershell
& (Get-Command Godot_v4.7.2-stable_win64_console.exe).Source --headless --editor --path . --import
& (Get-Command Godot_v4.7.2-stable_win64_console.exe).Source --headless --path . --script tests/windows_export_preset_smoke.gd
& ./tools/package_windows.ps1 -CheckOnly
& ./tools/package_windows.ps1 -OutputDirectory 'E:\Projects\game_hundouluo_codex_artifacts\v0.1.1-rc.3' -PackageLabel v0.1.1-rc.3
```

脚本拒绝未提交改动、项目目录内的输出路径和已有同名 ZIP。它从同一 Git `HEAD` 制作完整源 ZIP，在隔离副本导入资源、检查主场景并导出内嵌 PCK 的 Windows 单体 EXE；Windows ZIP 同时含README、LICENSE、素材清单、定点复测单与构建信息。最后在另一个临时目录解压ZIP，真实等待EXE两帧并要求exit0且无诊断。BUILD_INFO保留rc.1已通过项来源，#36主项及#34/#35保留项均未获人工确认。

预备阶段在 `747f418` 基线以 Godot `4.7.2.stable.official.ed1daf0bf` 成功导出 109,697,272 字节单体 EXE，并在新目录解压后无界面启动（exit 0）。该结果仅验证导出链路；正式 v0.1.0 包必须在全部玩法与音画反馈合入之后从最终提交重新生成、记录文件名与 SHA-256，并把包及 [#12 试玩记录单](https://github.com/immorcoding/hundouluo/issues/12)交给用户。

历史边界：v0.1.0/rc.1记录保留`art/issue-31/`，rc.2保留`art/issue-31-rc2/`及原包；#36红绿和早期失败见`bugs/issue-36/`。本轮rc.3实际提交/图形证据见`art/issue-31-rc3/`，完整检查/构建/新解压日志在持久交付verification。人审通过项不重开，三bug等待定点复测。
