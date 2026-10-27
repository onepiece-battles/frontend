import 'dart:convert';

import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';

import '../repository/character_dao.dart';
import '../repository/fruit_dao.dart';
import '../utils/i18n_helper.dart';

final GetIt _getIt = GetIt.instance;

/// A system resource the assistant surfaced in a reply. The chat renders these
/// as chips that deep-link into the resource's detail page.
class ResourceRef {
  const ResourceRef(this.type, this.id, this.name);

  final String type; // character | fruit | battle | group
  final String id;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is ResourceRef && other.type == type && other.id == id;

  @override
  int get hashCode => Object.hash(type, id);
}

/// The outcome of one tool call: JSON [content] handed back to the model, plus
/// the resources it referenced for the UI to link to.
class ToolResult {
  const ToolResult(this.content, this.resources);
  final String content;
  final List<ResourceRef> resources;
}

/// The devil-fruit / character / battle lookups the model may call. Executed
/// locally against the existing DAOs — no new backend.
class ResourceTools {
  static String _name(I18nText? t) =>
      t == null ? '' : I18nHelper.getDisplayNameFromI18n(t);

  static LanguageCode get _lang => I18nHelper.getLanguageCode();

  /// OpenAI / DeepSeek function-tool definitions.
  static List<Map<String, dynamic>> definitions() => [
        _fn('search_characters',
            'Search characters by (partial) name. Returns id, name, combat power, bounty and haki.',
            {
              'name': {'type': 'string', 'description': 'Character name or part of it'}
            },
            ['name']),
        _fn('get_character_detail',
            'Full profile of a character by name: all combat stats, devil fruits, crews and battle history (opponent + win/lose).',
            {
              'name': {'type': 'string'}
            },
            ['name']),
        _fn('list_top_characters',
            'List the strongest characters by combat power, highest first.',
            {
              'limit': {'type': 'integer', 'description': 'How many, 1-10'}
            },
            []),
        _fn('search_fruits',
            'Search devil fruits by (partial) name. Returns id, name, type and current holders.',
            {
              'name': {'type': 'string'}
            },
            ['name']),
        _fn('get_fruit_holders',
            'Who ate / currently holds a devil fruit, by fruit name.', {
          'name': {'type': 'string'}
        }, [
          'name'
        ]),
        _fn('list_fruits_by_type',
            'List devil fruits of a given type and their holders. Use this for '
                'questions like "all Ancient Zoan users".',
            {
              'type': {
                'type': 'string',
                'description':
                    'One of: Paramecia, Logia, Zoan, Ancient_Zoan, Mythical_Zoan, Artificial_Zoan',
              }
            },
            ['type']),
        _fn('propose_battle',
            'Propose a battle between two characters so the user can create it. '
                'Call this when the user wants to simulate or create a fight (e.g. '
                '"who would win, A vs B", "create a battle between A and B").',
            {
              'starter_name': {'type': 'string'},
              'receiver_name': {'type': 'string'},
            },
            ['starter_name', 'receiver_name']),
      ];

  static Map<String, dynamic> _fn(String name, String desc,
          Map<String, dynamic> props, List<String> required) =>
      {
        'type': 'function',
        'function': {
          'name': name,
          'description': desc,
          'parameters': {
            'type': 'object',
            'properties': props,
            'required': required,
          },
        },
      };

  static Future<ToolResult> execute(String name, Map<String, dynamic> args) async {
    try {
      switch (name) {
        case 'search_characters':
          return _searchCharacters('${args['name'] ?? ''}');
        case 'get_character_detail':
          return _characterDetail('${args['name'] ?? ''}');
        case 'list_top_characters':
          return _topCharacters((args['limit'] as num?)?.toInt() ?? 5);
        case 'search_fruits':
          return _searchFruits('${args['name'] ?? ''}');
        case 'get_fruit_holders':
          return _fruitHolders('${args['name'] ?? ''}');
        case 'list_fruits_by_type':
          return _fruitsByType('${args['type'] ?? ''}');
        case 'propose_battle':
          return _proposeBattle(
              '${args['starter_name'] ?? ''}', '${args['receiver_name'] ?? ''}');
      }
      return const ToolResult('{"error":"unknown tool"}', []);
    } catch (e) {
      return ToolResult(jsonEncode({'error': e.toString()}), const []);
    }
  }

