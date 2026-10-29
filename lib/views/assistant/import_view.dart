import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:openapi/api.dart';

import '../../ai/import_api.dart';
import '../../ai/import_avatars.dart';
import '../../ai/import_fields.dart';
import '../../constants/onepiece_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../repository/image_dao.dart';
import '../../utils/base64_helper.dart';
import 'import_item_editor.dart';

/// AI batch import (NIKA only): describe a scope, let DeepSeek draft the
/// groups, fruits and characters in it, refine the draft by talking to the AI
/// and by editing items, then import it in one go. Nothing is written before
/// "Import".
class ImportView extends StatefulWidget {
  const ImportView({super.key});

  @override
  State<ImportView> createState() => _ImportViewState();
}

class _ImportViewState extends State<ImportView> {
  final _scope = TextEditingController();
  StreamSubscription<ImportEvent>? _drafting;
  String? _progress;
  String? _error;
  ImportDraft? _draft;
  bool _committing = false;
  ImportResult? _result;
  final List<String> _batchProblems = [];

  /// The avatar lookup (while reviewing) or upload (after importing).
  String? _avatarStatus;

  /// The review conversation: the scope, the AI's summary, then each request
  /// and reply. [_revising] is the label of a revision in progress.
  final List<ImportTurn> _conversation = [];
  final _instruction = TextEditingController();
  StreamSubscription<ImportEvent>? _revision;
  String? _revising;
  String? _revisionError;

  /// The keys the last revision added or changed, highlighted in the list.
  Set<String> _changed = {};

  ImportApi get _api => GetIt.instance<ImportApi>();
  ImportAvatars get _avatars => GetIt.instance<ImportAvatars>();
  bool get _zh => Localizations.localeOf(context).languageCode == 'zh';
  String _t(String zh, String en) => _zh ? zh : en;

  static const _examples = [
    ('草帽一伙', 'Straw Hat Pirates'),
    ('王下七武海', 'Seven Warlords of the Sea'),
    ('海军三大将', 'The three Marine admirals'),
  ];

  @override
  void dispose() {
    _drafting?.cancel();
    _revision?.cancel();
    _scope.dispose();
    _instruction.dispose();
    super.dispose();
  }

  void _startDraft() {
    final scope = _scope.text.trim();
    if (scope.isEmpty || _progress != null) return;
    _drafting?.cancel();
    _revision?.cancel();
    setState(() {
      _progress = _t('正在连接 DeepSeek…', 'Connecting to DeepSeek…');
      _error = null;
      _draft = null;
      _result = null;
      _avatarStatus = null;
      _batchProblems.clear();
      _conversation.clear();
      _changed = {};
      _revising = null;
      _revisionError = null;
    });
    _drafting = _api.draft(scope, language: _zh ? 'zh_CN' : 'en_US').listen(
      (event) {
        if (!mounted) return;
        setState(() {
          switch (event) {
            case ImportProgress(:final label):
              _progress = label;
            case ImportDraftReady(:final draft):
              _draft = draft;
              _progress = null;
              _conversation
                ..add(ImportTurn(true, scope))
                ..add(ImportTurn(false, _summary(draft)));
            case ImportFailure(:final message):
              _error = message;
              _progress = null;
          }
        });
        if (event is ImportDraftReady) unawaited(_findAvatars(event.draft));
      },
      onError: (Object e) {
        if (!mounted) return;
        setState(() {
          _error = e is ApiException && e.code == 403
              ? _t('只有 NIKA 可以使用批量录入。', 'Only NIKA can use the batch import.')
              : _t('起草失败：$e', 'Drafting failed: $e');
          _progress = null;
        });
      },
      onDone: () {
        if (!mounted || _progress == null) return;
        setState(() {
          _error =
              _t('连接中断了，请重试。', 'The connection dropped. Please try again.');
          _progress = null;
        });
      },
    );
  }

  List<ImportItem> get _items => _draft?.items ?? const [];
  List<ImportItem> get _included => _items.where((i) => i.included).toList();

  ImportItem? _item(String? key) {
    for (final item in _items) {
      if (item.key == key) return item;
    }
    return null;
  }

  bool _needsFix(ImportItem item) =>
      item.problems.isNotEmpty ||
      importFieldErrors(item, _zh).isNotEmpty ||
      _unheld(item);

