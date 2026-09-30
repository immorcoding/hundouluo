# #31 v0.1.1-rc.3 增量集成

最终实现/完整实测`3806da865a6e52d371ccb0942d6ca9926180df51`：干净新鲜串行副本48条严格通过（44Godot/21Python无skip/导入/两主启动），源码8与实际Windows EXE8也通过。[双轴审查](code-review.md) P3/P2已解决，各轴未解决0。最终构建与尾部仅证据文档差异、独立解压/许可/SHA见持久交付DELIVERY/BUILD_INFO，不将文档提交冒称重新跑全48。

基线已推送main `dc46c7601291a3c3175c0dafc680605fe0f19391`，包含#36最终`c4952b649633a0ce0861b4ea23391241a2cd2f93`（实现c7cc81f、完整实测a176c9a，到最终仅本票证据文档）。指定工作树`E:\Projects\game_hundouluo_codex_worktree\issue-31-v011-acceptance`、分支`codex/issue-31-v011-acceptance`；沿用已初始化主目录只读代理/领域配置，实际权限danger-full-access/never，本轮gpt-6.1-sol/high。不清理旧工作树、包、用户原文或被策略拒绝删除的#33缓存。

已完整读取#25/#31/#34/#35/#36正文、评论与原生依赖：#29/#30/#33已关闭；#34/#35/#36开放是最终人工闸门，不阻止为合入修复制包。用户#36原话直接报障，不要求先填旧试玩单。rc.1其他通过项与机甲“时间差不多”有效，#34/#35尚未确认；本轮仅新火光/枪身主项和保留两bug及最小通关/R，见[定点复测单](../../retest-v0.1.1-rc.3.md)。五票均OPEN，不合并main/建tag/release/封milestone，由协调最终复核。

#36同关卡接线保持：Muzzle在Sprite之前，专属CombatFlash逐帧可见后沿[18,14,17,18]对齐并裁透明残留；新生己弹只裁枪口平面后的尾部，超过20px清shader/anchor。520px/s、960射程、碰撞/伤害/射速不变，通用敌方及独立己弹合同保持。背景-3/Ground-2/残骸-1/行动员与活敌0，门x3396/14×148/地面252/门靴263/commit3463/警告0.22s/固定中心3580/机甲42HP与射程420继续有效。本轮不改生产scripts/scenes/assets，仅候选版本/包合同、复测文档和新捕获入口。

真实包合同TDD先在37d3906干净独立Git克隆产出旧包，因缺docs/retest-v0.1.1-rc.3.md而exit1；不是脏树前置拒绝。后续绿、固定源码完整检查、新Windows包实际GL合成、源ZIP独立Git/导入、审查与SHA必须实际核对，精确提交/命令/原始日志记录在持久交付DELIVERY/verification，不在本初始说明预宣告通过。

旧默认相机/音频失败、#35三帧低置信inconclusive继续保留。#36首次缓存缺失Python1024诊断、一次import异常3221225477、两次Windows删除缓存失败保留为失败，不冒称根因已确认；新增GL测试自建严格导入E-TEMP相同运行fixture且保留供诊断，断言/诊断不放宽。本轮完整入口仍44Godot+21Python无skip、导入及两主场景90帧共48记录，paced=60模拟+process_frame17ms墙钟，victory120/30。

新捕获工具复用#36实际批准枪管源像素掩码/有无己方反馈同姿态差分、#35合法运动飞行与#36真赢弹120/30；合法Input整关与公开初设/受击/设姿/可见组件fixture分别披露。原速循环必须640×360、180帧/60fps/3秒；全关抽样明确5fps，不冒称原速60fps。最终实际结果随后补入本目录；新增shader及UID入源码包、Windows实际渲染不可仅靠headless启动。

初次134完整检查实际strict_pass=false：Godot/导入/两启动全绿，Python固定镜头缺右向受击姿态；[真实重复红/绿与最小fixture修复](fixture-diagnosis.md)。公开生命事件驱动四步普通左右Input覆盖，保留全部原断言；生产不改。初审Spec P3私有报告字段已删除，采样实际物理帧/source参数及末态门禁也收敛，后续从新干净固定提交重新完整回归与捕获，不拿134旧成功代替。

344d151已实际完整48严格通过、21Python无skip，源码8项GL/呈现也通过；但其Windows独立script入口180秒timeout（子进程exit未取得），scene位置参数探针actual3221225620且明确禁止path overrides。辅助movie仅3067/3600帧后240秒timeout，未发送UI按键，不算火光或成功启动证据。原命令/原始异常与日志保留。

必要最小接缝为纯tools验证Node+project.godot autoload注册：普通无flag立即释放；显式userargs仅选择pixels/motion/outcomes/integrated四个嵌入工具，公共SceneTree.set_script及deferred工具初始化，无任意路径或模板/系统配置更改。源码正常入口开发probe12对画面实际exit0，未知模式exit1、无flag90帧exit0，均零诊断。它是非doc的启动配置增量，因此后续新干净实现必须重新完整48、source/Windows8与构建；344旧成功仅历史，不当最终。