  static Future<ListCharacterResponse?> _listChars(CharacterFilter f,
          {int size = 6, List<CharacterSortableField> sort = const []}) =>
      _getIt<CharacterDao>().listCharacter(ListCharacterRequest(
          pageSize: size, pageIndex: 1, sortKeys: sort, characterFilter: f));

  static Future<ToolResult> _searchCharacters(String name) async {
    final resp = await _listChars(CharacterFilter(name: name, languageCode: _lang));
    final chars = resp?.characters ?? [];
    final refs = chars.map((c) => ResourceRef('character', c.id, _name(c.name)));
    final data = chars
        .map((c) => {
              'id': c.id,
              'name': _name(c.name),
              'combat_power': c.score,
              'bounty': c.bounty,
              'haki': c.hakis.map((h) => h.toString()).toList(),
            })
        .toList();
    return ToolResult(jsonEncode({'characters': data}), refs.toList());
  }

  static Future<ToolResult> _topCharacters(int limit) async {
    final n = limit.clamp(1, 10);
    final resp = await _listChars(CharacterFilter(languageCode: _lang),
        size: n,
        sort: [
          CharacterSortableField(
              sortKey: CharacterSortableFieldsEnum.score,
              sortOrder: SortOrder.DESC)
        ]);
    final chars = resp?.characters ?? [];
    final refs = chars.map((c) => ResourceRef('character', c.id, _name(c.name)));
    final data = chars
        .map((c) => {'id': c.id, 'name': _name(c.name), 'combat_power': c.score, 'bounty': c.bounty})
        .toList();
    return ToolResult(jsonEncode({'top_characters': data}), refs.toList());
  }

  static Future<ToolResult> _characterDetail(String name) async {
    final list = await _listChars(CharacterFilter(name: name, languageCode: _lang),
        size: 1);
    final match = (list?.characters ?? []).isEmpty ? null : list!.characters.first;
    if (match == null) {
      return ToolResult(jsonEncode({'found': false, 'query': name}), const []);
    }
    final full = await _getIt<CharacterDao>()
        .getCharacter(GetCharacterFullViewRequest(characterId: match.id));
    if (full == null) {
      return ToolResult(jsonEncode({'found': false}), const []);
    }
    final refs = <ResourceRef>[ResourceRef('character', full.id, _name(full.name))];
    for (final f in full.fruits) {
      refs.add(ResourceRef('fruit', f.id!, _name(f.name)));
    }
    final battles = full.battles.take(8).map((b) {
      final isStarter = b.starterId == full.id;
      final opp = isStarter ? b.receiver : b.starter;
      final winnerId = b.battleExecution?.winnerId;
      final result = winnerId == null
          ? 'undecided'
          : (winnerId == full.id ? 'win' : 'lose');
      final oppName = _name(opp?.name);
      if (b.id.isNotEmpty) {
        refs.add(ResourceRef(
            'battle', b.id, oppName.isEmpty ? _name(full.name) : 'vs $oppName'));
      }
      return {'battle_id': b.id, 'opponent': oppName, 'result': result};
    }).toList();
    final data = {
      'id': full.id,
      'name': _name(full.name),
      'combat_power': full.score,
      'bounty': full.bounty,
      'stats': {
        'attack': full.attack,
        'defense': full.defense,
        'intelligence': full.intelligence,
        'blood': full.blood,
        'speed': full.speed,
        'group_gain': full.groupGain,
        'energy': full.energy,
      },
      'haki': full.hakis.map((h) => h.toString()).toList(),
      'devil_fruits': full.fruits.map((f) => _name(f.name)).toList(),
      'crews': full.groups.map((g) => _name(g.name)).toList(),
      'battles': battles,
    };
    return ToolResult(jsonEncode(data), refs);
  }

