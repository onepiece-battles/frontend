import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';

import '../repository/image_dao.dart';
import '../utils/base64_helper.dart';
import 'import_api.dart';
import 'import_avatars.dart';
import 'import_revision.dart';

/// The AI batch import for the whole login session, like `AssistantSession`:
/// every scope and request of the reviewer with the AI's answers, the draft
/// being reviewed and the last import's result. Drafting, revising, finding
/// avatars and uploading them run here, so leaving the page and coming back
/// keeps all of it, including a draft that is still streaming in; the import
/// view only listens. Registered as a GetIt singleton in ApiInitializer.
class ImportSession extends ChangeNotifier {
  /// Everything said, oldest first. A new draft does not clear it.
  final List<ImportTurn> conversation = [];

  /// Where the current draft's turns start. Earlier drafts' turns stay on
  /// screen but are not context for revising this one.
  int _draftStart = 0;

  ImportDraft? draft;
  ImportResult? result;

  /// What the AI is doing (drafting or revising); null when idle.
  String? progress;

  /// The avatar lookup (while reviewing) or upload (after importing).
  String? avatarStatus;

  /// The keys the last revision added or changed.
  Set<String> changed = {};

  ImportRevisionReview? lastRevision;
  bool get canUndoRevision => lastRevision != null && !busy;

  void undoRevision({required bool zh}) {
    if (!canUndoRevision) return;
    draft = copyImportDraft(lastRevision!.before);
    lastRevision = null;
    changed = {};
    batchProblems.clear();
    _say(zh
        ? '已撤销上一轮 AI 修改，恢复修改前的草稿。'
        : 'Undid the last AI revision and restored the previous draft.');
    avatarStatus = null;
    unawaited(_findAvatars(draft!, zh));
    notifyListeners();
  }

  bool committing = false;
  final List<String> batchProblems = [];

  StreamSubscription<ImportEvent>? _stream;

  ImportApi get _api => GetIt.instance<ImportApi>();
  ImportAvatars get _avatars => GetIt.instance<ImportAvatars>();

  bool get busy => progress != null || committing;

  List<ImportItem> get items => draft?.items ?? const [];
  List<ImportItem> get included => items.where((i) => i.included).toList();

  /// Redraws listeners after the view changed an item in place.
  void touch() {
    // A snapshot undo must never discard edits made after the AI finished.
    lastRevision = null;
    notifyListeners();
  }

  /// The reviewer's next message: a draft of that scope when there is no
  /// draft to change (none yet, or the last one was imported), otherwise a
  /// revision of the current draft.
  void send(String text, {required bool zh}) {
    final message = text.trim();
    if (message.isEmpty || busy) return;
    draft == null ? _draft(message, zh) : _revise(message, zh);
  }

  /// Puts the current draft aside so the next message drafts a new scope.
  /// What was said so far stays in the conversation.
  void newDraft({required bool zh}) {
    _stream?.cancel();
    draft = null;
    result = null;
    progress = null;
    changed = {};
    lastRevision = null;
    avatarStatus = null;
    batchProblems.clear();
    if (conversation.isNotEmpty &&
        conversation.last.kind != ImportTurnKind.note) {
      conversation.add(ImportTurn(
          ImportTurnKind.note, zh ? '开始新草稿' : 'Starting a new draft'));
    }
    _draftStart = conversation.length;
    notifyListeners();
  }

  /// Forgets the conversation, the draft and the result.
  void clear() {
    newDraft(zh: true);
    conversation.clear();
    _draftStart = 0;
    notifyListeners();
  }

  void _draft(String scope, bool zh) {
    _stream?.cancel();
    draft = null;
    result = null;
    changed = {};
    lastRevision = null;
    avatarStatus = null;
    batchProblems.clear();
    _draftStart = conversation.length;
    conversation.add(ImportTurn(ImportTurnKind.user, scope));
    progress = zh ? '正在连接 DeepSeek…' : 'Connecting to DeepSeek…';
    notifyListeners();
    _stream = _api.draft(scope, language: zh ? 'zh_CN' : 'en_US').listen(
      (event) {
        switch (event) {
          case ImportProgress(:final label):
            progress = label;
          case ImportDraftReady(draft: final ready):
            draft = ready;
            progress = null;
            _say(_summary(ready, zh));
            unawaited(_findAvatars(ready, zh));
          case ImportFailure(:final message):
            _fail(message);
        }
        notifyListeners();
      },
      onError: (Object e) {
        _fail(e is ApiException && e.code == 403
            ? (zh ? '只有 NIKA 可以使用批量录入。' : 'Only NIKA can use the batch import.')
            : (zh ? '起草失败：$e' : 'Drafting failed: $e'));
        notifyListeners();
      },
      onDone: () {
        if (progress == null) return;
        _fail(zh ? '连接中断了，请重试。' : 'The connection dropped. Please try again.');
        notifyListeners();
      },
    );
  }

