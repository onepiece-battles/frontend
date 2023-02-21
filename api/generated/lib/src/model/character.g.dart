// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Character extends Character {
  @override
  final String id;
  @override
  final CharacterType characterType;
  @override
  final String name;
  @override
  final String? groupOid;
  @override
  final bool hasFruits;
  @override
  final BuiltList<FruitInCharacter>? fruits;
  @override
  final int fruitLimit;
  @override
  final int groupGain;
  @override
  final int attack;
  @override
  final int defense;
  @override
  final int intelligence;
  @override
  final int blood;
  @override
  final int speed;
  @override
  final int magic;

  factory _$Character([void Function(CharacterBuilder)? updates]) =>
      (new CharacterBuilder()..update(updates)).build();

  _$Character._(
      {required this.id,
      required this.characterType,
      required this.name,
      this.groupOid,
      required this.hasFruits,
      this.fruits,
      required this.fruitLimit,
      required this.groupGain,
      required this.attack,
      required this.defense,
      required this.intelligence,
      required this.blood,
      required this.speed,
      required this.magic})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(id, 'Character', 'id');
    BuiltValueNullFieldError.checkNotNull(
        characterType, 'Character', 'characterType');
    BuiltValueNullFieldError.checkNotNull(name, 'Character', 'name');
    BuiltValueNullFieldError.checkNotNull(hasFruits, 'Character', 'hasFruits');
    BuiltValueNullFieldError.checkNotNull(
        fruitLimit, 'Character', 'fruitLimit');
    BuiltValueNullFieldError.checkNotNull(groupGain, 'Character', 'groupGain');
    BuiltValueNullFieldError.checkNotNull(attack, 'Character', 'attack');
    BuiltValueNullFieldError.checkNotNull(defense, 'Character', 'defense');
    BuiltValueNullFieldError.checkNotNull(
        intelligence, 'Character', 'intelligence');
    BuiltValueNullFieldError.checkNotNull(blood, 'Character', 'blood');
    BuiltValueNullFieldError.checkNotNull(speed, 'Character', 'speed');
    BuiltValueNullFieldError.checkNotNull(magic, 'Character', 'magic');
  }

  @override
  Character rebuild(void Function(CharacterBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CharacterBuilder toBuilder() => new CharacterBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Character &&
        id == other.id &&
        characterType == other.characterType &&
        name == other.name &&
        groupOid == other.groupOid &&
        hasFruits == other.hasFruits &&
        fruits == other.fruits &&
        fruitLimit == other.fruitLimit &&
        groupGain == other.groupGain &&
        attack == other.attack &&
        defense == other.defense &&
        intelligence == other.intelligence &&
        blood == other.blood &&
        speed == other.speed &&
        magic == other.magic;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc(
                        $jc(
                            $jc(
                                $jc(
                                    $jc(
                                        $jc(
                                            $jc(
                                                $jc(
                                                    $jc($jc(0, id.hashCode),
                                                        characterType.hashCode),
                                                    name.hashCode),
                                                groupOid.hashCode),
                                            hasFruits.hashCode),
                                        fruits.hashCode),
                                    fruitLimit.hashCode),
                                groupGain.hashCode),
                            attack.hashCode),
                        defense.hashCode),
                    intelligence.hashCode),
                blood.hashCode),
            speed.hashCode),
        magic.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Character')
          ..add('id', id)
          ..add('characterType', characterType)
          ..add('name', name)
          ..add('groupOid', groupOid)
          ..add('hasFruits', hasFruits)
          ..add('fruits', fruits)
          ..add('fruitLimit', fruitLimit)
          ..add('groupGain', groupGain)
          ..add('attack', attack)
          ..add('defense', defense)
          ..add('intelligence', intelligence)
          ..add('blood', blood)
          ..add('speed', speed)
          ..add('magic', magic))
        .toString();
  }
}