  static Future<ToolResult> _searchFruits(String name) async {
    final resp = await _getIt<FruitDao>().list(ListFruitRequest(
        pageSize: 6,
        pageIndex: 1,
        sortKeys: [],
        fruitFilter: FruitFilter(name: name, languageCode: _lang)));
    final fruits = resp?.fruits ?? [];
    final refs = <ResourceRef>[];
    final data = fruits.map((f) {
      refs.add(ResourceRef('fruit', f.id!, _name(f.name)));
      final holders = f.characters.map((h) {
        refs.add(ResourceRef('character', h.id, _name(h.name)));
        return {'id': h.id, 'name': _name(h.name)};
      }).toList();
      return {
        'id': f.id,
        'name': _name(f.name),
        'type': f.fruitType?.toString(),
        'holders': holders,
      };
    }).toList();
    return ToolResult(jsonEncode({'fruits': data}), refs);
  }

  static Future<ToolResult> _fruitHolders(String name) async {
    final result = await _searchFruits(name);
    return result; // same data; holders are included.
  }

  static FruitType? _parseFruitType(String raw) {
    final t = raw.trim().toLowerCase().replaceAll(' ', '_');
    switch (t) {
      case 'paramecia':
      case '超人系':
        return FruitType.paramecia;
      case 'logia':
      case '自然系':
        return FruitType.logia;
      case 'zoan':
      case '动物系':
        return FruitType.zoan;
      case 'ancient_zoan':
      case 'ancientzoan':
      case '古代种':
        return FruitType.ancientZoan;
      case 'mythical_zoan':
      case 'mythicalzoan':
      case '幻兽种':
      case '神话种':
        return FruitType.mythicalZoan;
      case 'artificial_zoan':
      case 'artificialzoan':
      case '人造':
      case '人造恶魔果实':
        return FruitType.artificialZoan;
    }
    return null;
  }

  static Future<ToolResult> _fruitsByType(String rawType) async {
    final type = _parseFruitType(rawType);
    if (type == null) {
      return ToolResult(
          jsonEncode({'error': 'unknown fruit type', 'query': rawType}), const []);
    }
    final resp = await _getIt<FruitDao>().list(ListFruitRequest(
        pageSize: 30,
        pageIndex: 1,
        sortKeys: [],
        fruitFilter: FruitFilter(types: [type], languageCode: _lang)));
    final fruits = resp?.fruits ?? [];
    final refs = <ResourceRef>[];
    final data = fruits.map((f) {
      refs.add(ResourceRef('fruit', f.id!, _name(f.name)));
      final holders = f.characters.map((h) {
        refs.add(ResourceRef('character', h.id, _name(h.name)));
        return {'id': h.id, 'name': _name(h.name)};
      }).toList();
      return {
        'id': f.id,
        'name': _name(f.name),
        'type': f.fruitType?.toString(),
        'holders': holders,
      };
    }).toList();
    return ToolResult(
        jsonEncode({'type': type.toString(), 'count': data.length, 'fruits': data}),
        refs);
  }

  static Future<CharacterListView?> _findOneCharacter(String name) async {
    final resp =
        await _listChars(CharacterFilter(name: name, languageCode: _lang), size: 1);
    final chars = resp?.characters ?? [];
    return chars.isEmpty ? null : chars.first;
  }

  static Future<ToolResult> _proposeBattle(
      String starterName, String receiverName) async {
    final starter = await _findOneCharacter(starterName);
    final receiver = await _findOneCharacter(receiverName);
    if (starter == null || receiver == null) {
      return ToolResult(
          jsonEncode({
            'proposed': false,
            'starter_found': starter != null,
            'receiver_found': receiver != null,
          }),
          const []);
    }
    final sName = _name(starter.name);
    final rName = _name(receiver.name);
    final refs = <ResourceRef>[
      ResourceRef('character', starter.id, sName),
      ResourceRef('character', receiver.id, rName),
      // Consumed by the UI to show a Confirm/Cancel battle card (id = "starter|receiver").
      ResourceRef('battle_proposal', '${starter.id}|${receiver.id}', '$sName vs $rName'),
    ];
    return ToolResult(
        jsonEncode({
          'proposed': true,
          'starter': {'id': starter.id, 'name': sName},
          'receiver': {'id': receiver.id, 'name': rName},
          'note': 'A battle proposal card with Confirm/Cancel is shown to the user. '
              'Do not output a onepiece:// link for this; just briefly say you prepared it.',
        }),
        refs);
  }
}
