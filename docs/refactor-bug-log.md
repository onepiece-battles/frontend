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

## 重构范围说明 · `refactor/views` 分支(一次性批量重构)

> 本段记录继 `character_detail` / `character_view` 之后、对其余巨型 view 的一次性重构范围。
> 全程仅做**静态验证**(`flutter analyze` 零告警 + `flutter build web` 通过),由使用者在最后统一做人工冒烟。

**已完成(行为保持,逐个 commit):**
1. **数据访问解耦(全量)**:为每个 view/view-widget 新建数据访问 Controller,把所有 `getIt<XxxDao>()` 调用收口到 Controller。现 `lib/views` 下已无任何 `getIt<SomeDao>()`(仅 Controller 内部通过 `GetIt.instance` 兜底,支持测试注入)。涉及 fruit/group/battle/issue/user/chatting 各 list、detail、create view 以及 `add_group_character_dialog`。
2. **列表页拆分**:fruit/group/battle/issue/user 五个列表页的移动端卡片列表 + 桌面端 SpotlightGrid 抽成独立 `widgets/*_roster.dart`(展示组件,展开状态经回调上提)。
3. **死代码清理**:删除各列表页早已被卡片布局取代、仅挂 `// ignore: unused_element` 的 DataTable 老路径(`_create*Table`/`_createColumns`/`_createRows` 等)与其专用的 `sortOrderToPath` / `sortableEnumToSortOrderMap`;删除 `create_character_view` / `create_group_view` 中 `useCardLayout = maxWidth.isFinite` 恒为 true、`else` 永不可达的遗留布局分支;删除各处未使用的 ScrollController(`tableController`/`horizontalController` 等)、`logger`、`onlyShowSystemResource` 等字段与随之失效的 import。

**暂缓(⚪️ 需配合逐块人工冒烟再做,本轮未动):**
- **编辑类详情页的表单区块抽取**:`fruit_detail_view` / `group_detail_view` / `battle_detail_view` 以及 `create_*_view` 的移动端/桌面端**可编辑表单 + 提交逻辑**尚未像 `character_detail` 那样抽成 StatefulWidget 区块。这类改动会改写有状态的编辑/提交流程,`character_detail` 当初是靠"逐块冒烟"验证的;本轮为一次性批量、无逐块冒烟,故仅做解耦+清理,表单区块抽取留待后续逐块冒烟时进行。
- **`chatting_view`(1828 行)**:已基于 Provider/`ChatNotifier`,无服务定位器耦合、无死代码;其体量来自聊天 UI 固有的有状态逻辑(滚动位置恢复、websocket、图片上传)。强行拆 `_buildChatView` 风险高,留待逐块冒烟时处理。

---
