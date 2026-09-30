# 静态场景深度配置的视觉对照

参照场景是提交 `d309625de50a167af83b550402da220411b1e16d`（动态修改背景/甲板的实现）；后测场景是本次把背景/甲板层级声明到 `scenes/level.tscn` 的实现。两边都使用 Godot 4.7.2、OpenGL Compatibility 和 640×360 正式关卡视口。

捕获夹具把行动员放到存活的 SoloSoldier 位置，冻结两者动画和相机跟随，再分别记录两者同屏、单独机械兵、单独行动员及隐藏两者后的环境画面。除相机观察位置和测试节点冻结外，没有改场景美术、尺寸、相对位置或游戏规则。节拍器根据上一帧实际工作时长补足到 16,667 微秒；每次在渲染前真实运行 30 个 process frame。

| 状态 | 重构前 Z | 重构后 Z |
| --- | --- | --- |
| 六个背景节点 | 0 | -3 |
| Ground（含其子节点） | 0 | -2 |
| 行动员 Sprite | 0 | 0 |
| 存活机械兵 Sprite | 0 | 0 |

重构前/后的平均 process-frame 间隔分别是 16.566ms 和 16.647ms。以下四组全画幅图像都是 640×360，使用 PIL RGBA 像素逐点比较，变化像素均为 0：

| 捕获状态 | 重构前 | 重构后 | 变化像素 |
| --- | --- | --- | ---: |
| 存活行动员与机械兵同屏 | [alive.png](before/alive.png) | [alive.png](after/alive.png) | 0 |
| 存活机械兵单独可见 | [soldier-only.png](before/soldier-only.png) | [soldier-only.png](after/soldier-only.png) | 0 |
| 行动员单独可见 | [operative-only.png](before/operative-only.png) | [operative-only.png](after/operative-only.png) | 0 |
| 环境与 HUD | [background.png](before/background.png) | [background.png](after/background.png) | 0 |

对应的 `scene-state.json` 记录每侧 Z 值、帧数和实测节拍。残骸前景和通过行动员行走的像素证据见 [`after/soldier-standing`](../after/soldier-standing/) 与 [`after/mech-standing`](../after/mech-standing/)。
