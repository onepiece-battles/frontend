// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_character_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AddCharacterRequest extends AddCharacterRequest {
  @override
  final CharacterType characterType;
  @override
  final String name;
  @override
  final String? groupOid;
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

  factory _$AddCharacterRequest(
          [void Function(AddCharacterRequestBuilder)? updates]) =>
      (new AddCharacterRequestBuilder()..update(updates)).build();

  _$AddCharacterRequest._(
      {required this.characterType,
      required this.name,
      this.groupOid,
      required this.fruitLimit,
      required this.groupGain,
      required this.attack,
      required this.defense,
      required this.intelligence,
      required this.blood,
      required this.speed,
      required this.magic})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        characterType, 'AddCharacterRequest', 'characterType');
    BuiltValueNullFieldError.checkNotNull(name, 'AddCharacterRequest', 'name');
    BuiltValueNullFieldError.checkNotNull(
        fruitLimit, 'AddCharacterRequest', 'fruitLimit');
    BuiltValueNullFieldError.checkNotNull(
        groupGain, 'AddCharacterRequest', 'groupGain');
    BuiltValueNullFieldError.checkNotNull(
        attack, 'AddCharacterRequest', 'attack');
    BuiltValueNullFieldError.checkNotNull(
        defense, 'AddCharacterRequest', 'defense');
    BuiltValueNullFieldError.checkNotNull(
        intelligence, 'AddCharacterRequest', 'intelligence');
    BuiltValueNullFieldError.checkNotNull(
        blood, 'AddCharacterRequest', 'blood');
    BuiltValueNullFieldError.checkNotNull(
        speed, 'AddCharacterRequest', 'speed');
    BuiltValueNullFieldError.checkNotNull(
        magic, 'AddCharacterRequest', 'magic');
  }

  @override
  AddCharacterRequest rebuild(
          void Function(AddCharacterRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AddCharacterRequestBuilder toBuilder() =>
      new AddCharacterRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AddCharacterRequest &&
        characterType == other.characterType &&
        name == other.name &&
        groupOid == other.groupOid &&
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
                                        $jc($jc(0, characterType.hashCode),
                                            name.hashCode),
                                        groupOid.hashCode),
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
    return (newBuiltValueToStringHelper('AddCharacterRequest')
          ..add('characterType', characterType)
          ..add('name', name)
          ..add('groupOid', groupOid)
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

class AddCharacterRequestBuilder
    implements Builder<AddCharacterRequest, AddCharacterRequestBuilder> {
  _$AddCharacterRequest? _$v;

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

  AddCharacterRequestBuilder() {
    AddCharacterRequest._defaults(this);
  }

  AddCharacterRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _characterType = $v.characterType;
      _name = $v.name;
      _groupOid = $v.groupOid;
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
  void replace(AddCharacterRequest other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$AddCharacterRequest;
  }

  @override
  void update(void Function(AddCharacterRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$AddCharacterRequest build() {
    final _$result = _$v ??
        new _$AddCharacterRequest._(
            characterType: BuiltValueNullFieldError.checkNotNull(
                characterType, 'AddCharacterRequest', 'characterType'),
            name: BuiltValueNullFieldError.checkNotNull(
                name, 'AddCharacterRequest', 'name'),
            groupOid: groupOid,
            fruitLimit: BuiltValueNullFieldError.checkNotNull(
                fruitLimit, 'AddCharacterRequest', 'fruitLimit'),
            groupGain: BuiltValueNullFieldError.checkNotNull(
                groupGain, 'AddCharacterRequest', 'groupGain'),
            attack: BuiltValueNullFieldError.checkNotNull(
                attack, 'AddCharacterRequest', 'attack'),
            defense: BuiltValueNullFieldError.checkNotNull(
                defense, 'AddCharacterRequest', 'defense'),
            intelligence: BuiltValueNullFieldError.checkNotNull(
                intelligence, 'AddCharacterRequest', 'intelligence'),
            blood: BuiltValueNullFieldError.checkNotNull(
                blood, 'AddCharacterRequest', 'blood'),
            speed:
                BuiltValueNullFieldError.checkNotNull(speed, 'AddCharacterRequest', 'speed'),
            magic: BuiltValueNullFieldError.checkNotNull(magic, 'AddCharacterRequest', 'magic'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
