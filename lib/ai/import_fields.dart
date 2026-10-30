import 'package:openapi/api.dart';

import '../l10n/app_localizations.dart';
import 'import_models.dart';

enum ImportFieldKind { text, integer, decimal, choice, choices }

/// One editable create field of an import item. Ranges are those of the app's
/// own create forms, as are the server's (ActionSchemas), which re-validate
/// everything on import.
class ImportField {
  const ImportField(
    this.key,
    this.kind, {
    this.min,
    this.max,
    this.maxLength = 200,
    this.options = const [],
    this.required = false,
  });

  final String key;
  final ImportFieldKind kind;
  final num? min;
  final num? max;
  final int maxLength;
  final List<String> options;
  final bool required;

  /// Why [value] is not acceptable, or null when it is.
  String? check(Object? value, bool zh) {
    if (value == null || (value is String && value.trim().isEmpty)) {
      return required ? (zh ? '必填' : 'Required') : null;
    }
    switch (kind) {
      case ImportFieldKind.integer:
      case ImportFieldKind.decimal:
        if (value is! num ||
            (kind == ImportFieldKind.integer &&
                value != value.roundToDouble())) {
          return zh ? '需要数字' : 'Must be a number';
        }
        if ((min != null && value < min!) || (max != null && value > max!)) {
          return zh
              ? '范围 ${_n(min)}–${_n(max)}'
              : 'Range ${_n(min)}–${_n(max)}';
        }
      case ImportFieldKind.text:
        if (value.toString().length > maxLength) {
          return zh ? '最多 $maxLength 字' : 'At most $maxLength characters';
        }
      case ImportFieldKind.choice:
        if (!options.contains(value.toString())) {
          return zh ? '请选择' : 'Choose a value';
        }
      case ImportFieldKind.choices:
        if (value is! List || value.any((v) => !options.contains(v))) {
          return zh ? '请选择' : 'Choose values';
        }
    }
    return null;
  }

  static String _n(num? value) => value == null
      ? ''
      : (value == value.roundToDouble() ? '${value.toInt()}' : '$value');
}

const _stats = [
  'attack',
  'defense',
  'blood',
  'group_gain',
  'speed',
  'intelligence'
];
const _slopeMax = [1.5, 1.5, 1.5, 2, 3, 2];
const _interceptMin = [-100, -100, -1000, -10, -10, -30];
const _interceptMax = [300, 800, 3000, 30, 30, 30];

final characterFields = <ImportField>[
  ImportField('race', ImportFieldKind.choice,
      options: Race.values.map((e) => e.value).toList(), required: true),
  ImportField('battle_style', ImportFieldKind.choice,
      options: BattleStyle.values.map((e) => e.value).toList(), required: true),
  ImportField('hakis', ImportFieldKind.choices,
      options: Haki.values.map((e) => e.value).toList()),
  const ImportField('bounty', ImportFieldKind.integer,
      min: 10, max: 100000000000),
  const ImportField('age', ImportFieldKind.integer, min: 0, max: 100000),
  const ImportField('height', ImportFieldKind.integer, min: 1, max: 100000),
  const ImportField('birth_place', ImportFieldKind.text),
  const ImportField('date_of_birth', ImportFieldKind.text, maxLength: 100),
  // A new character holds one fruit (only Blackbeard held two; he exists).
  const ImportField('maximum_fruit_count', ImportFieldKind.integer,
      min: 1, max: 1, required: true),
  const ImportField('group_gain', ImportFieldKind.integer,
      min: 100, max: 200, required: true),
  const ImportField('attack', ImportFieldKind.integer,
      min: 10, max: 1500, required: true),
  const ImportField('defense', ImportFieldKind.integer,
      min: 10, max: 1400, required: true),
  const ImportField('blood', ImportFieldKind.integer,
      min: 100, max: 10000, required: true),
  const ImportField('speed', ImportFieldKind.integer,
      min: 10, max: 200, required: true),
  const ImportField('intelligence', ImportFieldKind.integer,
      min: 70, max: 260, required: true),
  const ImportField('energy', ImportFieldKind.integer,
      min: 100, max: 300, required: true),
];

final fruitFields = <ImportField>[
  ImportField('fruit_type', ImportFieldKind.choice,
      options: FruitType.values.map((e) => e.value).toList(), required: true),
  const ImportField('energy_consume', ImportFieldKind.integer,
      min: 1, max: 10, required: true),
  for (var i = 0; i < _stats.length; i++) ...[
    ImportField('${_stats[i]}_slope', ImportFieldKind.decimal,
        min: 0.8, max: _slopeMax[i], required: true),
    ImportField('${_stats[i]}_intercept', ImportFieldKind.integer,
        min: _interceptMin[i], max: _interceptMax[i], required: true),
  ],
];

final groupFields = <ImportField>[
  ImportField('group_category', ImportFieldKind.choice,
      options: GroupCategory.values
          .where((e) => e != GroupCategory.group)
          .map((e) => e.value)
          .toList(),
      required: true),
];

List<ImportField> importFields(String type) => switch (type) {
      ImportType.character => characterFields,
      ImportType.fruit => fruitFields,
      _ => groupFields,
    };

