// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_fruit_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AddFruitRequest extends AddFruitRequest {
  @override
  final String? name;
  @override
  final FruitType? fruitType;
  @override
  final int? groupGainStrengthen;
  @override
  final int? magicConsume;
  @override
  final int? attackStrengthen;
  @override
  final int? defenseStrengthen;
  @override
  final int? intelligenceStrengthen;
  @override
  final int? bloodStrengthen;
  @override
  final int? speedStrengthen;

  factory _$AddFruitRequest([void Function(AddFruitRequestBuilder)? updates]) =>
      (new AddFruitRequestBuilder()..update(updates)).build();

  _$AddFruitRequest._(
      {this.name,
      this.fruitType,
      this.groupGainStrengthen,
      this.magicConsume,
      this.attackStrengthen,
      this.defenseStrengthen,
      this.intelligenceStrengthen,
      this.bloodStrengthen,
      this.speedStrengthen})
      : super._();

  @override
  AddFruitRequest rebuild(void Function(AddFruitRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AddFruitRequestBuilder toBuilder() =>
      new AddFruitRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AddFruitRequest &&
        name == other.name &&
        fruitType == other.fruitType &&
        groupGainStrengthen == other.groupGainStrengthen &&
        magicConsume == other.magicConsume &&
        attackStrengthen == other.attackStrengthen &&
        defenseStrengthen == other.defenseStrengthen &&
        intelligenceStrengthen == other.intelligenceStrengthen &&
        bloodStrengthen == other.bloodStrengthen &&
        speedStrengthen == other.speedStrengthen;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc(
                        $jc(
                            $jc($jc($jc(0, name.hashCode), fruitType.hashCode),
                                groupGainStrengthen.hashCode),
                            magicConsume.hashCode),
                        attackStrengthen.hashCode),
                    defenseStrengthen.hashCode),
                intelligenceStrengthen.hashCode),
            bloodStrengthen.hashCode),
        speedStrengthen.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('AddFruitRequest')
          ..add('name', name)
          ..add('fruitType', fruitType)
          ..add('groupGainStrengthen', groupGainStrengthen)
          ..add('magicConsume', magicConsume)
          ..add('attackStrengthen', attackStrengthen)
          ..add('defenseStrengthen', defenseStrengthen)
          ..add('intelligenceStrengthen', intelligenceStrengthen)
          ..add('bloodStrengthen', bloodStrengthen)
          ..add('speedStrengthen', speedStrengthen))
        .toString();
  }
}

class AddFruitRequestBuilder
    implements Builder<AddFruitRequest, AddFruitRequestBuilder> {
  _$AddFruitRequest? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  FruitType? _fruitType;
  FruitType? get fruitType => _$this._fruitType;
  set fruitType(FruitType? fruitType) => _$this._fruitType = fruitType;

  int? _groupGainStrengthen;
  int? get groupGainStrengthen => _$this._groupGainStrengthen;
  set groupGainStrengthen(int? groupGainStrengthen) =>
      _$this._groupGainStrengthen = groupGainStrengthen;

  int? _magicConsume;
  int? get magicConsume => _$this._magicConsume;
  set magicConsume(int? magicConsume) => _$this._magicConsume = magicConsume;

  int? _attackStrengthen;
  int? get attackStrengthen => _$this._attackStrengthen;
  set attackStrengthen(int? attackStrengthen) =>
      _$this._attackStrengthen = attackStrengthen;

  int? _defenseStrengthen;
  int? get defenseStrengthen => _$this._defenseStrengthen;
  set defenseStrengthen(int? defenseStrengthen) =>
      _$this._defenseStrengthen = defenseStrengthen;

  int? _intelligenceStrengthen;
  int? get intelligenceStrengthen => _$this._intelligenceStrengthen;
  set intelligenceStrengthen(int? intelligenceStrengthen) =>
      _$this._intelligenceStrengthen = intelligenceStrengthen;

  int? _bloodStrengthen;
  int? get bloodStrengthen => _$this._bloodStrengthen;
  set bloodStrengthen(int? bloodStrengthen) =>
      _$this._bloodStrengthen = bloodStrengthen;

  int? _speedStrengthen;
  int? get speedStrengthen => _$this._speedStrengthen;
  set speedStrengthen(int? speedStrengthen) =>
      _$this._speedStrengthen = speedStrengthen;

  AddFruitRequestBuilder() {
    AddFruitRequest._defaults(this);
  }

  AddFruitRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _fruitType = $v.fruitType;
      _groupGainStrengthen = $v.groupGainStrengthen;
      _magicConsume = $v.magicConsume;
      _attackStrengthen = $v.attackStrengthen;
      _defenseStrengthen = $v.defenseStrengthen;
      _intelligenceStrengthen = $v.intelligenceStrengthen;
      _bloodStrengthen = $v.bloodStrengthen;
      _speedStrengthen = $v.speedStrengthen;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AddFruitRequest other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$AddFruitRequest;
  }

  @override
  void update(void Function(AddFruitRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$AddFruitRequest build() {
    final _$result = _$v ??
        new _$AddFruitRequest._(
            name: name,
            fruitType: fruitType,
            groupGainStrengthen: groupGainStrengthen,
            magicConsume: magicConsume,
            attackStrengthen: attackStrengthen,
            defenseStrengthen: defenseStrengthen,
            intelligenceStrengthen: intelligenceStrengthen,
            bloodStrengthen: bloodStrengthen,
            speedStrengthen: speedStrengthen);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
