// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_type_info.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CharacterTypeInfo extends CharacterTypeInfo {
  @override
  final CharacterType? type;
  @override
  final int? index;

  factory _$CharacterTypeInfo(
          [void Function(CharacterTypeInfoBuilder)? updates]) =>
      (new CharacterTypeInfoBuilder()..update(updates)).build();

  _$CharacterTypeInfo._({this.type, this.index}) : super._();

  @override
  CharacterTypeInfo rebuild(void Function(CharacterTypeInfoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CharacterTypeInfoBuilder toBuilder() =>
      new CharacterTypeInfoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CharacterTypeInfo &&
        type == other.type &&
        index == other.index;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, type.hashCode), index.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('CharacterTypeInfo')
          ..add('type', type)
          ..add('index', index))
        .toString();
  }
}

class CharacterTypeInfoBuilder
    implements Builder<CharacterTypeInfo, CharacterTypeInfoBuilder> {
  _$CharacterTypeInfo? _$v;

  CharacterType? _type;
  CharacterType? get type => _$this._type;
  set type(CharacterType? type) => _$this._type = type;

  int? _index;
  int? get index => _$this._index;
  set index(int? index) => _$this._index = index;

  CharacterTypeInfoBuilder() {
    CharacterTypeInfo._defaults(this);
  }

  CharacterTypeInfoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _type = $v.type;
      _index = $v.index;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CharacterTypeInfo other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$CharacterTypeInfo;
  }

  @override
  void update(void Function(CharacterTypeInfoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$CharacterTypeInfo build() {
    final _$result = _$v ?? new _$CharacterTypeInfo._(type: type, index: index);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
