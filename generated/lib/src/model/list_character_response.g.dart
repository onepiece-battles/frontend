// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_character_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ListCharacterResponse extends ListCharacterResponse {
  @override
  final BuiltList<Character>? characters;

  factory _$ListCharacterResponse(
          [void Function(ListCharacterResponseBuilder)? updates]) =>
      (new ListCharacterResponseBuilder()..update(updates)).build();

  _$ListCharacterResponse._({this.characters}) : super._();

  @override
  ListCharacterResponse rebuild(
          void Function(ListCharacterResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ListCharacterResponseBuilder toBuilder() =>
      new ListCharacterResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ListCharacterResponse && characters == other.characters;
  }

  @override
  int get hashCode {
    return $jf($jc(0, characters.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('ListCharacterResponse')
          ..add('characters', characters))
        .toString();
  }
}

class ListCharacterResponseBuilder
    implements Builder<ListCharacterResponse, ListCharacterResponseBuilder> {
  _$ListCharacterResponse? _$v;

  ListBuilder<Character>? _characters;
  ListBuilder<Character> get characters =>
      _$this._characters ??= new ListBuilder<Character>();
  set characters(ListBuilder<Character>? characters) =>
      _$this._characters = characters;

  ListCharacterResponseBuilder() {
    ListCharacterResponse._defaults(this);
  }

  ListCharacterResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _characters = $v.characters?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ListCharacterResponse other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ListCharacterResponse;
  }

  @override
  void update(void Function(ListCharacterResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$ListCharacterResponse build() {
    _$ListCharacterResponse _$result;
    try {
      _$result = _$v ??
          new _$ListCharacterResponse._(characters: _characters?.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'characters';
        _characters?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'ListCharacterResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