class CharacterBuilder implements Builder<Character, CharacterBuilder> {
  _$Character? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  CharacterType? _characterType;
  CharacterType? get characterType => _$this._characterType;
  set characterType(CharacterType? characterType) =>
      _$this._characterType = characterType;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _groupOid;
  String? get groupOid => _$this._groupOid;
  set groupOid(String? groupOid) => _$this._groupOid = groupOid;

  bool? _hasFruits;
  bool? get hasFruits => _$this._hasFruits;
  set hasFruits(bool? hasFruits) => _$this._hasFruits = hasFruits;

  ListBuilder<FruitInCharacter>? _fruits;
  ListBuilder<FruitInCharacter> get fruits =>
      _$this._fruits ??= new ListBuilder<FruitInCharacter>();
  set fruits(ListBuilder<FruitInCharacter>? fruits) => _$this._fruits = fruits;

  int? _fruitLimit;
  int? get fruitLimit => _$this._fruitLimit;
  set fruitLimit(int? fruitLimit) => _$this._fruitLimit = fruitLimit;

  int? _groupGain;
  int? get groupGain => _$this._groupGain;
  set groupGain(int? groupGain) => _$this._groupGain = groupGain;

  int? _attack;
  int? get attack => _$this._attack;
  set attack(int? attack) => _$this._attack = attack;

  int? _defense;
  int? get defense => _$this._defense;
  set defense(int? defense) => _$this._defense = defense;

  int? _intelligence;
  int? get intelligence => _$this._intelligence;
  set intelligence(int? intelligence) => _$this._intelligence = intelligence;

  int? _blood;
  int? get blood => _$this._blood;
  set blood(int? blood) => _$this._blood = blood;

  int? _speed;
  int? get speed => _$this._speed;
  set speed(int? speed) => _$this._speed = speed;

  int? _magic;
  int? get magic => _$this._magic;
  set magic(int? magic) => _$this._magic = magic;

  CharacterBuilder() {
    Character._defaults(this);
  }

  CharacterBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _characterType = $v.characterType;
      _name = $v.name;
      _groupOid = $v.groupOid;
      _hasFruits = $v.hasFruits;
      _fruits = $v.fruits?.toBuilder();
      _fruitLimit = $v.fruitLimit;
      _groupGain = $v.groupGain;
      _attack = $v.attack;
      _defense = $v.defense;
      _intelligence = $v.intelligence;
      _blood = $v.blood;
      _speed = $v.speed;
      _magic = $v.magic;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Character other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$Character;
  }

  @override
  void update(void Function(CharacterBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Character build() {
    _$Character _$result;
    try {
      _$result = _$v ??
          new _$Character._(
              id: BuiltValueNullFieldError.checkNotNull(id, 'Character', 'id'),
              characterType: BuiltValueNullFieldError.checkNotNull(
                  characterType, 'Character', 'characterType'),
              name: BuiltValueNullFieldError.checkNotNull(
                  name, 'Character', 'name'),
              groupOid: groupOid,
              hasFruits: BuiltValueNullFieldError.checkNotNull(
                  hasFruits, 'Character', 'hasFruits'),
              fruits: _fruits?.build(),
              fruitLimit: BuiltValueNullFieldError.checkNotNull(
                  fruitLimit, 'Character', 'fruitLimit'),
              groupGain: BuiltValueNullFieldError.checkNotNull(
                  groupGain, 'Character', 'groupGain'),
              attack: BuiltValueNullFieldError.checkNotNull(
                  attack, 'Character', 'attack'),
              defense: BuiltValueNullFieldError.checkNotNull(
                  defense, 'Character', 'defense'),
              intelligence: BuiltValueNullFieldError.checkNotNull(
                  intelligence, 'Character', 'intelligence'),
              blood: BuiltValueNullFieldError.checkNotNull(
                  blood, 'Character', 'blood'),
              speed: BuiltValueNullFieldError.checkNotNull(
                  speed, 'Character', 'speed'),
              magic: BuiltValueNullFieldError.checkNotNull(magic, 'Character', 'magic'));
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'fruits';
        _fruits?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'Character', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
