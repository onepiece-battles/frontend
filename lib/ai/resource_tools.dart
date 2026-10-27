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
}
