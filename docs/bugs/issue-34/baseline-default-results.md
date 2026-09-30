# 默认节拍测试的基线记录

本记录保留实施前已完成的默认 headless 基线对照；按协调指示没有重复运行这些诊断探针。基线是 `bb36822575c2adbdc464bcb8cf8d6dac7e8de266` 的隔离源码快照，运行 Godot 4.7.2，未修改测试断言。

命令形式：

```powershell
Godot_v4.7.2-stable_win64_console.exe --headless --path <bb36822575c2 的快照目录> --script tests/<test-name>.gd
```

| 默认 headless 测试 | 基线结果 | 诊断 |
| --- | --- | --- |
| `defense_mech_tuning` | exit 0，PASS 输出 | `WARNING: 2 ObjectDB instances were leaked at exit`；`ERROR: 1 resources still in use at exit` |
| `level_gap_camera` | exit 1 | `ERROR: 接近缺口时两侧边缘未同时入镜` |
| `level_progression` | exit 1 | `ERROR: 镜头没有跟随并预留前方视野` |
| `level_boss_wiring` | exit 1 | `ERROR: 机甲完整入镜后未激活`；另有对象清理诊断 |

同一默认严格检查在 `d309625de50a167af83b550402da220411b1e16d` 也记录到 `level_gap_camera` 失败与 `defense_mech_tuning` 的相同泄漏诊断；完整逐项输出保留在本地 `.godot/issue-34-verification/`。这些默认节拍结果不被视为通过验收。提交 `f5aa2107253cb16ad8594a9095efb0bcaf4d5700` 的正式全量检查另用 #35 的 17ms process-frame 墙钟节拍，严格检查 exit code 与全部诊断；结果为 46/46 全通过，详见 [诊断记录](diagnosis.md)。
