import 'package:flutter/material.dart';
import 'package:openapi/api.dart';

import '../../ai/import_fields.dart';
import '../../ai/import_models.dart';
import '../../constants/onepiece_colors.dart';
import '../../l10n/app_localizations.dart';

const _unsureFill = Color(0xFFFFF7E6);
const _unsureText = Color(0xFF8A5A00);
const _errorText = Color(0xFFC64138);

/// Edits a copy of a drafted item; "Save" writes it back. Fields are grouped
/// into sections — identity, profile, combat stats and relations for a
/// character; type, effects and holders for a fruit — and every number shows
/// its allowed range. A fruit's holders are the characters whose fruit lists
/// contain it, so choosing them here edits those characters.
class ImportItemEditor extends StatefulWidget {
  const ImportItemEditor({super.key, required this.item, required this.draft});

  final ImportItem item;
  final List<ImportItem> draft;

  /// Opens the editor full screen on a phone, as a dialog otherwise. Resolves
  /// to true when the item was saved.
  static Future<bool?> show(
      BuildContext context, ImportItem item, List<ImportItem> draft) {
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return showDialog<bool>(
      context: context,
      builder: (_) => narrow
          ? Dialog.fullscreen(child: ImportItemEditor(item: item, draft: draft))
          : Dialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ImportItemEditor(item: item, draft: draft),
              ),
            ),
    );
  }

  /// Gives [fruit] to [character]. A new character holds one fruit, so it
  /// replaces theirs; an existing one keeps its own capacity, checked on import.
  static void giveFruit(ImportItem character, String fruit) {
    if (character.exists) {
      character.fruits = [...character.fruits, fruit];
    } else {
      character.fruits = [fruit];
      character.data['maximum_fruit_count'] = 1;
    }
  }

  @override
  State<ImportItemEditor> createState() => _ImportItemEditorState();
}

class _ImportItemEditorState extends State<ImportItemEditor> {
  late final Map<String, dynamic> _data =
      Map<String, dynamic>.from(widget.item.data);
  late final Map<String, dynamic> _name =
      Map<String, dynamic>.from((widget.item.data['name'] as Map?) ?? {});
  late final List<String> _fruits = List.of(widget.item.fruits);
  late String? _group = widget.item.group;
  late String _position = widget.item.position ?? 'member';
  late final Set<String> _holders = {
    for (final c in _characters)
      if (c.fruits.contains(widget.item.key)) c.key,
  };
  final Map<String, TextEditingController> _text = {};

  bool get _zh => Localizations.localeOf(context).languageCode == 'zh';
  String _t(String zh, String en) => _zh ? zh : en;
  AppLocalizations get _l => AppLocalizations.of(context)!;
  ImportItem get _item => widget.item;

