// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'eat_fruit_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$EatFruitResponse extends EatFruitResponse {
  @override
  final Character character;
  @override
  final String fruitMessage;

  factory _$EatFruitResponse(
          [void Function(EatFruitResponseBuilder)? updates]) =>
      (new EatFruitResponseBuilder()..update(updates)).build();

  _$EatFruitResponse._({required this.character, required this.fruitMessage})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        character, 'EatFruitResponse', 'character');
    BuiltValueNullFieldError.checkNotNull(
        fruitMessage, 'EatFruitResponse', 'fruitMessage');
  }

  @override
  EatFruitResponse rebuild(void Function(EatFruitResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  EatFruitResponseBuilder toBuilder() =>
      new EatFruitResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is EatFruitResponse &&
        character == other.character &&
        fruitMessage == other.fruitMessage;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, character.hashCode), fruitMessage.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('EatFruitResponse')
          ..add('character', character)
          ..add('fruitMessage', fruitMessage))
        .toString();
  }
}

class EatFruitResponseBuilder
    implements Builder<EatFruitResponse, EatFruitResponseBuilder> {
  _$EatFruitResponse? _$v;

  CharacterBuilder? _character;
  CharacterBuilder get character =>
      _$this._character ??= new CharacterBuilder();
  set character(CharacterBuilder? character) => _$this._character = character;

  String? _fruitMessage;
  String? get fruitMessage => _$this._fruitMessage;
  set fruitMessage(String? fruitMessage) => _$this._fruitMessage = fruitMessage;

  EatFruitResponseBuilder() {
    EatFruitResponse._defaults(this);
  }

  EatFruitResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _character = $v.character.toBuilder();
      _fruitMessage = $v.fruitMessage;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(EatFruitResponse other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$EatFruitResponse;
  }

  @override
  void update(void Function(EatFruitResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$EatFruitResponse build() {
    _$EatFruitResponse _$result;
    try {
      _$result = _$v ??
          new _$EatFruitResponse._(
              character: character.build(),
              fruitMessage: BuiltValueNullFieldError.checkNotNull(
                  fruitMessage, 'EatFruitResponse', 'fruitMessage'));
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'character';
        character.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'EatFruitResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
