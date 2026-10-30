import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:openapi/api.dart';

import '../../ai/import_api.dart';
import '../../ai/import_session.dart';
import '../../ai/import_revision.dart';
import '../../ai/import_fields.dart';
import '../../constants/onepiece_colors.dart';
import '../../l10n/app_localizations.dart';
import 'import_item_editor.dart';
import 'widgets/assistant_composer.dart';

/// AI batch import (NIKA only): describe a scope, let DeepSeek draft the
/// groups, fruits and characters in it, refine the draft by talking to the AI
/// and by editing items, then import it in one go. Nothing is written before
/// "Import". The conversation and the draft live in [ImportSession], so they
/// survive leaving the page.
class ImportView extends StatefulWidget {
  const ImportView({super.key});

  @override
  State<ImportView> createState() => _ImportViewState();
}

class _ImportViewState extends State<ImportView> {
  final _message = TextEditingController();
  final _session = GetIt.instance<ImportSession>();

  bool get _zh => Localizations.localeOf(context).languageCode == 'zh';
  String _t(String zh, String en) => _zh ? zh : en;

  static const _examples = [
    ('唐吉诃德家族', 'Donquixote Pirates'),
    ('草帽一伙', 'Straw Hat Pirates'),
    ('海军三大将', 'The three Marine admirals'),
  ];

  @override
  void initState() {
    super.initState();
    _session.addListener(_redraw);
  }

  @override
  void dispose() {
    _session.removeListener(_redraw);
    _message.dispose();
    super.dispose();
  }

  void _redraw() {
    if (mounted) setState(() {});
  }

  ImportDraft? get _draft => _session.draft;
  List<ImportItem> get _items => _session.items;
  List<ImportItem> get _included => _session.included;

  ImportItem? _item(String? key) {
    for (final item in _items) {
      if (item.key == key) return item;
    }
    return null;
  }

