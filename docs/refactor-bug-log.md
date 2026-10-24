# 前端重构 · Bug 记录

> 本文件记录在"稳健增量重构"过程中发现的**真实缺陷**(逻辑错误、潜在崩溃、行为异常、资源泄漏等),与纯架构/风格改动区分开。
> 架构与清理类改动见 commit 历史。
>
> 分支:`refactor/frontend` ·  基线:`flutter analyze` → No issues found(重构全程须保持零告警)

## 状态图例
- 🔴 待修  · 🟡 修复中 · ✅ 已修复 · ⚪️ 暂不修(仅记录)

---

## BUG-001 — Locale 在 `build()` 内被反复重注册 ✅
- **文件**:`lib/main.dart`
- **现象 / 风险**:
  - `_MyAppState.build()`(原 line 132)每次重建都执行 `getIt.registerLazySingleton<Locale>(() => _locale)`,高频重建时反复重注册服务,是无谓开销且语义错误。
  - `MyApp.setLocale`(原 line 91)又单独再注册一次,Locale 有**两个注册来源**,靠全局 `allowReassignment = true` 掩盖。
  - 用 `registerLazySingleton`(惰性单例,首次解析后缓存)承载一个**会变化的** `Locale` 值,语义不符;只有配合 reassignment 清缓存才"碰巧"工作。
- **影响**:语言切换依赖脆弱的注册时机,存在读到陈旧 locale 的风险;每帧多余的 DI 写操作。
- **修复**:在 `getItSetUp()` 中以 `registerSingleton<Locale>` 初始化一次;`setLocale` 中统一 `registerSingleton` 更新(单一数据源);删除 `build()` 内与 `MyApp.setLocale` 内的重复注册;`ThemeData.fontFamily` 改为直接读 `_locale`。

---

## BUG-002 — 编辑角色基础/战斗信息会清空其头像(后端)🔴
- **类型**:既有后端缺陷(非本次重构引入;前端冒烟测试时发现)。
- **文件**:`backend/.../character/model/converter/CharacterEntityConverter.java:66`
- **现象**:在角色详情页编辑基础信息或战斗信息并提交后,该角色的 `image_uri` 被写成 null,头像消失。生产环境同样存在(开发库里已有一个 `image_uri` 为 NULL 的角色)。
- **根因**:
  - `toCharacterEntity(UpdateCharacterRequest)` 标了 `@Mapping(target = "imageUri", ignore = true)`,转换出的 `CharacterEntity.imageUri = null`。
  - `CharacterDao.update` 继承自 `BaseDao`,是**全列更新**(`CharacterService.updateProfile` 正是依赖它写 `image_uri`),于是把 `image_uri` 覆盖为 null。
  - 前端在 `_submitBasicInfo` / `_submitCombatInfo` 中已发送 `imageUri: character.imageUri` 试图保留,但被后端转换器丢弃,前端无法绕过。
- **验证**:`UpdateCharacterRequest` 确有 `imageUri` 字段与 getter。
- **建议修复**:移除 `toCharacterEntity(UpdateCharacterRequest)` 上的 `@Mapping(target = "imageUri", ignore = true)`,让其从请求映射(前端已发当前值,可正确保留)。`CreateCharacterRequest`/`Character` 两处的 ignore 维持不变(创建走单独上传、内部转换)。

---

## BUG-003 — 水果详情页「桌面端」编辑会清空其它字段 🟡(重构中修复)
- **类型**:既有前端缺陷(编辑类区块抽取时发现),与 BUG-002 同类。
- **文件**:`lib/views/fruit/fruit_detail_view.dart`(桌面端 `_getBasicInfo` / `_getCombatInfo` 内联提交)。
- **现象 / 根因**:
  - 后端 `FruitService.updateFruit` → `FruitConverter.toFruitEntity(UpdateFruitRequest)` → `fruitDao.update(entity)`,`FruitDao` 的 `update` 继承自 BaseDao,是**全列更新**;转换器只映射请求里存在的字段。
  - 前端**移动端**提交的是**完整** `UpdateFruitRequest`(名称+类型+能量+全部 6 组 slope/intercept),安全;
  - 但**桌面端**是两个独立的**部分**提交:基础区块只发 `{id, name, fruitType}`、战斗区块只发那几组系数。缺失字段在请求里为 null → 全列更新把它们**写成 null**。即:在桌面端编辑基础信息会清空该水果的全部战斗系数(反之亦然)。
  - 另注:移动端把 `energyConsume` 放在战斗区块、桌面端放在基础区块(布局不一致)。
- **修复**:抽取 `Fruit*InfoSection` 区块时,让每个编辑区块都提交**完整** `UpdateFruitRequest`(自己负责的字段取自本区块控件,其余字段取自已加载的 `fruit` 模型),移动端/桌面端行为统一。这与移动端既有行为一致,并消除桌面端的清字段问题。冒烟重点:桌面端分别编辑基础/战斗信息后,其它字段应保持不变。

---