  /// The included characters that eat [fruit].
  List<ImportItem> _holders(ImportItem fruit) => [
        for (final item in _included)
          if (item.type == ImportType.character &&
              item.fruits.contains(fruit.key))
            item,
      ];

  /// A new fruit to import that no included character eats. Every fruit
  /// belongs to the character who ate it, so this blocks the import.
  bool _unheld(ImportItem item) =>
      item.type == ImportType.fruit &&
      !item.exists &&
      item.included &&
      _holders(item).isEmpty;

  /// Leaving a character out leaves out the fruits only it eats; taking it
  /// back takes them back.
  void _toggle(ImportItem item, bool included) => setState(() {
        item.included = included;
        if (item.type != ImportType.character) return;
        for (final fruit in item.fruits.map(_item).whereType<ImportItem>()) {
          if (fruit.exists) continue;
          if (included) {
            fruit.included = true;
          } else if (_holders(fruit).isEmpty) {
            fruit.included = false;
          }
        }
      });

  /// Gives [fruit] to [character]; a new character's capacity follows (up to
  /// two fruits).
  void _assign(ImportItem fruit, ImportItem character) => setState(() {
        character.fruits = [...character.fruits, fruit.key];
        final capacity = character.data['maximum_fruit_count'];
        if (!character.exists &&
            character.fruits.length <= 2 &&
            (capacity is! num || capacity < character.fruits.length)) {
          character.data['maximum_fruit_count'] = character.fruits.length;
        }
        fruit.problems = [];
      });

  String _summary(ImportDraft draft) {
    int count(String type) => draft.items.where((i) => i.type == type).length;
    final groups = count(ImportType.group),
        fruits = count(ImportType.fruit),
        characters = count(ImportType.character);
    return _t(
        '起草了 $groups 个团体、$fruits 个果实、$characters 个角色。哪里不满意直接告诉我，比如“加上佩罗娜”“去掉霍古巴克”“把影子果实给莫利亚”。',
        'Drafted $groups groups, $fruits fruits and $characters characters. Tell me what to change, e.g. "add Perona", "remove Hogback" or "give the Kage Kage no Mi to Moria".');
  }

  /// Sends [text] (or the composer's text) to the AI with the conversation so
  /// far, and applies the revised draft it streams back.
  void _revise([String? text]) {
    final instruction = (text ?? _instruction.text).trim();
    final draft = _draft;
    if (instruction.isEmpty || draft == null || _revising != null) return;
    final history = List.of(_conversation);
    setState(() {
      _conversation.add(ImportTurn(true, instruction));
      _instruction.clear();
      _revising = _t('AI 正在修改草稿…', 'The AI is revising the draft…');
      _revisionError = null;
      _batchProblems.clear();
    });
    void fail(String message) {
      if (!mounted) return;
      setState(() {
        _revisionError = message;
        _revising = null;
      });
    }

    _revision?.cancel();
    _revision = _api
        .revise(draft.items, history, instruction,
            language: _zh ? 'zh_CN' : 'en_US')
        .listen(
          (event) {
            if (!mounted) return;
            switch (event) {
              case ImportProgress(:final label):
                setState(() => _revising = label);
              case ImportDraftReady(draft: final revised):
                _applyRevision(draft, revised);
              case ImportFailure(:final message):
                fail(message);
            }
          },
          onError: (Object e) => fail(_t('修改失败：$e', 'Revising failed: $e')),
          onDone: () {
            if (_revising != null) {
              fail(_t(
                  '连接中断了，请重试。', 'The connection dropped. Please try again.'));
            }
          },
        );
  }

  /// Takes the revised draft, keeping what the reviewer chose for items that
  /// stayed: whether they are included, and their avatar if the name is the
  /// same.
  void _applyRevision(ImportDraft before, ImportDraft revised) {
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
    setState(() {
      _draft = revised;
      _changed = revised.changed.toSet();
      _conversation.add(ImportTurn(
          false, revised.reply ?? _t('草稿已更新。', 'The draft is updated.')));
      _revising = null;
    });
    unawaited(_findAvatars(revised, only: _changed));
  }

