// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fruit_in_character.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$FruitInCharacter extends FruitInCharacter {
  @override
  final String fruitId;
  @override
  final bool wakeUp;

  factory _$FruitInCharacter(
          [void Function(FruitInCharacterBuilder)? updates]) =>
      (new FruitInCharacterBuilder()..update(updates)).build();

  _$FruitInCharacter._({required this.fruitId, required this.wakeUp})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        fruitId, 'FruitInCharacter', 'fruitId');
    BuiltValueNullFieldError.checkNotNull(wakeUp, 'FruitInCharacter', 'wakeUp');
  }

  @override
  FruitInCharacter rebuild(void Function(FruitInCharacterBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FruitInCharacterBuilder toBuilder() =>
      new FruitInCharacterBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FruitInCharacter &&
        fruitId == other.fruitId &&
        wakeUp == other.wakeUp;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, fruitId.hashCode), wakeUp.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('FruitInCharacter')
          ..add('fruitId', fruitId)
          ..add('wakeUp', wakeUp))
        .toString();
  }
}

class FruitInCharacterBuilder
    implements Builder<FruitInCharacter, FruitInCharacterBuilder> {
  _$FruitInCharacter? _$v;

  String? _fruitId;
  String? get fruitId => _$this._fruitId;
  set fruitId(String? fruitId) => _$this._fruitId = fruitId;

  bool? _wakeUp;
  bool? get wakeUp => _$this._wakeUp;
  set wakeUp(bool? wakeUp) => _$this._wakeUp = wakeUp;

  FruitInCharacterBuilder() {
    FruitInCharacter._defaults(this);
  }

  FruitInCharacterBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _fruitId = $v.fruitId;
      _wakeUp = $v.wakeUp;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FruitInCharacter other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$FruitInCharacter;
  }

  @override
  void update(void Function(FruitInCharacterBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$FruitInCharacter build() {
    final _$result = _$v ??
        new _$FruitInCharacter._(
            fruitId: BuiltValueNullFieldError.checkNotNull(
                fruitId, 'FruitInCharacter', 'fruitId'),
            wakeUp: BuiltValueNullFieldError.checkNotNull(
                wakeUp, 'FruitInCharacter', 'wakeUp'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