15cdbef增量Spec P2发现独立GL fixture只复制capture_issue_36工具、遗漏新增autoload/UID，导致保持原project配置时缺资源。实际单模块红为exit5/0tests/errors1且3ERROR；完整Python为exit1/18tests/errors1及4诊断，不能说21执行或通过。已同步复制该普通启动依赖与UID，不删project配置、不屏蔽导入诊断/不跳过测试，后续新干净完整提交重跑，原15失败保留。

补依赖后该独立真实GL模块3/3实际exit0、零诊断（69.631s），只是定点green不是全套。15实际release用户参数开发probe也取得12对640×360帧、枪身0/接缝0；unknown实际exit1、默认无flagGL90实际exit0均零引擎诊断。它证明验证入口可行，最终仍需新固定提交的完整source/Windows8及全48，不能把12帧开发probe算完整矩阵。

## 最终380完整检查与导入异常边界

实际入口`tools/check_issue_31.py --clock paced`在全新独立Git副本`.godot/issue31-rc3/verified-project-3806da8-serial`执行，TEMP为被测checkout外E盘`temp-3806da8-serial`。44递归Godot（含继承式running_muzzle）、21Python无skip（含Windows端到端2及真实GL3），导入和headless/GL各90帧，总48记录全部实际exit0、ERROR/SCRIPT ERROR/WARNING零，strict_pass/complete_suite=true；Python113.744s。固定60fps+每process_frame17ms墙钟，victory120/30，原断言不变。

开始HEAD380/status空；结束HEAD相同、25个.import行尾/stat标志，normalized/staged diff空，未stage掩盖。完整argv/inventory/results/raw日志位于verification-final/及持久交付verification。此轮未并发其他Godot捕获、打包或Editor导入，避免把未控制的并发条件混入最终记录。

380首次同实现完整运行失败仍保留：helper import返回失败但原assert未打印内层实际退出，Python18tests/errors1，Godot44/全项目import/两启动通过，strict_pass=false；不能据无engine ERROR声称import exit0。原因未知，不补造3221225477或宣布缓存/并发为已定根因。原副本两次重新import实际exit0/无诊断，只是后续观察，不能恢复首次未记录的退出。失败在verification-first-3806da8及持久diagnostics，重导入argv/实际退出在import-exit-probe。旧36未知异常也不借此宣称已解决。

## 实际源码与原封Windows包的同级图形证据

[汇总](summary.json)、[源码记录](source/run-record.json)、[Windows记录](windows/run-record.json) 均8/8实际exit0、timeout=null、零诊断，前后HEAD380/status/diff/staged空；OpenGL/NVIDIA4060、640×360、固定60模拟+17ms墙钟；终局120Hz/30fps。Windows仅原封EXE+固定userargs入口，无--script/path/外部mainpack，验证时EXE SHA256 `16CE231D4B1910AC6EC14EB2F3FFAF9B81CB5BD5B064C82DC0F6ADE16FC30A66`。普通玩家启动无验证参数、不留下验证节点/信号/后台工作，不新增玩家功能。

两套每套各540配对/642短帧，三个镜头枪身变化0、后沿误差1/0/1px；十种双向站/跑/跳/受击姿态完整。paired首次真实非fatal生命事件后普通Input右2左2并恢复计划；tick125调用可能被正常无敌期挡住，未伪称强制造伤。配对暂停只用于同姿态有无己方反馈差分；原速motion不隐藏效果。两套每套54发/2783独立飞行样本，birth0、maxflight0.003173828px。跟随550.03..725.03、固定3580。

残骸四组243/243、130/130、97/97、1169/1169均行动员前景，尸体673/3687像素仍可见。静态设姿/传送/公开受击组件fixture单独披露；正常起点合法Input全关另证五兵+42机甲有效命中、health1胜利，物理R恢复140/3HP/42机甲。真赢弹120/30变向前后冻结枪管origin/pose/facing相同，死亡无短帧、实体R重建后枪身/接缝正确。模拟机甲时间不替换真人“时间差不多”。

每套三条180帧/60fps/3秒APNG解码逐帧与raw全等；合法全关116帧/5fps，115个实际相邻physics delta全12，明确抽样不冒称60fps。41张精选PNG跨source/EXE有27字节相同、14不同（跑步pose用实际Time.get_ticks_msec/125），不宣称后端/时间跨运行全等；每套自己的真实掩码/枪口证据均过。

完整raw/日志/trace与所有呈现及3663项SHA持久于`E:\Projects\game_hundouluo_codex_artifacts\v0.1.1-rc.3\render-evidence`，不依赖临时worktree。根代理实际查看Windows固定射击与左向残骸图，枪身/火光/独立弹道/门/HUD同屏清楚；所有像素/原速/合法Input证据仅工程确认，三票人工仍未确认。官方release两次不可用CLI入口、辅助movie超时、包合同红/GL依赖红及首次完整失败全部保留，见持久diagnostics。
