# #33 正式入口闸门

接入用户批准的 #32 **B 甲板同源墙式门洞、再左16px / x3396**。#32 已关闭，位置风险与相机要求采用 [#33 最新评论](https://github.com/immorcoding/hundouluo/issues/33#issuecomment-5885469279)。不使用 x3388 候选，不重新设计或生成美术。

`gate.png` 是 1024×288 的无损横向图集，8 帧各128×288。顺序为开放、warning-0..5、关闭；每帧原始锚点 `(64,252)`。正式 Sprite2D 中心位于 CombatEntry 本地 `(0,-108)`，因此世界门中心 `(3396,252)`，图集左上 `(3332,0)`，门靴末行 y263。最近邻、1:1、整数位置；门及后景框在行动员、机甲和弹丸之前绘制。

可编辑几何、调色板和世界对齐基板来自 `art/entry_gate/b-left/build.py`、`art/entry_gate/ab/build.py` 及 `art/entry_gate/build.py`。8 张批准 PNG/SVG 位于 `art/entry_gate/b-left/left16/`。`build.py` 只逐像素拼接这些导出，不缩放、模糊、重绘或改变色阶。

```powershell
python art/entry_gate/b-left/build.py # 需要重建设计导出时使用
python assets/entry_gate_v011/build.py
```

新增代码/门框/门板继承根 MIT LICENSE；甲板材质沿用项目 #22 原创生成辅助素材 `assets/pixel/hangar_deck.png`，来源、生成提示与许可见 `assets/art_source/README.md`、`PROMPTS.md`、`docs/assets-manifest.md`。本次没有使用新的 ImageGen 输出或第三方游戏素材。

屏障仍为14×148、x3389..3403/y104..252，地面 y252。门靴下探为装饰；B 双侧门框在后景，不增加宽实体侧墙。上墙体与下框材质密度差异仍是既有设计限制，单项获批不表示全关像素风已统一。