/// Every field of [item] that still needs fixing (field key → reason), the
/// name included. Existing items are reused as they are.
Map<String, String> importFieldErrors(ImportItem item, bool zh) {
  if (item.exists) return const {};
  final errors = <String, String>{};
  final name = item.data['name'];
  final zhName = name is Map ? (name['zh_CN'] ?? '').toString().trim() : '';
  final enName = name is Map ? (name['en_US'] ?? '').toString().trim() : '';
  if (zhName.isEmpty && enName.isEmpty) errors['name'] = zh ? '必填' : 'Required';
  if (zhName.length > 100 || enName.length > 100) {
    errors['name'] = zh ? '最多 100 字' : 'At most 100 characters';
  }
  for (final field in importFields(item.type)) {
    final error = field.check(item.data[field.key], zh);
    if (error != null) errors[field.key] = error;
  }
  if (item.type == ImportType.character) {
    final capacity = item.data['maximum_fruit_count'];
    if (capacity is num && item.fruits.length > capacity) {
      errors['fruits'] = zh ? '超过果实数量上限' : 'More fruits than the capacity';
    }
  }
  return errors;
}

String importFieldLabel(AppLocalizations l, bool zh, String key) {
  if (key.endsWith('_slope') || key.endsWith('_intercept')) {
    final stat = key.substring(0, key.lastIndexOf('_'));
    final base = importFieldLabel(l, zh, stat);
    return key.endsWith('_slope')
        ? (zh ? '$base系数' : '$base slope')
        : (zh ? '$base加成' : '$base bonus');
  }
  return switch (key) {
    'name' => zh ? '名称' : 'Name',
    'race' => zh ? '种族' : 'Race',
    'battle_style' => zh ? '战斗风格' : 'Battle style',
    'hakis' => zh ? '霸气' : 'Haki',
    'bounty' => zh ? '悬赏' : 'Bounty',
    'age' => zh ? '年龄' : 'Age',
    'height' => zh ? '身高' : 'Height',
    'birth_place' => zh ? '出生地' : 'Birthplace',
    'date_of_birth' => zh ? '生日' : 'Birthday',
    'maximum_fruit_count' => zh ? '果实上限' : 'Fruit capacity',
    'group_gain' => zh ? '团队加成' : 'Crew bonus',
    'attack' => zh ? '攻击' : 'Attack',
    'defense' => zh ? '防御' : 'Defense',
    'blood' => zh ? '血量' : 'Health',
    'speed' => zh ? '速度' : 'Speed',
    'intelligence' => zh ? '智力' : 'Intelligence',
    'energy' => zh ? '精力' : 'Energy',
    'fruit_type' => zh ? '果实类型' : 'Fruit type',
    'energy_consume' => zh ? '精力消耗' : 'Energy cost',
    'group_category' => zh ? '团体类型' : 'Group type',
    'fruits' => zh ? '果实' : 'Fruits',
    'group' => zh ? '团体' : 'Group',
    'position' => zh ? '职位' : 'Position',
    _ => key,
  };
}

/// The display name of an option of a choice field (or a group position).
String importOptionLabel(AppLocalizations l, String field, String value) {
  final label = switch (field) {
    'race' => {
        'HUMAN': l.human,
        'FISH_MAN': l.fishman,
        'MERFOLK': l.merfolk,
        'GIANT': l.giant,
        'LONG_ARM': l.longArm,
        'LONG_LEG': l.longLeg,
        'SNAKE_NECK': l.snakeNeck,
        'THREE_EYE': l.threeEye,
        'LUNARIAN': l.lunarian,
        'MINK': l.mink,
        'WORLD_NOBEL': l.worldNobel,
        'DWARVES': l.dwarves,
        'NO_LIFE_OBJECT': l.lifeless_object,
        'ANIMAL': l.animal,
        'SOUL': l.soul,
      }[value],
    'battle_style' => {
        'BODY': l.body,
        'SCIENCE': l.science,
        'KATANA': l.katana,
        'SHOOTER': l.shoot,
        'STICK': l.stick,
        'RIFLE': l.rifle,
        'SWORD': l.sword,
      }[value],
    'hakis' => {
        'Busoshoku': l.busoshoku,
        'Haoshoku': l.haoshoku,
        'Kenbunshoku': l.kenbunshoku,
      }[value],
    'fruit_type' => {
        'Logia': l.logiaFruit,
        'Zoan': l.zoanFruit,
        'Ancient_Zoan': l.ancientZoanFruit,
        'Mythical_Zoan': l.mythicalZoanFruit,
        'Artificial_Zoan': l.artificialZoanFruit,
        'Paramecia': l.parameciaFruit,
      }[value],
    'group_category' => {
        'marine': l.marine,
        'pirate': l.pirate,
        'group': l.group,
        'other': l.otherType,
        'under_world': l.underworld,
        'government': l.worldGovernment,
        'revolution_army': l.revolutionaryArmy,
      }[value],
    'position' => {
        'member': l.member,
        'captain': l.caption,
        'combatant': l.combatant,
        'cook': l.cook,
        'doctor': l.doctor,
        'first_mate': l.firstMate,
        'helmsman': l.helmsman,
        'intern': l.intern,
        'musician': l.musician,
        'navigator': l.navigator,
        'scholar': l.scholar,
        'shipwright': l.shipwright,
      }[value],
    _ => null,
  };
  return label ?? value;
}
