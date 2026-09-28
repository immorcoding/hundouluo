# 救援机库开放美术素材包调研（#23）

日期：2026-09-29。范围仅为 2D 横版视觉素材的选型依据；**没有素材入库、没有改动 #22、没有完成美术验收**。对照目标为 [C · 救援机库概念图](https://github.com/immorcoding/hundouluo/blob/codex/visual-art-prototype/prototypes/visual-art/images/c-rescue-bay.png) 与 [#22 验收条件](https://github.com/immorcoding/hundouluo/issues/22)。本次实际下载和解包均在用户临时目录，仓库只保存这份文字笔记。

## 结论先行

**没有发现可原样代替 C 图、且一包覆盖可玩机库、青白行动员、橙红机械兵、大型固定防御机甲的开放素材包。** 可用的低许可风险起点是同一作者 Ansimuz 的 [Sideview Sci-Fi 合集](https://opengameart.org/content/sideview-sci-fi-patreon-collection)中的 *bulkhead-walls / sci-fi-interior-platform / space-marine / bipedal-unit / mech-unit*，配 [Warped Sci-Fi Lab](https://opengameart.org/content/warped-sci-fi-lab) 的三层背景。这是**统一画师的原生像素素材组合**，不是 C 图的成品替身：需先按真实 640×360 画布搭一屏，用户比较之后才能决定是否接受相应像素密度。若 C 的概念图级照明、空间尺度与细节是硬门槛，则即便采用这些开放包，仍须新制大型机库结构、远景机甲/剪影、角色重设计和关键帧；不应再承诺“换包即达标”。[合集原作者发布页](https://opengameart.org/content/sideview-sci-fi-patreon-collection)、[实验室原作者发布页](https://opengameart.org/content/warped-sci-fi-lab)。

## 五个已下载并解包的候选

下述尺寸、帧数和包内许可文本均是 2026-09-29 下载的实际文件检查结果；其可复核的原始压缩包与作者页面列在每项中。表中“与 C 差距”和工时是本项目适配评估，不是作者承诺；工时为有像素美术/Godot 经验者的**粗估**，不包含完整关卡与真人试玩迭代。

| 候选及可浏览预览 | 发布/许可和包内核验 | 实际内容与 C 差距 | 需补项；粗估 |
| --- | --- | --- | --- |
| **1. [Ansimuz Sideview Sci-Fi - Patreon Collection](https://opengameart.org/content/sideview-sci-fi-patreon-collection)**（页面有预览）；[原包 ZIP](https://opengameart.org/sites/default/files/Sideview%20Sci-Fi%20-%20Patreon%20Collection.zip) | 作者本人上传；页标 CC0、允许自由使用且署名自愿；`public-license.txt` 亦声明 public domain、个人/商业均可、无需署名。下载约 2.47 MB，SHA-256 `6DF6FEB73A194568CA0505EA5787867C8DBE623CDEBE6A4C555288F1D92B0CCF`。 | `bulkhead-walls` 有独立 `bg-wall-with-supports.png` 144×224、`bg-wall.png` 48×224、`floor.png` 48×19、`foreground.png` 240×98 及 PSD；`sci-fi-interior-platform` 有 320×192 地块图与 208×112 背景。`space-marine` 为 48 像素高的 idle/run/jump/shoot/die 精灵表；`bipedal-unit` 七格 80×64；`mech-unit` 十格 96×80。还含 corridor 的 192×176 后层与 272×176 前层、其他场景与 PSD。原生画面是细致的 16-bit 小尺度像素风，但“机库墙体”是重复走廊，不具 C 的超大开放空间、光束或巨大远景机甲；现有机甲十格是小型跑动单位，非固定大 Boss。 | 可拼合法地面/缺口和远近景；行动员须重配青白且加不对称工具背包，敌人调整橙红尖角与标识，大 Boss 另画静态大轮廓/射击/受击帧。先做一屏组合约 8–16h；达 C 水准的新增高密度场景和角色约 40–80h，波动大。不可仅缩放角色/把整张预览贴成关卡。 |
| **2. [Ansimuz Warped City](https://ansimuz.itch.io/warped-city)**（作者可运行演示和截图）；[作者 OGA 发布及 ZIP](https://opengameart.org/content/warped-city) | 免费基础包页标 CC0；ZIP 内 `public-license.txt` 明确**美术** public domain。4.26 MB，SHA-256 `CF0E69A203206F529ADBAF1F82D4C5F165CA9CDB49D3995EC88D135B37E40E3E`。包内 Pascal Belisle 音乐要求适当署名，**不按美术 CC0 使用音频**。[作者原文](https://opengameart.org/content/warped-city)。 | 16×16 地块（图 384×256），城市三层背景、道具；玩家单帧约 71×67 画布；免费包的 `SPRITES/player/` 实测 `shoot` 1、`run-shoot` 8、`run` 8、`jump` 4、`idle` 4、`hurt` 1 等，共十类/56 PNG；drone 4、turret 6 帧等。**免费包确有射击和跑射**；[$9 的 addon](https://ansimuz.itch.io/warped-city-addon)所列 rifle run/jump 等扩展不在本 ZIP 中，不能继承基础包许可或暗称已下载。风格为霓虹赛博城市，不是轨道机库；主角是城市人形，不是救援行动员。 | 室外城市与 C 的蓝灰空间及叙事冲突；重配色与机库重建至少 30–60h，Boss 另作。适合作同画师动画/特效参考，不推荐直接当本关主场景。 |
| **3. [Ansimuz Warped Sci-Fi Lab](https://opengameart.org/content/warped-sci-fi-lab)**（页面预览）；[原包 ZIP](https://opengameart.org/sites/default/files/scifi_lab_files.zip) | 作者本人发布，页标 CC0，ZIP 内 `public-license.txt` 明示个人/商业、修改、再分发且署名非必须。40,102 B，SHA-256 `AF2EB52DEBBAFC46355726C44CC34B16CFB037D6F6E19FA19C4F020C05D1D85A`。 | 包内 `back.png`、`middle.png`、`front.png` 各 320×240，另 16×240 支柱、三张 48×122 实验舱和一张预览。蓝青管线/机械背景有 C 所需的“分层技术空间”气氛，但它是室内实验室，没有可行走甲板、跳跃缺口、角色或大型机库远景。 | 与候选 1 同作者混搭可降低风格缝隙；需要另造地面、警戒边、机库主题、机甲。单独使用无法构成场景；与 1 搭配试拼约 6–12h，达 C 的内容制作仍参考候选 1 的 40–80h。 |
| **4. [Ansimuz Warped City 2](https://ansimuz.itch.io/warped-city-2)**（作者截图）；[作者 OGA 发布及 ZIP](https://opengameart.org/content/warped-city-2) | OGA 作者页标 CC0；包内 `public-license.txt` 声明**美术**商业使用、修改、再分发。28.58 MB，SHA-256 `F584233C8543E3048B6E51881EA576294987E431A18BBD00E9A433C96B89ABAC`。包内音频授权未单独核完，**不纳入美术选择/使用**。 | 三层 `back/middle/front`、624×128 的 16×16 地块表、玩家约 80×80 帧画布，`Sprites/Player` 27 PNG、`cop` 13、`egg turret` 6、射击/爆炸效果。比前版大而丰富，但强烈紫/粉城市天际线、楼宇和警方人形与 C 轨道基地差距更大。 | 街景变机库接近重新制作，约 40–80h 起；仅作同作者特效/角色运动备选，不建议作为 #22 场景主包。 |
| **5. [MattWalkden Free Space Runner Pack](https://mattwalkden.itch.io/free-space-runner-pack)**（作者截图）；[作者下载页](https://mattwalkden.itch.io/free-space-runner-pack) | 作者页面明确 CC0 的商业使用、修改和再分发；ZIP 内 `License.txt` 包含 CC0 文本。128,802 B，SHA-256 `AD277C513A3A626EBA62CA0274812AA79EF90B4EAE4C846C3FF28D0F9B440FFE`。 | 432×192 洞穴地块图，24px 高宇航员 idle/run/jump/death、32px 外星人同四类、钻机/尘埃/UI。完整地可作太空洞穴跑酷，但**没有射击帧**，更没有机库/安防机械兵/大机甲。若放大到 #22 主角 54–65 逻辑像素，像素颗粒和 C 明显冲突。 | 不是本关可用主包；重绘比例和背景通常不划算（40h+ 且仍需新 Boss）。作为“开放≠合适”的对照劣选。 |

### 另外核查并淘汰

- [taeden 32×32 Sci-Fi Asset Pack](https://taeden.itch.io/32-x-32-sci-fi-asset-pack) 页面明确 CC0。179 KB ZIP 已实际解开：`tileset.png` 1920×1080、`space_background.png` 320×240，`idle.png` 256×32 及前后左右行走表，少量敌人动画；无包内独立许可文件（许可来自作者页面）。图像是极高对比紫绿，并且多方向/顶视家具，不是 C 的蓝灰横版机库；无完整射击和大 Boss。SHA-256 `A8E492AE557785EB233930EA9FE6330F057A085E6425AC1A7C534508769AA79D`。不建议混入。[作者页面与许可](https://taeden.itch.io/32-x-32-sci-fi-asset-pack)。
- [Buch Sci-fi platformer tileset](https://opengameart.org/content/sci-fi-platformer-tileset) 是作者 CC0、两张 384×384 PNG（16×16 格，机器人/杠杆少量动画），可下载但颜色是强烈彩虹式抽象地块，缺机库纵深与角色动作；不作为本关候选。[作者原页](https://opengameart.org/content/sci-fi-platformer-tileset)。
- [Ansimuz Warped - Space Station](https://ansimuz.itch.io/warped-space-station) 视觉/内容可能更贴近完整场景：作者页称三层背景、16×16 地块、8 个主角动作、4 敌人、Godot 示例；但文件需至少 $19.99 购买，当前未获得 ZIP 与其中许可文本，因此**不是本次“已下载且开放许可已核实”候选**。不能把同画师其他包的 CC0 自动套给它。[作者原页](https://ansimuz.itch.io/warped-space-station)。同理 [$5 Warped Mecha Boss](https://ansimuz.itch.io/warped-mecha-boss) 商业使用许可不等于 CC0，未购买/未核包内文本；而页面标签包含 `contra`，不建议把其现成轮廓直接作为本游戏标志性 Boss。

## 决策、风险和下一步建议

1. **优先试拼而非立即切换 #22 全部资产。** 从候选 1 的已分层 PSD/PNG、候选 3 的 320×240 三层背景取材，制作独立的一张 640×360 Godot **实机**画面，对照 C 图的空间、光照、地面/缺口清晰度和主角 15–18% 高度。只在用户明确认可此像素密度时再把选定文件入库并更新 #22；现在不发布素材。原生背景 240 像素高，放入 360 高逻辑画布应重新布局/补画上方空间，不能任意 1.5× 非整数拉伸后声称清晰像素效果。[#22 规格](https://github.com/immorcoding/hundouluo/issues/22)。
2. **原创辨识度需要二次设计。** CC0 解决被许可素材的复制/改编权限，不代表直接使用 space-marine、bipedal-unit 或 mech-unit 的完整外观会让本游戏拥有自己的视觉标识。保留 [#7](https://github.com/immorcoding/hundouluo/issues/7) 的救援/维修身份、青白偏圆与橙红尖角、深色宽大 Boss、黄色缺口和安防标记；平台布局、徽记和远景主体独立设计。别复制 C 概念图里已画死的地形当可玩贴图，也别复用任何经典游戏可识别的角色/关卡构图。[CC0 正式说明](https://creativecommons.org/publicdomain/zero/1.0/)还指出商标、其他第三方权利与无担保的限制。
3. **许可入库门槛。** 若日后选择包，将实际使用的 PNG、作者 URL、具体 ZIP 文件名及 SHA-256、访问日期、源文件路径、修改说明和 `public-license.txt`/CC0 链接记录到资产台账；包内含音频者逐首另核，不能用美术 CC0 推定音乐权限。保持 #22 不合并直至用户看过真实实机画面。估时只用于选型，不是交付承诺。

研究方法：以作者原发布页及原始压缩包为事实源；实际下载的 ZIP 位于系统 `%TEMP%/hundouluo-open-art-pack-research/`，未入仓库；尺寸与帧数通过解包逐文件检查，画面判断来自本地预览与 C 图并排观察。本笔记不提供法律意见，也未验证这些素材在最终 Godot 场景中的视觉效果。
