// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'eat_fruit_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$EatFruitRequest extends EatFruitRequest {
  @override
  final String characterId;
  @override
  final String fruitId;

  factory _$EatFruitRequest([void Function(EatFruitRequestBuilder)? updates]) =>
      (new EatFruitRequestBuilder()..update(updates)).build();

  _$EatFruitRequest._({required this.characterId, required this.fruitId})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        characterId, 'EatFruitRequest', 'characterId');
    BuiltValueNullFieldError.checkNotNull(
        fruitId, 'EatFruitRequest', 'fruitId');
  }

  @override
  EatFruitRequest rebuild(void Function(EatFruitRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  EatFruitRequestBuilder toBuilder() =>
      new EatFruitRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is EatFruitRequest &&
        characterId == other.characterId &&
        fruitId == other.fruitId;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, characterId.hashCode), fruitId.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('EatFruitRequest')
          ..add('characterId', characterId)
          ..add('fruitId', fruitId))
        .toString();
  }
}

class EatFruitRequestBuilder
    implements Builder<EatFruitRequest, EatFruitRequestBuilder> {
  _$EatFruitRequest? _$v;

  String? _characterId;
  String? get characterId => _$this._characterId;
  set characterId(String? characterId) => _$this._characterId = characterId;

  String? _fruitId;
  String? get fruitId => _$this._fruitId;
  set fruitId(String? fruitId) => _$this._fruitId = fruitId;

  EatFruitRequestBuilder() {
    EatFruitRequest._defaults(this);
  }

  EatFruitRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _characterId = $v.characterId;
      _fruitId = $v.fruitId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(EatFruitRequest other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$EatFruitRequest;
  }

  @override
  void update(void Function(EatFruitRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$EatFruitRequest build() {
    final _$result = _$v ??
        new _$EatFruitRequest._(
            characterId: BuiltValueNullFieldError.checkNotNull(
                characterId, 'EatFruitRequest', 'characterId'),
            fruitId: BuiltValueNullFieldError.checkNotNull(
                fruitId, 'EatFruitRequest', 'fruitId'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