  /// The included items, with relations to left-out items dropped.
  List<ImportItem> _toImport() {
    final keys = _included.map((i) => i.key).toSet();
    return [
      for (final item in _included)
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

  /// Looks up portraits for the new characters of [draft] that have none yet
  /// ([only] limits it to those keys, after a revision).
  Future<void> _findAvatars(ImportDraft draft, {Set<String>? only}) async {
    final wanted = draft.items
        .where((i) => !i.exists && i.type == ImportType.character)
        .toList();
    final missing = wanted
        .where((i) => i.avatarUrl == null && (only?.contains(i.key) ?? true))
        .toList();
    if (missing.isEmpty) return;
    setState(() => _avatarStatus =
        _t('正在从 Bangumi 查找角色头像…', 'Looking for character avatars on Bangumi…'));
    String status;
    try {
      final found = await _avatars.find(missing);
      for (final item in missing) {
        item.avatarUrl = found[item.key];
      }
      final have = wanted.where((i) => i.avatarUrl != null).length;
      status = _t(
          '在 Bangumi 找到 $have/${wanted.length} 个角色头像，导入后自动上传；点头像可以不用它。果实和团体的头像请导入后在详情页上传。',
          'Found $have of ${wanted.length} character avatars on Bangumi. They are uploaded after the import; tap one to skip it. Upload fruit and group avatars on their detail pages.');
    } catch (_) {
      status = _t('无法访问 Bangumi，导入后请在详情页上传头像。',
          'Could not reach Bangumi; upload avatars on the detail pages after importing.');
    }
    if (mounted && _draft == draft) setState(() => _avatarStatus = status);
  }

  /// Uploads the kept avatars of the created resources, three at a time. A
  /// failed avatar only leaves that resource without one.
  Future<void> _uploadAvatars(
      ImportResult result, Map<String, String> avatars) async {
    final jobs = [
      for (final created in result.created)
        if (avatars[created.key] case final url?) (created, url),
    ];
    if (jobs.isEmpty) {
      if (mounted) setState(() => _avatarStatus = null);
      return;
    }
    var done = 0, failed = 0;
    void report() => _avatarStatus = done < jobs.length
        ? _t('正在上传头像 $done/${jobs.length}…',
            'Uploading avatars $done/${jobs.length}…')
        : failed == 0
            ? _t('已上传 ${jobs.length} 个头像。', 'Uploaded ${jobs.length} avatars.')
            : _t('已上传 ${jobs.length - failed} 个头像，$failed 个失败，可在详情页手动上传。',
                'Uploaded ${jobs.length - failed} avatars; $failed failed, upload those on the detail pages.');
    setState(report);
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
      if (mounted) setState(report);
    }

    for (var i = 0; i < jobs.length; i += 3) {
      await Future.wait(jobs.skip(i).take(3).map(upload));
    }
  }

  Future<void> _commit() async {
    if (_committing) return;
    setState(() {
      _committing = true;
      _batchProblems.clear();
    });
    final avatars = {
      for (final item in _included)
        if (!item.exists && item.useAvatar && item.avatarUrl != null)
          item.key: item.avatarUrl!,
    };
    try {
      final result =
          await _api.commit(_toImport(), language: _zh ? 'zh_CN' : 'en_US');
      if (!mounted) return;
      setState(() {
        _result = result;
        _draft = null;
      });
      unawaited(_uploadAvatars(result, avatars));
    } on ImportRejected catch (e) {
      if (!mounted) return;
      setState(() {
        for (final item in _items) {
          item.problems = [];
        }
        for (final problem in e.problems) {
          final item = _item(problem.key);
          if (item == null) {
            _batchProblems.add(problem.message);
          } else {
            item.problems.add(problem.message);
          }
        }
        if (_batchProblems.isEmpty) _batchProblems.add(e.message);
      });
    } catch (e) {
      if (mounted) {
        setState(() => _batchProblems.add(_t('导入失败：$e', 'Import failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _committing = false);
    }
  }

  Future<void> _edit(ImportItem item) async {
    final saved = await ImportItemEditor.show(context, item, _items);
    if (saved == true && mounted) setState(() => item.problems = []);
  }

  void _openResource(ImportCreated created) {
    const names = {
      'character': 'characterDetails',
      'fruit': 'fruitDetails',
      'group': 'groupDetails',
    };
    final route = names[created.type];
    if (route == null) return;
    context.goNamed(route,
        extra: created.id, pathParameters: {'name': created.name});
  }

  @override
  Widget build(BuildContext context) {
    final nika = GetIt.instance.isRegistered<User>() &&
        GetIt.instance<User>().loginRole == UserRole.NIKA;
    return Container(
      color: OnepieceColors.surface,
      child: !nika
          ? Center(
              child: Text(_t(
                  '只有 NIKA 可以使用批量录入。', 'Only NIKA can use the batch import.')))
          : LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 600;
                return Column(children: [
                  Expanded(
                    child: SingleChildScrollView(
                      key: const Key('import-scroll'),
                      padding: EdgeInsets.fromLTRB(
                          narrow ? 16 : 28, 20, narrow ? 16 : 28, 24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 960),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _header(),
                              const SizedBox(height: 16),
                              _scopePanel(),
                              if (_error != null) ...[
                                const SizedBox(height: 12),
                                _message(_error!, error: true),
                              ],
                              if (_result != null) ...[
                                const SizedBox(height: 16),
                                _resultPanel(_result!),
                              ],
                              if (_draft != null) ...[
                                const SizedBox(height: 16),
                                _conversationPanel(),
                                const SizedBox(height: 16),
                                ..._review(_draft!, narrow),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_draft != null) _commitBar(narrow),
                ]);
              },
            ),
    );
  }

  Widget _header() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t('AI 批量录入', 'AI batch import'),
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: OnepieceColors.primaryLabel)),
          const SizedBox(height: 6),
          Text(
              _t('说一个范围，AI 起草其中的团体、果实和角色，战力参照已有角色校准。核对修改后一次导入；导入前不会写入任何数据。',
                  'Name a scope and the AI drafts its groups, fruits and characters, with combat stats calibrated against existing characters. Review, fix, then import in one go — nothing is saved before that.'),
              style: const TextStyle(
                  height: 1.5,
                  fontSize: 13,
                  color: OnepieceColors.secondaryLabel)),
        ],
      );

  Widget _panel({required Widget child, Key? key}) => Container(
        key: key,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: OnepieceColors.separator),
        ),
        child: child,
      );

  Widget _scopePanel() {
    final busy = _progress != null;
    return _panel(
      key: const Key('import-scope'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(
          key: const Key('import-scope-field'),
          controller: _scope,
          enabled: !busy,
          maxLength: 500,
          minLines: 1,
          maxLines: 4,
          onSubmitted: (_) => _startDraft(),
          decoration: InputDecoration(
            hintText: _t('例如：草帽一伙全员 / 和之国篇主要角色 / 粘贴一份名单',
                'e.g. the Straw Hat Pirates / main Wano characters / a pasted list'),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final (zh, en) in _examples)
            ActionChip(
              label: Text(_t(zh, en)),
              onPressed: busy
                  ? null
                  : () {
                      _scope.text = _t(zh, en);
                      _startDraft();
                    },
            ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          if (busy) ...[
            const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(_progress!,
                  key: const Key('import-progress'),
                  style: const TextStyle(
                      fontSize: 13, color: OnepieceColors.secondaryLabel)),
            ),
          ] else
            const Spacer(),
          FilledButton.icon(
            key: const Key('import-draft-button'),
            onPressed: busy ? null : _startDraft,
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: Text(_draft == null
                ? _t('生成草稿', 'Draft')
                : _t('重新起草', 'Draft again')),
            style: FilledButton.styleFrom(
                backgroundColor: OnepieceColors.fancyBlue),
          ),
        ]),
      ]),
    );
  }

  /// The conversation with the AI about the draft, and the composer for the
  /// next request.
  Widget _conversationPanel() {
    final busy = _revising != null;
    final unheld = _included.where(_unheld).toList();
    return _panel(
      key: const Key('import-conversation'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.forum_outlined,
              size: 18, color: OnepieceColors.fancyBlue),
          const SizedBox(width: 8),
          Text(_t('和 AI 一起修改草稿', 'Refine the draft with the AI'),
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: OnepieceColors.primaryLabel)),
        ]),
        const SizedBox(height: 12),
        for (final turn in _conversation) _bubble(turn),
        if (busy)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Row(children: [
              const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(_revising!,
                    key: const Key('import-revise-progress'),
                    style: const TextStyle(
                        fontSize: 13, color: OnepieceColors.secondaryLabel)),
              ),
            ]),
          ),
        if (_revisionError != null) ...[
          _message(_revisionError!, error: true),
          const SizedBox(height: 8),
        ],
        if (unheld.isNotEmpty && !busy) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: ActionChip(
              key: const Key('import-revise-holders'),
              avatar: const Icon(Icons.person_search_outlined, size: 18),
              label: Text(_t('让 AI 给没有持有者的果实找到持有者',
                  'Ask the AI who ate the fruits without a holder')),
              onPressed: () => _revise(_t(
                  '这些果实还没有持有者：${unheld.map((f) => f.name(true)).join('、')}。请把它们分给原作里吃下它们的角色，必要时加上这些角色。',
                  'These fruits have no holder: ${unheld.map((f) => f.name(false)).join(', ')}. Give each to the canon character who ate it, adding them if needed.')),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: TextField(
              key: const Key('import-revise-field'),
              controller: _instruction,
              enabled: !busy,
              minLines: 1,
              maxLines: 4,
              maxLength: 500,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _revise(),
              decoration: InputDecoration(
                hintText: _t('告诉 AI 要怎么改…', 'Tell the AI what to change…'),
                counterText: '',
                isDense: true,
                filled: true,
                fillColor: OnepieceColors.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            key: const Key('import-revise-send'),
            tooltip: _t('发送', 'Send'),
            onPressed: busy ? null : _revise,
            style:
                IconButton.styleFrom(backgroundColor: OnepieceColors.fancyBlue),
            icon: const Icon(Icons.arrow_upward_rounded),
          ),
        ]),
      ]),
    );
  }

  Widget _bubble(ImportTurn turn) => Align(
        alignment: turn.user ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: turn.user
                  ? OnepieceColors.fancyBlue.withValues(alpha: .1)
                  : OnepieceColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(turn.user ? 14 : 4),
                bottomRight: Radius.circular(turn.user ? 4 : 14),
              ),
            ),
            child: Text(turn.text,
                style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: OnepieceColors.primaryLabel)),
          ),
        ),
      );

  Widget _message(String text, {bool error = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: error ? const Color(0xFFFFE9E7) : const Color(0xFFFFF4E0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color:
                    error ? const Color(0xFFC64138) : const Color(0xFF8A5A00))),
      );

  List<Widget> _review(ImportDraft draft, bool narrow) {
    final l = AppLocalizations.of(context)!;
    final sections = [
      (ImportType.group, _t('团体', 'Groups')),
      (ImportType.fruit, _t('果实', 'Fruits')),
      (ImportType.character, _t('角色', 'Characters')),
    ];
    return [
      for (final note in draft.notes) ...[
        _message(note),
        const SizedBox(height: 8),
      ],
      if (_avatarStatus != null) ...[
        KeyedSubtree(
            key: const Key('import-avatar-status'),
            child: _message(_avatarStatus!)),
        const SizedBox(height: 8),
      ],
      for (final (type, title) in sections)
        if (draft.items.any((i) => i.type == type)) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Text(
                '$title · ${draft.items.where((i) => i.type == type).length}',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: OnepieceColors.primaryLabel)),
          ),
          for (final item in draft.items.where((i) => i.type == type)) ...[
            // The list waits while the AI revises it, so no edit is lost.
            IgnorePointer(
              ignoring: _revising != null,
              child: _ItemCard(
                key: Key('import-item-${item.key}'),
                item: item,
                draft: draft.items,
                zh: _zh,
                l: l,
                needsFix: _needsFix(item),
                changed: _changed.contains(item.key),
                holders:
                    item.type == ImportType.fruit ? _holders(item) : const [],
                unheld: _unheld(item),
                onToggle: (value) => _toggle(item, value),
                onToggleAvatar: () =>
                    setState(() => item.useAvatar = !item.useAvatar),
                onAssign: (character) => _assign(item, character),
                onEdit: () => _edit(item),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
    ];
  }

  Widget _commitBar(bool narrow) {
    final included = _included;
    final blocked = included.where(_needsFix).length;
    final toCreate = included.where((i) => !i.exists).length;
    final canCommit = included.isNotEmpty && blocked == 0 && !_committing;
    return Container(
      padding: EdgeInsets.fromLTRB(narrow ? 16 : 28, 10, narrow ? 16 : 28, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: OnepieceColors.separator)),
      ),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final problem in _batchProblems) ...[
            _message(problem, error: true),
            const SizedBox(height: 8),
          ],
          Row(children: [
            Expanded(
              child: Text(
                blocked > 0
                    ? _t('还有 $blocked 项需要修改', '$blocked item(s) need fixing')
                    : _t('将新建 $toCreate 项，复用 ${included.length - toCreate} 项',
                        'Creates $toCreate, reuses ${included.length - toCreate}'),
                key: const Key('import-summary'),
                style: TextStyle(
                    fontSize: 13,
                    color: blocked > 0
                        ? const Color(0xFFC64138)
                        : OnepieceColors.secondaryLabel),
              ),
            ),
            FilledButton(
              key: const Key('import-commit-button'),
              onPressed: canCommit ? _commit : null,
              style: FilledButton.styleFrom(
                  backgroundColor: OnepieceColors.fancyBlue),
              child: _committing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_t(
                      '导入 ${included.length} 项', 'Import ${included.length}')),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _resultPanel(ImportResult result) => _panel(
        key: const Key('import-result'),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF247A50), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _t('导入完成：新建 ${result.created.length} 项，复用 ${result.reused} 项，服用果实 ${result.fruitsEaten} 次，加入团体 ${result.groupsJoined} 次。',
                    'Imported: ${result.created.length} created, ${result.reused} reused, ${result.fruitsEaten} fruits eaten, ${result.groupsJoined} groups joined.'),
                style: const TextStyle(
                    fontSize: 14, color: OnepieceColors.primaryLabel),
              ),
            ),
          ]),
          if (_avatarStatus != null) ...[
            const SizedBox(height: 6),
            Text(_avatarStatus!,
                key: const Key('import-avatar-status'),
                style: const TextStyle(
                    fontSize: 13, color: OnepieceColors.secondaryLabel)),
          ],
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final created in result.created)
              ActionChip(
                avatar: Icon(_icon(created.type), size: 16),
                label: Text(created.name),
                onPressed: () => _openResource(created),
              ),
          ]),
        ]),
      );
}

