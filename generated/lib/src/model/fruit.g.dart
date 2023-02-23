// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fruit.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Fruit extends Fruit {
  @override
  final String? id;
  @override
  final String? name;
  @override
  final String? ownerId;
  @override
  final FruitType? fruitType;
  @override
  final int? magicConsume;
  @override
  final int? attackStrengthen;
  @override
  final int? intelligenceStrengthen;
  @override
  final int? bloodStrengthen;
  @override
  final int? speedStrengthen;

  factory _$Fruit([void Function(FruitBuilder)? updates]) =>
      (new FruitBuilder()..update(updates)).build();

  _$Fruit._(
      {this.id,
      this.name,
      this.ownerId,
      this.fruitType,
      this.magicConsume,
      this.attackStrengthen,
      this.intelligenceStrengthen,
      this.bloodStrengthen,
      this.speedStrengthen})
      : super._();

  @override
  Fruit rebuild(void Function(FruitBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FruitBuilder toBuilder() => new FruitBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Fruit &&
        id == other.id &&
        name == other.name &&
        ownerId == other.ownerId &&
        fruitType == other.fruitType &&
        magicConsume == other.magicConsume &&
        attackStrengthen == other.attackStrengthen &&
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
                            $jc($jc($jc(0, id.hashCode), name.hashCode),
                                ownerId.hashCode),
                            fruitType.hashCode),
                        magicConsume.hashCode),
                    attackStrengthen.hashCode),
                intelligenceStrengthen.hashCode),
            bloodStrengthen.hashCode),
        speedStrengthen.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Fruit')
          ..add('id', id)
          ..add('name', name)
          ..add('ownerId', ownerId)
          ..add('fruitType', fruitType)
          ..add('magicConsume', magicConsume)
          ..add('attackStrengthen', attackStrengthen)
          ..add('intelligenceStrengthen', intelligenceStrengthen)
          ..add('bloodStrengthen', bloodStrengthen)
          ..add('speedStrengthen', speedStrengthen))
        .toString();
  }
}

class FruitBuilder implements Builder<Fruit, FruitBuilder> {
  _$Fruit? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _ownerId;
  String? get ownerId => _$this._ownerId;
  set ownerId(String? ownerId) => _$this._ownerId = ownerId;

  FruitType? _fruitType;
  FruitType? get fruitType => _$this._fruitType;
  set fruitType(FruitType? fruitType) => _$this._fruitType = fruitType;

  int? _magicConsume;
  int? get magicConsume => _$this._magicConsume;
  set magicConsume(int? magicConsume) => _$this._magicConsume = magicConsume;

  int? _attackStrengthen;
  int? get attackStrengthen => _$this._attackStrengthen;
  set attackStrengthen(int? attackStrengthen) =>
      _$this._attackStrengthen = attackStrengthen;

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

  FruitBuilder() {
    Fruit._defaults(this);
  }

  FruitBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _name = $v.name;
      _ownerId = $v.ownerId;
      _fruitType = $v.fruitType;
      _magicConsume = $v.magicConsume;
      _attackStrengthen = $v.attackStrengthen;
      _intelligenceStrengthen = $v.intelligenceStrengthen;
      _bloodStrengthen = $v.bloodStrengthen;
      _speedStrengthen = $v.speedStrengthen;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Fruit other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$Fruit;
  }

  @override
  void update(void Function(FruitBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Fruit build() {
    final _$result = _$v ??
        new _$Fruit._(
            id: id,
            name: name,
            ownerId: ownerId,
            fruitType: fruitType,
            magicConsume: magicConsume,
            attackStrengthen: attackStrengthen,
            intelligenceStrengthen: intelligenceStrengthen,
            bloodStrengthen: bloodStrengthen,
            speedStrengthen: speedStrengthen);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