  void _revise(String instruction, bool zh) {
    final before = copyImportDraft(draft!);
    final history = [
      for (final turn in conversation.skip(_draftStart))
        if (turn.said) turn,
    ];
    conversation.add(ImportTurn(ImportTurnKind.user, instruction));
    progress = zh ? 'AI 正在修改草稿…' : 'The AI is revising the draft…';
    batchProblems.clear();
    notifyListeners();
    _stream?.cancel();
    _stream = _api
        .revise(before.items, history, instruction,
            language: zh ? 'zh_CN' : 'en_US')
        .listen(
      (event) {
        switch (event) {
          case ImportProgress(:final label):
            progress = label;
          case ImportDraftReady(draft: final revised):
            _applyRevision(before, revised, zh);
          case ImportFailure(:final message):
            _fail(message);
        }
        notifyListeners();
      },
      onError: (Object e) {
        _fail(zh ? '修改失败：$e' : 'Revising failed: $e');
        notifyListeners();
      },
      onDone: () {
        if (progress == null) return;
        _fail(zh ? '连接中断了，请重试。' : 'The connection dropped. Please try again.');
        notifyListeners();
      },
    );
  }

  /// Takes the revised draft, keeping what the reviewer chose for items that
  /// stayed: whether they are included, and their avatar if the name is the
  /// same.
  void _applyRevision(ImportDraft before, ImportDraft revised, bool zh) {
    final previous = {for (final item in before.items) item.key: item};
    for (final item in revised.items) {
      final old = previous[item.key];
      if (old == null) continue;
      item.included = old.included;
      if (old.name(true) == item.name(true) &&
          old.name(false) == item.name(false)) {
        item.avatarUrl = old.avatarUrl;
        item.useAvatar = old.useAvatar;
      }
    }
    lastRevision = ImportRevisionReview(before, revised);
    if (lastRevision!.changes.isEmpty) lastRevision = null;
    draft = revised;
    changed = revised.changed.toSet();
    progress = null;
    _say(revised.reply ?? (zh ? '草稿已更新。' : 'The draft is updated.'));
    unawaited(_findAvatars(revised, zh, only: changed));
  }

  void _say(String text) =>
      conversation.add(ImportTurn(ImportTurnKind.assistant, text));

  void _fail(String message) {
    progress = null;
    conversation.add(ImportTurn(ImportTurnKind.error, message));
  }

  String _summary(ImportDraft draft, bool zh) {
    int count(String type) => draft.items.where((i) => i.type == type).length;
    final groups = count(ImportType.group),
        fruits = count(ImportType.fruit),
        characters = count(ImportType.character);
    return zh
        ? '起草了 $groups 个团体、$fruits 个果实、$characters 个角色。哪里不满意直接告诉我，比如“加上佩罗娜”“去掉霍古巴克”“把影子果实给莫利亚”。'
        : 'Drafted $groups groups, $fruits fruits and $characters characters. Tell me what to change, e.g. "add Perona", "remove Hogback" or "give the Kage Kage no Mi to Moria".';
  }

  /// Looks up portraits for the new characters of [draft] that have none yet
  /// ([only] limits it to those keys, after a revision).
  Future<void> _findAvatars(ImportDraft draft, bool zh,
      {Set<String>? only}) async {
    final wanted = draft.items
        .where((i) => !i.exists && i.type == ImportType.character)
        .toList();
    final missing = wanted
        .where((i) => i.avatarUrl == null && (only?.contains(i.key) ?? true))
        .toList();
    if (missing.isEmpty) return;
    avatarStatus = zh
        ? '正在从 Bangumi 查找角色头像…'
        : 'Looking for character avatars on Bangumi…';
    notifyListeners();
    String status;
    try {
      final found = await _avatars.find(missing);
      for (final item in missing) {
        item.avatarUrl = found[item.key];
      }
      final have = wanted.where((i) => i.avatarUrl != null).length;
      status = zh
          ? '在 Bangumi 找到 $have/${wanted.length} 个角色头像，导入后自动上传；点头像可以不用它。果实和团体的头像请导入后在详情页上传。'
          : 'Found $have of ${wanted.length} character avatars on Bangumi. They are uploaded after the import; tap one to skip it. Upload fruit and group avatars on their detail pages.';
    } catch (_) {
      status = zh
          ? '无法访问 Bangumi，导入后请在详情页上传头像。'
          : 'Could not reach Bangumi; upload avatars on the detail pages after importing.';
    }
    if (this.draft != draft) return;
    avatarStatus = status;
    notifyListeners();
  }

