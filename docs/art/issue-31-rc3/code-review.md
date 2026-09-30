# rc.3 独立双轴审查

固定基线`dc46c7601291a3c3175c0dafc680605fe0f19391`，最终实现`3806da865a6e52d371ccb0942d6ca9926180df51`。两个独立gpt-6.1-sol/high只读子代理分别Standards和Spec，初审`dc46c760...134dd338`，逐次审`134dd338...344d151`、`344d151...15cdbef`、`15cdbef...3806da8`；不是由主代理合并重排发现。

## Standards

初审硬性违规0、可行动baseline smell0。领域词汇符合CONTEXT/domain；原生640×360、180/60fps与5fps抽样分别披露，复用合法Input、公开事件和独立枪管像素预期。继承包装有时钟/记录职责，未判定Middle Man/Refused Bequest。素材清单记录shader/UID与MIT来源，历史失败、包和人审边界保留。

344增量硬违反0、smell0、未解决0：原计划动作独立为_scheduled_inputs，真实生命事件后普通左右Input四步并恢复原计划；原像素/姿态/相机断言保留。source参数、Windows BUILD_INFO及source末态收敛；实际物理帧delta12验证才称5fps；私有_phase报告字段移除。

15启动配置单独审：硬违反0、smell0、未解决0。project autoload与纯tools Node无flag立即排队释放返回；只接受四个静态模式，空/重复/未知明确失败。加载后校验SceneTree类型，延迟一次工具初始化，无任意资源路径入口或重复初始化。固定映射是两运行环境有限接线，无需共享配置抽象。超时保留partial stdout/stderr、exit=null，未伪造正常退出；原项目MIT来源、UID跟踪完整。审查不提前认定EXE或完整检查通过。

380依赖复制增量硬违反0、smell0、未解决0：GL fixture从同一ROOT复制bootstrap gd+UID，保持原project配置/导入诊断/全部断言。仅显式验证flag才加载四种工具，正常fixture无需复制未启用的mode工具。文档区分失败、3项定点与尚待完整验证。

## Spec

初审P3：新rc3合法模拟未覆盖_state，继承旧报告读取mech._phase，超出公开边界。344已用公开_state覆盖解决。source==ROOT、Windows无project且BUILD_INFO一致、source末态和真实采样间隔也收敛，新增未解决0。独立核对三green trace真实3→2，tick88/89右、90/91左、92恢复左、95停；三次均右2/左39带可见火光受击样本，枪身/接缝0。tick125仍2→2被挡，文档不伪称有效hit。生产/生命/无敌期/原断言未改。

15启动配置增量P2：project注册bootstrap但独立GL fixture仅复制36工具，漏新增autoload及UID。380精确补这两依赖，保留project/诊断，不跳过或过滤；独立核对red0tests/3ERROR、green3/3/69.631s。P2已解决、旧P3仍已解决、新增未解决0。

历史15/380审查曾认为输出目录由正式Python捕获器限制新E盘即可。协调复核已退回这一判断：原封f208 EXE可绕过捕获器直接将--out交给旧fixture，实际覆盖已有输出；此处历史“未解决0”不能作为输出边界通过结论。固定模式、无任意可执行资源输入以及默认无flag返回的判断继续有效；输出边界改由EXE入口自身负责，见下文增量范围。

## 实际核对与剩余边界

主代理核对最终380干净新鲜串行副本全48记录strict_pass/complete_suite=true：44Godot、21Python无skip（113.744s）、导入和两主启动，所有exit0/零引擎诊断。380首次helper import失败仍strict=false/18tests/errors1，内层原退出未被旧assert输出，原因未确定；原副本两次重导入exit0不恢复原退出或证实原因。最终运行时没有其他捕获/包/Editor导入并发，条件明示，不借后续通过抹掉失败。

同380源码8/实际Windows8均真实exit0/零诊断、前后干净同HEAD；默认无flag90和unknown mode实际exit1 probe分别留证。源/EXE图形独立记录，不互相冒称，后续证据文档提交不冒称重跑完整48。最终新包独立Git/导入/实际启动/许可证/哈希以及最终文档增量仍需交付记录核对。

Standards：硬违反0、smell0、未解决0。Spec：P3/P2已解决，未解决0；历史未知import异常/默认时钟失败/旧低置信probe继续披露。

## f208输出边界返工范围

基线固定为f208911d8b6712407c68dbac2a2b5bd675d3e211。保留旧审查及失败事实，不重做#36美术/诊断。真实旧EXE红测在新自有E目录内覆盖47字节哨兵为491字节trace，EXE实际exit0并进入fixture；拒绝契约测试exit1、strict_pass=false。原包及既有证据未改，原始日志/前后SHA保留在持久交付目录的新增输出边界诊断中。

新入口在load固定fixture前要求唯一非空--out、规范化绝对E路径、固定rc.3证据根内的既存非链接父目录和不存在的目标。拒绝res/user/相对/其他盘、重复参数、dot/dotdot、Windows名称别名、已有文件/目录、链接祖先和缺失父目录；原子make_dir预留新leaf，失败exit1且不加载fixture。两个固定根是本E工作树的.godot/issue31-rc3与E:/Projects/game_hundouluo_codex_artifacts/v0.1.1-rc.3；正斜杠及反斜杠均接受。仍只输出既有PNG/trace，无任意资源/方法入口。无flag在校验前返回，原测试和生产行为不变。

新增tools/check_rc3_output_boundary.py只作为实际原封EXE的独立CLI契约检查，不增加unittest类或改变21项计数。非法pixels参数以headless运行防止守卫退化时误写res/user输出；任何fixture marker都判失败，不能借旧fixture自身的headless失败冒称入口拒绝。合法新E目录用真实GL、原PASS及640×360 PNG核验。新实现独立两轴审查、完整44Godot/21Python与Windows八项结果以新提交对应的持久交付记录为准，本段不预先宣称通过。