IconData _icon(String type) => switch (type) {
      ImportType.character => Icons.person_outline_rounded,
      ImportType.fruit => Icons.spa_outlined,
      _ => Icons.groups_outlined,
    };

/// One drafted resource: include checkbox, status badges, the key values and
/// relations, and what still needs fixing.
class _ItemCard extends StatelessWidget {
  const _ItemCard({
    super.key,
    required this.item,
    required this.draft,
    required this.zh,
    required this.l,
    required this.needsFix,
    required this.changed,
    required this.holders,
    required this.unheld,
    required this.onToggle,
    required this.onToggleAvatar,
    required this.onAssign,
    required this.onEdit,
  });

  final ImportItem item;
  final List<ImportItem> draft;
  final bool zh;
  final AppLocalizations l;
  final bool needsFix;

  /// Added or changed by the AI's last revision.
  final bool changed;

  /// For a fruit: the included characters that eat it; [unheld] when it is
  /// new and nobody does, which blocks the import until [onAssign].
  final List<ImportItem> holders;
  final bool unheld;
  final ValueChanged<bool> onToggle;
  final VoidCallback onToggleAvatar;
  final ValueChanged<ImportItem> onAssign;
  final VoidCallback onEdit;

  String _t(String zh, String en) => this.zh ? zh : en;