  /// Sends what was typed, or [text] from a chip (leaving the typed text).
  void _send(String text, {bool typed = true}) {
    if (text.trim().isEmpty || _session.busy) return;
    _session.send(text, zh: _zh);
    if (typed) _message.clear();
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
  void _toggle(ImportItem item, bool included) {
    item.included = included;
    if (item.type == ImportType.character) {
      for (final fruit in item.fruits.map(_item).whereType<ImportItem>()) {
        if (fruit.exists) continue;
        if (included) {
          fruit.included = true;
        } else if (_holders(fruit).isEmpty) {
          fruit.included = false;
        }
      }
    }
    _session.touch();
  }

  void _assign(ImportItem fruit, ImportItem character) {
    ImportItemEditor.giveFruit(character, fruit.key);
    fruit.problems = [];
    _session.touch();
  }

  Future<void> _edit(ImportItem item) async {
    final saved = await ImportItemEditor.show(context, item, _items);
    if (saved == true) {
      item.problems = [];
      _session.touch();
    }
  }

  void _openResource(ImportCreated created) {
    const names = {
      'character': 'characterDetails',
      'fruit': 'fruitDetails',
      'group': 'groupDetails',
    };
    final route = names[created.type];
    if (route == null) return;
    context.goNamed(route, extra: created.id, pathParameters: {
      'name': created.name.trim().isEmpty ? _t('未命名', 'Unnamed') : created.name
    });
  }

  @override
  Widget build(BuildContext context) {
    final nika = GetIt.instance.isRegistered<User>() &&
        GetIt.instance<User>().loginRole == UserRole.NIKA;
    final result = _session.result;
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
                              _conversationPanel(),
                              if (result != null) ...[
                                const SizedBox(height: 16),
                                _resultPanel(result),
                              ],
                              if (_draft != null) ...[
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
                  AssistantComposer(
                    keyPrefix: 'import',
                    controller: _message,
                    zh: _zh,
                    busy: _session.busy,
                    onSend: _send,
                    hint: _draft == null
                        ? _t('说一个范围，例如：唐吉诃德家族全员',
                            'A scope, e.g. the Donquixote Pirates')
                        : _t('告诉 AI 要怎么改，或让它重新查资料…',
                            'Tell the AI what to change, or to look something up…'),
                  ),
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
              _t('说一个范围，AI 起草其中的团体、果实和角色，战力参照已有角色校准；再用一句句话让它修改，所有对话都会保留。核对后一次导入；导入前不会写入任何数据。',
                  'Name a scope and the AI drafts its groups, fruits and characters, with combat stats calibrated against existing characters; then keep telling it what to change — the whole conversation stays. Import in one go when it looks right; nothing is saved before that.'),
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

  /// The whole conversation: every scope and request, the AI's answers and
  /// errors. The composer under the page (the assistant's) drafts what it is
  /// told when there is no draft, and otherwise changes the current one.
  Widget _conversationPanel() {
    final session = _session;
    final busy = session.busy;
    final unheld = _included.where(_unheld).toList();
    final started = session.conversation.isNotEmpty;
    return _panel(
      key: const Key('import-conversation'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.forum_outlined,
              size: 18, color: OnepieceColors.fancyBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_t('和 AI 对话', 'Conversation'),
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: OnepieceColors.primaryLabel)),
          ),
          if (_draft != null || session.result != null)
            TextButton.icon(
              key: const Key('import-new-draft'),
              onPressed: busy ? null : () => session.newDraft(zh: _zh),
              icon: const Icon(Icons.add_comment_outlined, size: 18),
              label: Text(_t('新草稿', 'New draft')),
            ),
          if (started)
            IconButton(
              key: const Key('import-clear'),
              tooltip: _t('清空对话', 'Clear the conversation'),
              onPressed: busy ? null : _confirmClear,
              icon: const Icon(Icons.delete_sweep_outlined, size: 20),
            ),
        ]),
        const SizedBox(height: 10),
        if (!started) ...[
          Text(
              _t('先说一个范围，比如一个海贼团、一段剧情，或者粘贴一份名单。',
                  'Start with a scope: a crew, an arc, or a pasted list of names.'),
              style: const TextStyle(
                  fontSize: 13, color: OnepieceColors.secondaryLabel)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final (zh, en) in _examples)
              ActionChip(
                label: Text(_t(zh, en)),
                onPressed: busy ? null : () => _send(_t(zh, en), typed: false),
              ),
          ]),
          const SizedBox(height: 12),
        ],
        for (final turn in session.conversation) _turn(turn),
        if (session.progress != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Row(children: [
              const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(session.progress!,
                    key: const Key('import-progress'),
                    style: const TextStyle(
                        fontSize: 13, color: OnepieceColors.secondaryLabel)),
              ),
            ]),
          ),
        if (session.lastRevision case final revision?)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TextButton.icon(
                    key: const Key('import-review-revision'),
                    onPressed: () => _showRevision(revision),
                    icon: const Icon(Icons.difference_outlined, size: 17),
                    label: Text(_t('查看本次修改 · ${revision.changes.length} 项',
                        'Review changes · ${revision.changes.length} items')),
                  ),
                  TextButton.icon(
                    key: const Key('import-undo-revision'),
                    onPressed: session.canUndoRevision
                        ? () => session.undoRevision(zh: _zh)
                        : null,
                    icon: const Icon(Icons.undo_rounded, size: 17),
                    label: Text(_t('撤销本次修改', 'Undo revision')),
                  ),
                ]),
          ),
        if (unheld.isNotEmpty && !busy) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: ActionChip(
              key: const Key('import-revise-holders'),
              avatar: const Icon(Icons.person_search_outlined, size: 18),
              label: Text(_t('让 AI 给没有持有者的果实找到持有者',
                  'Ask the AI who ate the fruits without a holder')),
              onPressed: () => _send(
                  _t('这些果实还没有持有者：${unheld.map((f) => f.name(true)).join('、')}。请把它们分给原作里吃下它们的角色，必要时加上这些角色。',
                      'These fruits have no holder: ${unheld.map((f) => f.name(false)).join(', ')}. Give each to the canon character who ate it, adding them if needed.'),
                  typed: false),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ]),
    );
  }

  void _showRevision(ImportRevisionReview revision) {
    final l = AppLocalizations.of(context)!;
    String value(Object? value, String field, ImportDraft draft) {
      String resource(Object? key) =>
          draft.items.where((item) => item.key == key).firstOrNull?.name(_zh) ??
          '$key';
      if (value == null || value == '') return _t('留空', 'Blank');
      if (field == 'name' && value is Map) {
        return (value[_zh ? 'zh_CN' : 'en_US'] ??
                value.values.firstOrNull ??
                '')
            .toString();
      }
      if (field == 'group') return resource(value);
      if (value is List) {
        return value.isEmpty
            ? _t('无', 'None')
            : value
                .map((v) => field == 'fruits'
                    ? resource(v)
                    : importOptionLabel(l, field, '$v'))
                .join('、');
      }
      if (value is num) {
        return NumberFormat.decimalPattern(_zh ? 'zh_CN' : 'en_US')
            .format(value);
      }
      return importOptionLabel(l, field, '$value');
    }

    showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(_t('本次草稿修改', 'Draft changes')),
              content: SizedBox(
                  width: 560,
                  child: SingleChildScrollView(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final change in revision.changes) ...[
                        Text(
                            '${change.item.name(_zh)} · ${change.added ? _t('新增', 'Added') : change.removed ? _t('移除', 'Removed') : _t('修改', 'Updated')}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        for (final field in change.fields)
                          Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                      field.field.startsWith('name.')
                                          ? '${importFieldLabel(l, _zh, "name")} · ${field.field.endsWith("zh_CN") ? "中文" : "English"}'
                                          : importFieldLabel(
                                              l, _zh, field.field),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color:
                                              OnepieceColors.secondaryLabel)),
                                  const SizedBox(height: 3),
                                  Text(
                                      '${value(field.before, field.field, revision.before)} → ${value(field.after, field.field, revision.after)}',
                                      style: const TextStyle(fontSize: 13)),
                                ],
                              )),
                        const Divider(
                            height: 28, color: OnepieceColors.separator),
                      ],
                    ],
                  ))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(_t('完成', 'Done')))
              ],
            ));
  }

  Future<void> _confirmClear() async {
    final clear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t('清空对话？', 'Clear the conversation?')),
        content: Text(_t('对话记录和当前草稿都会清除，已经导入的数据不受影响。',
            'The conversation and the current draft are removed; what was imported stays.')),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(_t('取消', 'Cancel'))),
          FilledButton(
              key: const Key('import-clear-confirm'),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(_t('清空', 'Clear'))),
        ],
      ),
    );
    if (clear == true) _session.clear();
  }

  Widget _turn(ImportTurn turn) {
    if (turn.kind == ImportTurnKind.note) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          const Expanded(child: Divider(color: OnepieceColors.separator)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(turn.text,
                style: const TextStyle(
                    fontSize: 12, color: OnepieceColors.secondaryLabel)),
          ),
          const Expanded(child: Divider(color: OnepieceColors.separator)),
        ]),
      );
    }
    final error = turn.kind == ImportTurnKind.error;
    return Align(
      alignment: turn.user ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: turn.user
                ? OnepieceColors.fancyBlue.withValues(alpha: .1)
                : error
                    ? const Color(0xFFFFE9E7)
                    : OnepieceColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(turn.user ? 14 : 4),
              bottomRight: Radius.circular(turn.user ? 4 : 14),
            ),
          ),
          child: Text(turn.text,
              style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: error
                      ? const Color(0xFFC64138)
                      : OnepieceColors.primaryLabel)),
        ),
      ),
    );
  }

  Widget _note(String text, {bool error = false}) => Container(
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
        _note(note),
        const SizedBox(height: 8),
      ],
      if (_session.avatarStatus != null) ...[
        KeyedSubtree(
            key: const Key('import-avatar-status'),
            child: _note(_session.avatarStatus!)),
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
              ignoring: _session.busy,
              child: _ItemCard(
                key: Key('import-item-${item.key}'),
                item: item,
                draft: draft.items,
                zh: _zh,
                l: l,
                needsFix: _needsFix(item),
                changed: _session.changed.contains(item.key),
                holders:
                    item.type == ImportType.fruit ? _holders(item) : const [],
                unheld: _unheld(item),
                onToggle: (value) => _toggle(item, value),
                onToggleAvatar: () {
                  item.useAvatar = !item.useAvatar;
                  _session.touch();
                },
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
    final committing = _session.committing;
    final canCommit = included.isNotEmpty && blocked == 0 && !_session.busy;
    return Container(
      padding: EdgeInsets.fromLTRB(narrow ? 16 : 28, 10, narrow ? 16 : 28, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: OnepieceColors.separator)),
      ),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final problem in _session.batchProblems) ...[
            _note(problem, error: true),
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
              onPressed: canCommit ? () => _session.commit(zh: _zh) : null,
              style: FilledButton.styleFrom(
                  backgroundColor: OnepieceColors.fancyBlue),
              child: committing
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
          if (_session.avatarStatus != null) ...[
            const SizedBox(height: 6),
            Text(_session.avatarStatus!,
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
    // A new character holds one fruit; an existing one is checked on import.
    final candidates = [
      for (final other in draft)
        if (other.type == ImportType.character &&
            other.included &&
            (other.exists || other.fruits.isEmpty))
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
