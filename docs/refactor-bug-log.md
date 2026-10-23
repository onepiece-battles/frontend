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