  ImportItem? _find(String? key) {
    for (final other in draft) {
      if (other.key == key) return other;
    }
    return null;
  }

  String _summary() {
    final d = item.data;
    String option(String field) => d[field] == null
        ? ''
        : importOptionLabel(l, field, d[field].toString());
    final parts = <String>[];
    switch (item.type) {
      case ImportType.character:
        parts.addAll([option('race'), option('battle_style')]);
        if (d['bounty'] is num) {
          parts.add('${_t('悬赏', 'Bounty')} ${_berries(d['bounty'] as num)}');
        }
        final stats = ['attack', 'defense', 'blood', 'speed', 'intelligence']
            .where((k) => d[k] != null)
            .map((k) => '${importFieldLabel(l, zh, k)} ${d[k]}');
        parts.addAll(stats);
      case ImportType.fruit:
        parts.add(option('fruit_type'));
        if (d['energy_consume'] != null) {
          parts.add(
              '${importFieldLabel(l, zh, 'energy_consume')} ${d['energy_consume']}');
        }
      default:
        parts.add(option('group_category'));
    }
    return parts.where((p) => p.isNotEmpty).join(' · ');
  }

  String _berries(num value) => value >= 100000000
      ? (zh
          ? '${(value / 100000000).toStringAsFixed(2)}亿'
          : '${(value / 1e9).toStringAsFixed(2)}B')
      : value >= 10000
          ? (zh
              ? '${(value / 10000).toStringAsFixed(0)}万'
              : '${(value / 1e6).toStringAsFixed(1)}M')
          : value.toString();