  /// Imports the included items, then uploads their kept avatars. A rejected
  /// import marks every problem on its item and keeps the draft.
  Future<void> commit({required bool zh}) async {
    if (busy || draft == null) return;
    committing = true;
    batchProblems.clear();
    notifyListeners();
    final avatars = {
      for (final item in included)
        if (!item.exists && item.useAvatar && item.avatarUrl != null)
          item.key: item.avatarUrl!,
    };
    try {
      final imported =
          await _api.commit(_toImport(), language: zh ? 'zh_CN' : 'en_US');
      result = imported;
      draft = null;
      lastRevision = null;
      changed = {};
      _say(zh
          ? '导入完成：新建 ${imported.created.length} 项，复用 ${imported.reused} 项，服用果实 ${imported.fruitsEaten} 次，加入团体 ${imported.groupsJoined} 次。'
          : 'Imported: ${imported.created.length} created, ${imported.reused} reused, ${imported.fruitsEaten} fruits eaten, ${imported.groupsJoined} groups joined.');
      _draftStart = conversation.length;
      unawaited(_uploadAvatars(imported, avatars, zh));
    } on ImportRejected catch (e) {
      for (final item in items) {
        item.problems = [];
      }
      for (final problem in e.problems) {
        final item = items.where((i) => i.key == problem.key).firstOrNull;
        item == null
            ? batchProblems.add(problem.message)
            : item.problems.add(problem.message);
      }
      if (batchProblems.isEmpty) batchProblems.add(e.message);
    } catch (e) {
      batchProblems.add(zh ? '导入失败：$e' : 'Import failed: $e');
    } finally {
      committing = false;
      notifyListeners();
    }
  }

  /// The included items, with relations to left-out items dropped.
  List<ImportItem> _toImport() {
    final keys = included.map((i) => i.key).toSet();
    return [
      for (final item in included)
        ImportItem(
          key: item.key,
          type: item.type,
          data: item.data,
          existingId: item.existingId,
          fruits: item.fruits.where(keys.contains).toList(),
          group: keys.contains(item.group) ? item.group : null,
          position: keys.contains(item.group) ? item.position : null,
          uncertain: item.uncertain,
        ),
    ];
  }

  /// Uploads the kept avatars of the created resources, three at a time. A
  /// failed avatar only leaves that resource without one.
  Future<void> _uploadAvatars(
      ImportResult result, Map<String, String> avatars, bool zh) async {
    final jobs = [
      for (final created in result.created)
        if (avatars[created.key] case final url?) (created, url),
    ];
    if (jobs.isEmpty) {
      avatarStatus = null;
      notifyListeners();
      return;
    }
    var done = 0, failed = 0;
    void report() {
      avatarStatus = done < jobs.length
          ? (zh
              ? '正在上传头像 $done/${jobs.length}…'
              : 'Uploading avatars $done/${jobs.length}…')
          : failed == 0
              ? (zh
                  ? '已上传 ${jobs.length} 个头像。'
                  : 'Uploaded ${jobs.length} avatars.')
              : (zh
                  ? '已上传 ${jobs.length - failed} 个头像，$failed 个失败，可在详情页手动上传。'
                  : 'Uploaded ${jobs.length - failed} avatars; $failed failed, upload those on the detail pages.');
      notifyListeners();
    }

    report();
    final images = GetIt.instance<ImageDao>();
    Future<void> upload((ImportCreated, String) job) async {
      final (created, url) = job;
      try {
        final png = await _avatars.prepare(url);
        await images.addImage(UploadImageRequest(
            resourceId: created.id,
            image: Base64Helper.encode(png),
            type: switch (created.type) {
              ImportType.character => ResourceType.CHARACTER,
              ImportType.fruit => ResourceType.FRUIT,
              _ => ResourceType.GROUP,
            }));
      } catch (_) {
        failed++;
      }
      done++;
      report();
    }

    for (var i = 0; i < jobs.length; i += 3) {
      await Future.wait(jobs.skip(i).take(3).map(upload));
    }
  }

  @override
  void dispose() {
    _stream?.cancel();
    super.dispose();
  }
}