## BUG-004 — 编辑群组名称/类型会清空其父群组链接与头像 🟡(重构中修复)
- **类型**:既有前端缺陷(抽群组详情编辑区块时发现),与 BUG-002/003 同类但更严重。
- **文件**:`lib/views/group/group_detail_view.dart`(桌面端 `_getBasicInfo` 内联提交)。
- **现象 / 根因**:
  - 后端 `GroupService.update(Group)` → `GroupConverter.toGroupEntity(group)`(只 ignore `profileImage`)→ `groupDao.update(entity)`,`GroupDao.update` 继承自 BaseDao,是**全列更新**,且**不做 fetch-merge**。
  - 前端编辑基础信息时只发 `Group(id, groupCategory, name)`,于是 `fatherGroupId`、`imageUri`、`creationRecordId`、`modificationRecordId` 在请求里为 null → 全列更新把它们**写成 null**。
  - 后果:桌面端改一次群名/类型,该群的**父群组链接(fatherGroupId)丢失**、头像被清、创建/修改记录被清(若这些列为 NOT NULL,则编辑直接报错)。头像虽有独立 addImage 兜底,但 fatherGroupId/记录无兜底。
- **修复**:抽 `GroupBasicInfoSection` 时,提交发送**完整** `Group`(仅 name/category 取自本区块,`fatherGroupId`/`imageUri`/`creationRecordId`/`modificationRecordId` 取自已加载的 groupFullView)。冒烟重点:桌面端改群名/类型后,父子群组关系与头像应保持不变。

---

## 重构范围说明 · `refactor/views` 分支(一次性批量重构)

> 本段记录继 `character_detail` / `character_view` 之后、对其余巨型 view 的一次性重构范围。
> 全程仅做**静态验证**(`flutter analyze` 零告警 + `flutter build web` 通过),由使用者在最后统一做人工冒烟。

**已完成(行为保持,逐个 commit):**
1. **数据访问解耦(全量)**:为每个 view/view-widget 新建数据访问 Controller,把所有 `getIt<XxxDao>()` 调用收口到 Controller。现 `lib/views` 下已无任何 `getIt<SomeDao>()`(仅 Controller 内部通过 `GetIt.instance` 兜底,支持测试注入)。涉及 fruit/group/battle/issue/user/chatting 各 list、detail、create view 以及 `add_group_character_dialog`。
2. **列表页拆分**:fruit/group/battle/issue/user 五个列表页的移动端卡片列表 + 桌面端 SpotlightGrid 抽成独立 `widgets/*_roster.dart`(展示组件,展开状态经回调上提)。
3. **死代码清理**:删除各列表页早已被卡片布局取代、仅挂 `// ignore: unused_element` 的 DataTable 老路径(`_create*Table`/`_createColumns`/`_createRows` 等)与其专用的 `sortOrderToPath` / `sortableEnumToSortOrderMap`;删除 `create_character_view` / `create_group_view` 中 `useCardLayout = maxWidth.isFinite` 恒为 true、`else` 永不可达的遗留布局分支;删除各处未使用的 ScrollController(`tableController`/`horizontalController` 等)、`logger`、`onlyShowSystemResource` 等字段与随之失效的 import。

**后续已完成(逐块冒烟 / 自主静态验证):**
- **`fruit_detail_view`** → 拆成 FruitBasicInfoSection / FruitCombatInfoSection / FruitCharactersSection + 共享 fruit_detail_fields,视图 1413→271 行;顺带修 BUG-003(桌面端部分提交清字段)。
- **`group_detail_view`** → 拆成 GroupBasicInfoSection + GroupMembersPanel(成员树/懒加载/战斗数值整体搬入),视图 1161→249 行;顺带修 BUG-004(编辑群名/类型清空父群组链接与头像)。
- **`battle_detail_view`** → 本质是单一的"战斗执行"实时屏(Timer 轮询 + BattleExecutionData notifier 贯穿各处),不适合按区块拆分;改为抽出 BattleExecutionData 模型到独立文件、纯展示 helper(charMini/workflowStep/workflowConnector)到 widgets,视图 975→777 行。
- **性能**:移除 24 处 `ImageLazyLoader/SquareImageLoader` 上的 `key: UniqueKey()`——它导致每次父级重建都丢弃元素并重新加载图片;两个 loader 都走 ImageCacheManager 缓存且在 didUpdateWidget 里按 URI 变化重载,去掉 key 后元素按位置复用、URI 变化自愈,图片不再每次 setState 重闪。(ImageCacheManager 本身已是带内存/条目上限的 LRU,无需改。)

**保持现状(单一职责的内聚屏,拆分无收益):**
- **`chatting_view`(1828 行)**:已基于 Provider/`ChatNotifier`,无服务定位器耦合、无死代码;体量来自聊天 UI 固有的有状态逻辑(滚动恢复、websocket、图片上传)。
- **`create_*_view`(创建表单)**:单一创建流程、一次性整表提交,各字段区块无清晰的内聚边界;已完成数据访问解耦 + 死代码清理(如 create_character 的遗留 else 布局)。
- **`user_profile`**:早已是 controller + 分区 widget 结构,无需处理。

---