  Widget _badge(String text, Color background, Color foreground) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: background, borderRadius: BorderRadius.circular(999)),
        child: Text(text,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: foreground)),
      );

  /// The found portrait as it will be cropped (see
  /// [ImportAvatars.avatarSource]), or the type icon. Tapping a found avatar
  /// skips it or brings it back.
  Widget _avatar() {
    const side = 44.0;
    final radius = item.type == ImportType.character ? side / 2 : 8.0;
    final placeholder = Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
          color: OnepieceColors.surface,
          borderRadius: BorderRadius.circular(radius)),
      child: Icon(_icon(item.type),
          size: 20, color: OnepieceColors.secondaryLabel),
    );
    final url = item.avatarUrl;
    if (url == null) return placeholder;
    return Tooltip(
      message: item.useAvatar
          ? _t('不使用这个头像', 'Skip this avatar')
          : _t('使用这个头像', 'Use this avatar'),
      child: InkWell(
        key: Key('import-avatar-${item.key}'),
        customBorder:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        onTap: onToggleAvatar,
        child: Stack(clipBehavior: Clip.none, children: [
          item.useAvatar
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: Image.network(url,
                      width: side,
                      height: side,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (_, __, ___) => placeholder),
                )
              : placeholder,
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: Icon(
                  item.useAvatar ? Icons.cancel_rounded : Icons.undo_rounded,
                  size: 14,
                  color: OnepieceColors.secondaryLabel),
            ),
          ),
        ]),
      ),
    );
  }

  /// A fruit on a character, or a holder on a fruit: the link between them.
  Widget _pill(IconData icon, String text, {bool dropped = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: dropped ? OnepieceColors.surface : const Color(0xFFEAF6EE),
            borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 13,
              color: dropped
                  ? OnepieceColors.secondaryLabel
                  : const Color(0xFF247A50)),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  fontSize: 12,
                  color: dropped
                      ? OnepieceColors.secondaryLabel
                      : const Color(0xFF1F6B45),
                  decoration: dropped ? TextDecoration.lineThrough : null)),
        ]),
      );

  String _fruitLabel(ImportItem fruit) {
    final type = fruit.data['fruit_type'];
    return type == null
        ? fruit.name(zh)
        : '${fruit.name(zh)} · ${importOptionLabel(l, 'fruit_type', '$type')}';
  }

  /// Who eats this fruit, or a way to choose someone when nobody does.
  Widget _holderRow() {
    final candidates = [
      for (final other in draft)
        if (other.type == ImportType.character &&
            other.included &&
            other.fruits.length < 2)
          other,
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(_t('持有者', 'Holder'),
            style: const TextStyle(
                fontSize: 12, color: OnepieceColors.secondaryLabel)),
        for (final holder in holders)
          _pill(Icons.person_outline_rounded, holder.name(zh)),
        if (unheld) ...[
          Text(_t('还没有', 'none yet'),
              style: const TextStyle(fontSize: 12, color: Color(0xFFC64138))),
          PopupMenuButton<ImportItem>(
            key: Key('import-assign-${item.key}'),
            tooltip: _t('选择吃下它的角色', 'Choose who ate it'),
            onSelected: onAssign,
            enabled: candidates.isNotEmpty,
            itemBuilder: (_) => [
              for (final character in candidates)
                PopupMenuItem(
                    value: character, child: Text(character.name(zh))),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFC64138)),
                  borderRadius: BorderRadius.circular(999)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.person_add_alt_rounded,
                    size: 13, color: Color(0xFFC64138)),
                const SizedBox(width: 4),
                Text(_t('选择持有者', 'Choose holder'),
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFFC64138))),
              ]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _relation(IconData icon, String text, bool dropped) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: OnepieceColors.secondaryLabel),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  fontSize: 12,
                  color: OnepieceColors.secondaryLabel,
                  decoration: dropped ? TextDecoration.lineThrough : null)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final errors = importFieldErrors(item, zh);
    final group = _find(item.group);
    final otherName = item.name(!zh);
    // A reused group has nothing to edit; a reused fruit still has holders.
    final editable = !item.exists || item.type != ImportType.group;
    return Opacity(
      opacity: item.included ? 1 : .55,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
              width: changed && !needsFix ? 1.4 : 1,
              color: item.included && needsFix
                  ? const Color(0xFFE8A39C)
                  : changed
                      ? OnepieceColors.fancyBlue.withValues(alpha: .55)
                      : OnepieceColors.separator),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: editable ? onEdit : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 8, 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Checkbox(
                value: item.included,
                onChanged: (value) => onToggle(value ?? false),
              ),
              if (!item.exists)
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 4, 12, 0),
                  child: _avatar(),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(item.name(zh),
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: OnepieceColors.primaryLabel)),
                        if (otherName != item.name(zh))
                          Text(otherName,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: OnepieceColors.secondaryLabel)),
                        item.exists
                            ? _badge(
                                _t('已存在 · 复用', 'Exists · reused'),
                                OnepieceColors.surface,
                                OnepieceColors.secondaryLabel)
                            : _badge(
                                _t('新建', 'New'),
                                OnepieceColors.fancyBlue.withValues(alpha: .1),
                                OnepieceColors.fancyBlue),
                        if (item.uncertain.isNotEmpty && !item.exists)
                          _badge(
                              _t('${item.uncertain.length} 项待核对',
                                  '${item.uncertain.length} to double-check'),
                              const Color(0xFFFFF4E0),
                              const Color(0xFF8A5A00)),
                        if (changed)
                          _badge(
                              _t('刚修改', 'Just changed'),
                              OnepieceColors.fancyBlue.withValues(alpha: .1),
                              OnepieceColors.fancyBlue),
                        if (needsFix)
                          _badge(_t('需修改', 'Needs fixing'),
                              const Color(0xFFFFE9E7), const Color(0xFFC64138)),
                      ],
                    ),
                    if (!item.exists && _summary().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(_summary(),
                          style: const TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: OnepieceColors.secondaryLabel)),
                    ],
                    if (item.type == ImportType.fruit &&
                        (holders.isNotEmpty || unheld)) ...[
                      const SizedBox(height: 8),
                      _holderRow(),
                    ],
                    if (item.fruits.isNotEmpty || group != null) ...[
                      const SizedBox(height: 8),
                      Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            for (final fruit in item.fruits
                                .map(_find)
                                .whereType<ImportItem>())
                              _pill(Icons.spa_outlined, _fruitLabel(fruit),
                                  dropped: !fruit.included),
                            if (group != null)
                              _relation(
                                  Icons.groups_outlined,
                                  '${group.name(zh)} · ${importOptionLabel(l, 'position', item.position ?? 'member')}',
                                  !group.included),
                          ]),
                    ],
                    if (item.uncertain.isNotEmpty && !item.exists) ...[
                      const SizedBox(height: 6),
                      Text(
                          '${_t('AI 不确定：', 'AI unsure about: ')}${item.uncertain.map((k) => importFieldLabel(l, zh, k)).join(zh ? '、' : ', ')}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF8A5A00))),
                    ],
                    for (final text in [
                      ...item.problems,
                      if (errors.isNotEmpty)
                        '${_t('请修改：', 'Fix: ')}${errors.keys.map((k) => importFieldLabel(l, zh, k)).join(zh ? '、' : ', ')}',
                    ]) ...[
                      const SizedBox(height: 4),
                      Text(text,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFFC64138))),
                    ],
                  ],
                ),
              ),
              if (editable)
                IconButton(
                  tooltip: _t('编辑', 'Edit'),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: onEdit,
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