  List<ImportItem> get _characters =>
      widget.draft.where((i) => i.type == ImportType.character).toList();

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
        key: _item.key,
        type: _item.type,
        data: {..._data, 'name': _name},
        existingId: _item.existingId,
        fruits: _fruits,
        group: _group,
        position: _position,
      );

  void _save() {
    final item = _item;
    if (!item.exists) item.data = {..._data, 'name': _name};
    if (item.type == ImportType.character) {
      item.fruits = _fruits;
      item.group = _group;
      item.position = _group == null ? null : _position;
    }
    if (item.type == ImportType.fruit) {
      for (final character in _characters) {
        final eats = character.fruits.contains(item.key);
        if (_holders.contains(character.key) && !eats) {
          ImportItemEditor.giveFruit(character, item.key);
        } else if (!_holders.contains(character.key) && eats) {
          character.fruits =
              character.fruits.where((k) => k != item.key).toList();
        }
      }
    }
    Navigator.of(context).pop(true);
  }

  // ── Building blocks ────────────────────────────────────────────

  InputDecoration _decoration(
          {String? hint, String? error, String? suffix, bool unsure = false}) =>
      InputDecoration(
        isDense: true,
        filled: true,
        fillColor: unsure ? _unsureFill : OnepieceColors.surface,
        hintText: hint,
        errorText: error,
        suffixText: suffix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: OnepieceColors.fancyBlue, width: 1.4)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _errorText, width: 1.2)),
      );

  Widget _label(String text, {bool required = false, bool unsure = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Flexible(
            child: Text(text,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: OnepieceColors.secondaryLabel)),
          ),
          if (required)
            const Text(' *', style: TextStyle(color: _errorText, fontSize: 12)),
          if (unsure) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFEBC2),
                  borderRadius: BorderRadius.circular(99)),
              child: Text(_t('AI 不确定', 'AI unsure'),
                  style: const TextStyle(fontSize: 10.5, color: _unsureText)),
            ),
          ],
        ]),
      );

  Widget _section(IconData icon, String title, List<Widget> children,
          {String? hint}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(icon, size: 17, color: OnepieceColors.fancyBlue),
            const SizedBox(width: 6),
            Text(title,
                style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: OnepieceColors.primaryLabel)),
            if (hint != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(hint,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: OnepieceColors.secondaryLabel)),
              ),
            ],
          ]),
          const SizedBox(height: 12),
          ...children,
        ]),
      );

  /// [children] in [columns] equal columns (two on a phone).
  Widget _grid(List<Widget> children, {int columns = 2}) => LayoutBuilder(
        builder: (context, constraints) {
          final count = constraints.maxWidth < 520 ? 2 : columns;
          const gap = 12.0;
          final width = (constraints.maxWidth - gap * (count - 1)) / count;
          return Wrap(spacing: gap, runSpacing: 14, children: [
            for (final child in children) SizedBox(width: width, child: child),
          ]);
        },
      );

  ImportField _field(String key) =>
      importFields(_item.type).firstWhere((f) => f.key == key);

  String _range(ImportField field) {
    String n(num? v) => v == null
        ? ''
        : v == v.roundToDouble()
            ? v.toInt().toString()
            : v.toString();
    return '${n(field.min)} – ${n(field.max)}';
  }

  /// A text or number field; numbers show their range and where the value
  /// sits in it.
  Widget _input(String key, String? error, {String? label, String? suffix}) {
    final field = _field(key);
    final numeric = field.kind != ImportFieldKind.text;
    final unsure = _item.uncertain.contains(key);
    final value = _data[key];
    final position = numeric && value is num && field.min != null
        ? ((value - field.min!) / (field.max! - field.min!)).clamp(0.0, 1.0)
        : null;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _label(label ?? importFieldLabel(_l, _zh, key),
          required: field.required, unsure: unsure),
      TextField(
        key: Key('import-field-$key'),
        controller: _controller(key, value),
        keyboardType: numeric
            ? TextInputType.numberWithOptions(
                decimal: field.kind == ImportFieldKind.decimal, signed: true)
            : TextInputType.text,
        decoration: _decoration(error: error, suffix: suffix, unsure: unsure),
        onChanged: (text) => setState(() {
          final value = text.trim();
          if (value.isEmpty) {
            _data.remove(key);
          } else if (!numeric) {
            _data[key] = value;
          } else {
            final parsed = field.kind == ImportFieldKind.integer
                ? int.tryParse(value.replaceAll(',', ''))
                : double.tryParse(value);
            _data[key] = parsed ?? value;
          }
        }),
      ),
      if (numeric && field.min != null) ...[
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: position?.toDouble() ?? 0,
                minHeight: 3,
                backgroundColor: OnepieceColors.separator,
                color: error == null ? OnepieceColors.fancyBlue : _errorText,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(_range(field),
              style: const TextStyle(
                  fontSize: 10.5, color: OnepieceColors.secondaryLabel)),
        ]),
      ],
    ]);
  }

  Widget _dropdown(String key, String? error) {
    final field = _field(key);
    final value = _data[key]?.toString();
    final unsure = _item.uncertain.contains(key);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _label(importFieldLabel(_l, _zh, key),
          required: field.required, unsure: unsure),
      DropdownButtonFormField<String>(
        key: Key('import-field-$key'),
        initialValue: field.options.contains(value) ? value : null,
        isExpanded: true,
        decoration: _decoration(error: error, unsure: unsure),
        hint: Text(_t('请选择', 'Choose')),
        items: [
          for (final option in field.options)
            DropdownMenuItem(
                value: option, child: Text(importOptionLabel(_l, key, option))),
        ],
        onChanged: (value) => setState(() => _data[key] = value),
      ),
    ]);
  }

  /// One choice (or several) as chips, for short option lists.
  Widget _chips(String key, String? error, {bool multiple = false}) {
    final field = _field(key);
    final selected = multiple
        ? ((_data[key] as List?) ?? const []).map((e) => '$e').toSet()
        : {if (_data[key] != null) '${_data[key]}'};
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _label(importFieldLabel(_l, _zh, key),
          required: field.required, unsure: _item.uncertain.contains(key)),
      Wrap(
        key: Key('import-field-$key'),
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final option in field.options)
            ChoiceChip(
              label: Text(importOptionLabel(_l, key, option)),
              selected: selected.contains(option),
              showCheckmark: multiple,
              selectedColor: OnepieceColors.fancyBlue.withValues(alpha: .14),
              side: BorderSide(
                  color: selected.contains(option)
                      ? OnepieceColors.fancyBlue
                      : OnepieceColors.separator),
              onSelected: (on) => setState(() {
                if (!multiple) {
                  _data[key] = option;
                  return;
                }
                on ? selected.add(option) : selected.remove(option);
                _data[key] = field.options.where(selected.contains).toList();
              }),
            ),
        ],
      ),
      if (error != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(error,
              style: const TextStyle(fontSize: 12, color: _errorText)),
        ),
    ]);
  }

  /// A selectable card for a fruit (on a character) or a character (on a
  /// fruit): ticked when linked, with who else it belongs to.
  Widget _linkCard(
      {required Key key,
      required IconData icon,
      required String title,
      String? subtitle,
      required bool selected,
      required VoidCallback onTap}) {
    return InkWell(
      key: key,
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFEAF6EE)
              : OnepieceColors.surface.withValues(alpha: .6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? const Color(0xFF3E9B62) : Colors.transparent,
              width: 1.4),
        ),
        child: Row(children: [
          Icon(icon,
              size: 18,
              color: selected
                  ? const Color(0xFF247A50)
                  : OnepieceColors.secondaryLabel),
          const SizedBox(width: 8),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: OnepieceColors.primaryLabel)),
              if (subtitle != null)
                Text(subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11.5, color: OnepieceColors.secondaryLabel)),
            ]),
          ),
          Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 18,
              color: selected
                  ? const Color(0xFF3E9B62)
                  : OnepieceColors.separator),
        ]),
      ),
    );
  }

  // ── Sections ───────────────────────────────────────────────────

  Widget _names(Map<String, String> errors) => _section(
        Icons.badge_outlined,
        _t('名称', 'Name'),
        [
          _grid([
            for (final (key, zh, en) in [
              ('zh_CN', '中文名', 'Chinese name'),
              ('en_US', '英文名', 'English name'),
            ])
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _label(_t(zh, en)),
                TextField(
                  key: Key('import-field-name-$key'),
                  controller: _controller('name.$key', _name[key]),
                  decoration: _decoration(
                      error: key == 'zh_CN' ? errors['name'] : null),
                  onChanged: (text) => setState(() => text.trim().isEmpty
                      ? _name.remove(key)
                      : _name[key] = text.trim()),
                ),
              ]),
          ]),
        ],
      );

  List<Widget> _characterSections(Map<String, String> errors) => [
        if (!_item.exists) ...[
          _names(errors),
          _section(Icons.person_outline_rounded, _t('身份', 'Identity'), [
            _grid([
              _dropdown('race', errors['race']),
              _dropdown('battle_style', errors['battle_style']),
            ]),
            const SizedBox(height: 14),
            _chips('hakis', errors['hakis'], multiple: true),
          ]),
          _section(Icons.menu_book_outlined, _t('资料', 'Profile'), [
            _grid(columns: 3, [
              _input('bounty', errors['bounty'], suffix: _t('贝里', 'berries')),
              _input('age', errors['age'], suffix: _t('岁', 'yrs')),
              _input('height', errors['height'], suffix: 'cm'),
              _input('birth_place', errors['birth_place']),
              _input('date_of_birth', errors['date_of_birth']),
            ]),
          ]),
          _section(
            Icons.bolt_rounded,
            _t('战斗属性', 'Combat stats'),
            hint: _t('本应用自己的数值，参照已有角色', 'This app\'s own scale'),
            [
              _grid(columns: 4, [
                for (final key in const [
                  'attack',
                  'defense',
                  'blood',
                  'speed',
                  'intelligence',
                  'energy',
                  'group_gain',
                ])
                  _input(key, errors[key]),
              ]),
            ],
          ),
        ],
        _relations(errors),
      ];

  Widget _relations(Map<String, String> errors) {
    final fruits =
        widget.draft.where((i) => i.type == ImportType.fruit).toList();
    final groups =
        widget.draft.where((i) => i.type == ImportType.group).toList();
    return _section(Icons.link_rounded, _t('关系', 'Relations'), [
      if (fruits.isNotEmpty) ...[
        _label(_item.exists
            ? _t('吃下的果实', 'Fruits eaten')
            : _t('吃下的果实（只能 1 个）', 'Fruit eaten (one)')),
        _grid([
          for (final fruit in fruits)
            _linkCard(
              key: Key('import-link-${fruit.key}'),
              icon: Icons.spa_outlined,
              title: fruit.name(_zh),
              subtitle: _otherHolders(fruit),
              selected: _fruits.contains(fruit.key),
              onTap: () => setState(() {
                if (_fruits.contains(fruit.key)) {
                  _fruits.remove(fruit.key);
                } else {
                  // A new character holds one fruit: picking another replaces it.
                  if (!_item.exists) _fruits.clear();
                  _fruits.add(fruit.key);
                }
              }),
            ),
        ]),
        if (errors['fruits'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(errors['fruits']!,
                style: const TextStyle(fontSize: 12, color: _errorText)),
          ),
        const SizedBox(height: 16),
      ],
      if (groups.isNotEmpty)
        _grid([
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _label(importFieldLabel(_l, _zh, 'group')),
            DropdownButtonFormField<String?>(
              key: const Key('import-field-group'),
              initialValue: _group,
              isExpanded: true,
              decoration: _decoration(),
              items: [
                DropdownMenuItem(value: null, child: Text(_t('不加入', 'None'))),
                for (final group in groups)
                  DropdownMenuItem(
                      value: group.key, child: Text(group.name(_zh))),
              ],
              onChanged: (value) => setState(() => _group = value),
            ),
          ]),
          if (_group != null)
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _label(importFieldLabel(_l, _zh, 'position')),
              DropdownButtonFormField<String>(
                key: const Key('import-field-position'),
                initialValue: _position,
                isExpanded: true,
                decoration: _decoration(),
                items: [
                  for (final position in GroupPosition.values)
                    DropdownMenuItem(
                        value: position.value,
                        child: Text(
                            importOptionLabel(_l, 'position', position.value))),
                ],
                onChanged: (value) =>
                    setState(() => _position = value ?? 'member'),
              ),
            ]),
        ]),
    ]);
  }

  /// Who else in the draft eats [fruit], for a character's fruit cards.
  String? _otherHolders(ImportItem fruit) {
    final others = _characters
        .where((c) => c.key != _item.key && c.fruits.contains(fruit.key))
        .map((c) => c.name(_zh))
        .toList();
    final type = fruit.data['fruit_type'];
    final kind =
        type == null ? null : importOptionLabel(_l, 'fruit_type', '$type');
    if (others.isEmpty) return kind;
    final held =
        _t('已由 ${others.join('、')} 吃下', 'Eaten by ${others.join(', ')}');
    return kind == null ? held : '$kind · $held';
  }

  List<Widget> _fruitSections(Map<String, String> errors) {
    const stats = [
      'attack',
      'defense',
      'blood',
      'group_gain',
      'speed',
      'intelligence'
    ];
    return [
      if (!_item.exists) ...[
        _names(errors),
        _section(Icons.spa_outlined, _t('果实', 'Fruit'), [
          _chips('fruit_type', errors['fruit_type']),
          const SizedBox(height: 14),
          _grid([_input('energy_consume', errors['energy_consume'])]),
        ]),
        _section(
          Icons.auto_graph_rounded,
          _t('效果', 'Effects'),
          hint: _t('持有者的属性 = 属性 × 系数 + 加成', 'stat × slope + bonus'),
          [
            for (final stat in stats) ...[
              _grid([
                _input('${stat}_slope', errors['${stat}_slope'],
                    label:
                        '${importFieldLabel(_l, _zh, stat)} · ${_t('系数', 'slope')}',
                    suffix: '×'),
                _input('${stat}_intercept', errors['${stat}_intercept'],
                    label:
                        '${importFieldLabel(_l, _zh, stat)} · ${_t('加成', 'bonus')}',
                    suffix: '+'),
              ]),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ],
      _section(
          Icons.person_pin_outlined,
          _t('持有者', 'Holders'),
          hint: _t('每个果实都要有吃下它的角色', 'Every fruit needs a character who ate it'),
          [
            if (_characters.isEmpty)
              Text(_t('草稿里还没有角色。', 'There are no characters in the draft yet.'),
                  style: const TextStyle(
                      fontSize: 13, color: OnepieceColors.secondaryLabel))
            else
              _grid([
                for (final character in _characters)
                  _linkCard(
                    key: Key('import-link-${character.key}'),
                    icon: Icons.person_outline_rounded,
                    title: character.name(_zh),
                    subtitle: character.included ? null : _t('不导入', 'Left out'),
                    selected: _holders.contains(character.key),
                    onTap: () => setState(() => _holders.contains(character.key)
                        ? _holders.remove(character.key)
                        : _holders.add(character.key)),
                  ),
              ]),
          ]),
    ];
  }

  List<Widget> _groupSections(Map<String, String> errors) => [
        _names(errors),
        _section(Icons.groups_outlined, _t('团体', 'Group'), [
          _chips('group_category', errors['group_category']),
        ]),
      ];

  // ── Frame ──────────────────────────────────────────────────────

  Widget _header() {
    final other = _preview.name(!_zh);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 14),
      child: Row(children: [
        _portrait(),
        const SizedBox(width: 14),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_preview.name(_zh),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: OnepieceColors.primaryLabel)),
            const SizedBox(height: 2),
            Text(
                [
                  if (other != _preview.name(_zh)) other,
                  _item.exists
                      ? _t('已存在 · 只能修改关系', 'Exists · only relations change')
                      : _t('新建', 'New'),
                ].join(' · '),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12.5, color: OnepieceColors.secondaryLabel)),
          ]),
        ),
        IconButton(
          tooltip: _t('关闭', 'Close'),
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ]),
    );
  }

  Widget _portrait() {
    const side = 48.0;
    final character = _item.type == ImportType.character;
    final radius = character ? side / 2 : 12.0;
    final icon = Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
          color: OnepieceColors.fancyBlue.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(radius)),
      child: Icon(
          switch (_item.type) {
            ImportType.character => Icons.person_outline_rounded,
            ImportType.fruit => Icons.spa_outlined,
            _ => Icons.groups_outlined,
          },
          color: OnepieceColors.fancyBlue),
    );
    final url = _item.useAvatar ? _item.avatarUrl : null;
    if (url == null) return icon;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(url,
          width: side,
          height: side,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (_, __, ___) => icon),
    );
  }

  Widget _footer(Map<String, String> errors) {
    final unsure = _item.exists
        ? 0
        : _item.uncertain.where((k) => _data.containsKey(k)).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Row(children: [
        Expanded(
          child: Text(
            errors.isNotEmpty
                ? _t('还有 ${errors.length} 项需要修改', '${errors.length} to fix')
                : unsure > 0
                    ? _t('$unsure 项 AI 不确定，请核对', '$unsure marked AI unsure')
                    : '',
            style: TextStyle(
                fontSize: 12.5,
                color: errors.isNotEmpty ? _errorText : _unsureText),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(_t('取消', 'Cancel')),
        ),
        const SizedBox(width: 8),
        FilledButton(
          key: const Key('import-editor-save'),
          onPressed: _save,
          style:
              FilledButton.styleFrom(backgroundColor: OnepieceColors.fancyBlue),
          child: Text(_t('保存', 'Save')),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final errors = importFieldErrors(_preview, _zh);
    final sections = switch (_item.type) {
      ImportType.character => _characterSections(errors),
      ImportType.fruit => _fruitSections(errors),
      _ => _groupSections(errors),
    };
    return Material(
      color: Colors.white,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _header(),
        const Divider(height: 1, color: OnepieceColors.separator),
        Flexible(
          child: SingleChildScrollView(
            key: const Key('import-editor-body'),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: sections),
          ),
        ),
        const Divider(height: 1, color: OnepieceColors.separator),
        _footer(errors),
      ]),
    );
  }
}
