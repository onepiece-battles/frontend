import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:openapi/api.dart';

import '../../ai/import_api.dart';
import '../../ai/import_fields.dart';
import '../../constants/onepiece_colors.dart';
import '../../l10n/app_localizations.dart';

/// AI batch import (NIKA only): describe a scope, let DeepSeek draft the
/// groups, fruits and characters in it, review and fix the draft, then import
/// it in one go. Nothing is written before "Import".
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

  ImportApi get _api => GetIt.instance<ImportApi>();
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
    _scope.dispose();
    super.dispose();
  }

  void _startDraft() {
    final scope = _scope.text.trim();
    if (scope.isEmpty || _progress != null) return;
    _drafting?.cancel();
    setState(() {
      _progress = _t('正在连接 DeepSeek…', 'Connecting to DeepSeek…');
      _error = null;
      _draft = null;
      _result = null;
      _batchProblems.clear();
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
            case ImportFailure(:final message):
              _error = message;
              _progress = null;
          }
        });
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
      item.problems.isNotEmpty || importFieldErrors(item, _zh).isNotEmpty;

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

  Future<void> _commit() async {
    if (_committing) return;
    setState(() {
      _committing = true;
      _batchProblems.clear();
    });
    try {
      final result =
          await _api.commit(_toImport(), language: _zh ? 'zh_CN' : 'en_US');
      if (!mounted) return;
      setState(() {
        _result = result;
        _draft = null;
      });
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
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _ItemEditor(item: item, draft: _items),
    );
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
            _ItemCard(
              key: Key('import-item-${item.key}'),
              item: item,
              draft: draft.items,
              zh: _zh,
              l: l,
              needsFix: _needsFix(item),
              onToggle: (value) => setState(() => item.included = value),
              onEdit: () => _edit(item),
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
    required this.onToggle,
    required this.onEdit,
  });

  final ImportItem item;
  final List<ImportItem> draft;
  final bool zh;
  final AppLocalizations l;
  final bool needsFix;
  final ValueChanged<bool> onToggle;
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
    final editable = !item.exists || item.type == ImportType.character;
    return Opacity(
      opacity: item.included ? 1 : .55,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
              color: item.included && needsFix
                  ? const Color(0xFFE8A39C)
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
                    if (item.fruits.isNotEmpty || group != null) ...[
                      const SizedBox(height: 6),
                      Wrap(spacing: 12, runSpacing: 4, children: [
                        for (final fruit
                            in item.fruits.map(_find).whereType<ImportItem>())
                          _relation(Icons.spa_outlined, fruit.name(zh),
                              !fruit.included),
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

/// Edits a copy of an item's fields and relations; "Save" writes them back.
class _ItemEditor extends StatefulWidget {
  const _ItemEditor({required this.item, required this.draft});

  final ImportItem item;
  final List<ImportItem> draft;

  @override
  State<_ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends State<_ItemEditor> {
  late final Map<String, dynamic> _data =
      Map<String, dynamic>.from(widget.item.data);
  late final Map<String, dynamic> _name =
      Map<String, dynamic>.from((widget.item.data['name'] as Map?) ?? {});
  late final List<String> _fruits = List.of(widget.item.fruits);
  late String? _group = widget.item.group;
  late String _position = widget.item.position ?? 'member';
  final Map<String, TextEditingController> _text = {};

  bool get _zh => Localizations.localeOf(context).languageCode == 'zh';
  String _t(String zh, String en) => _zh ? zh : en;

  @override
  void dispose() {
    for (final controller in _text.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controller(String key, Object? value) =>
      _text.putIfAbsent(
          key, () => TextEditingController(text: value?.toString() ?? ''));

  ImportItem get _preview => ImportItem(
        key: widget.item.key,
        type: widget.item.type,
        data: {..._data, 'name': _name},
        existingId: widget.item.existingId,
        fruits: _fruits,
        group: _group,
        position: _position,
      );

  void _save() {
    final item = widget.item;
    if (!item.exists) item.data = {..._data, 'name': _name};
    if (item.type == ImportType.character) {
      item.fruits = _fruits;
      item.group = _group;
      item.position = _group == null ? null : _position;
    }
    Navigator.of(context).pop(true);
  }

  Widget _field(ImportField field, String? error) {
    final l = AppLocalizations.of(context)!;
    final label = importFieldLabel(l, _zh, field.key);
    final unsure = widget.item.uncertain.contains(field.key);
    final decoration = InputDecoration(
      labelText: field.required ? '$label *' : label,
      helperText: unsure ? _t('AI 不确定，请核对', 'AI unsure — please check') : null,
      helperStyle: const TextStyle(color: Color(0xFF8A5A00)),
      errorText: error,
      border: const OutlineInputBorder(),
      isDense: true,
    );
    switch (field.kind) {
      case ImportFieldKind.choice:
        final value = _data[field.key]?.toString();
        return DropdownButtonFormField<String>(
          key: Key('import-field-${field.key}'),
          initialValue: field.options.contains(value) ? value : null,
          isExpanded: true,
          decoration: decoration,
          items: [
            for (final option in field.options)
              DropdownMenuItem(
                  value: option,
                  child: Text(importOptionLabel(l, field.key, option))),
          ],
          onChanged: (value) => setState(() => _data[field.key] = value),
        );
      case ImportFieldKind.choices:
        final selected = ((_data[field.key] as List?) ?? const []).toSet();
        return InputDecorator(
          decoration: decoration,
          child: Wrap(spacing: 6, children: [
            for (final option in field.options)
              FilterChip(
                label: Text(importOptionLabel(l, field.key, option)),
                selected: selected.contains(option),
                onSelected: (on) => setState(() {
                  on ? selected.add(option) : selected.remove(option);
                  _data[field.key] =
                      field.options.where(selected.contains).toList();
                }),
              ),
          ]),
        );
      case ImportFieldKind.text:
      case ImportFieldKind.integer:
      case ImportFieldKind.decimal:
        final numeric = field.kind != ImportFieldKind.text;
        return TextField(
          key: Key('import-field-${field.key}'),
          controller: _controller(field.key, _data[field.key]),
          keyboardType: numeric
              ? TextInputType.numberWithOptions(
                  decimal: field.kind == ImportFieldKind.decimal, signed: true)
              : TextInputType.text,
          decoration: decoration,
          onChanged: (text) => setState(() {
            final value = text.trim();
            if (value.isEmpty) {
              _data.remove(field.key);
            } else if (!numeric) {
              _data[field.key] = value;
            } else {
              final parsed = field.kind == ImportFieldKind.integer
                  ? int.tryParse(value.replaceAll(',', ''))
                  : double.tryParse(value);
              _data[field.key] = parsed ?? value;
            }
          }),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final item = widget.item;
    final errors = importFieldErrors(_preview, _zh);
    final fruits =
        widget.draft.where((i) => i.type == ImportType.fruit).toList();
    final groups =
        widget.draft.where((i) => i.type == ImportType.group).toList();
    return AlertDialog(
      title: Text(item.name(_zh)),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (!item.exists) ...[
              for (final (key, zh, en) in [
                ('zh_CN', '中文名', 'Chinese name'),
                ('en_US', '英文名', 'English name'),
              ]) ...[
                TextField(
                  key: Key('import-field-name-$key'),
                  controller: _controller('name.$key', _name[key]),
                  decoration: InputDecoration(
                    labelText: _t(zh, en),
                    errorText: key == 'zh_CN' ? errors['name'] : null,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (text) => setState(() => text.trim().isEmpty
                      ? _name.remove(key)
                      : _name[key] = text.trim()),
                ),
                const SizedBox(height: 12),
              ],
              for (final field in importFields(item.type)) ...[
                _field(field, errors[field.key]),
                const SizedBox(height: 12),
              ],
            ],
            if (item.type == ImportType.character) ...[
              if (fruits.isNotEmpty) ...[
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: importFieldLabel(l, _zh, 'fruits'),
                    errorText: errors['fruits'],
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  child: Wrap(spacing: 6, children: [
                    for (final fruit in fruits)
                      FilterChip(
                        label: Text(fruit.name(_zh)),
                        selected: _fruits.contains(fruit.key),
                        onSelected: (on) => setState(() => on
                            ? _fruits.add(fruit.key)
                            : _fruits.remove(fruit.key)),
                      ),
                  ]),
                ),
                const SizedBox(height: 12),
              ],
              if (groups.isNotEmpty)
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      key: const Key('import-field-group'),
                      initialValue: _group,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: importFieldLabel(l, _zh, 'group'),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        DropdownMenuItem(
                            value: null, child: Text(_t('不加入', 'None'))),
                        for (final group in groups)
                          DropdownMenuItem(
                              value: group.key, child: Text(group.name(_zh))),
                      ],
                      onChanged: (value) => setState(() => _group = value),
                    ),
                  ),
                  if (_group != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: const Key('import-field-position'),
                        initialValue: _position,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: importFieldLabel(l, _zh, 'position'),
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          for (final position in GroupPosition.values)
                            DropdownMenuItem(
                                value: position.value,
                                child: Text(importOptionLabel(
                                    l, 'position', position.value))),
                        ],
                        onChanged: (value) =>
                            setState(() => _position = value ?? 'member'),
                      ),
                    ),
                  ],
                ]),
            ],
          ]),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(_t('取消', 'Cancel')),
        ),
        FilledButton(
          key: const Key('import-editor-save'),
          onPressed: _save,
          style:
              FilledButton.styleFrom(backgroundColor: OnepieceColors.fancyBlue),
          child: Text(_t('保存', 'Save')),
        ),
      ],
    );
  }
}
