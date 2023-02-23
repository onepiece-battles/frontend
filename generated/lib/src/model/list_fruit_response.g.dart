// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_fruit_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ListFruitResponse extends ListFruitResponse {
  @override
  final BuiltList<Fruit>? fruits;

  factory _$ListFruitResponse(
          [void Function(ListFruitResponseBuilder)? updates]) =>
      (new ListFruitResponseBuilder()..update(updates)).build();

  _$ListFruitResponse._({this.fruits}) : super._();

  @override
  ListFruitResponse rebuild(void Function(ListFruitResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ListFruitResponseBuilder toBuilder() =>
      new ListFruitResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ListFruitResponse && fruits == other.fruits;
  }

  @override
  int get hashCode {
    return $jf($jc(0, fruits.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('ListFruitResponse')
          ..add('fruits', fruits))
        .toString();
  }
}

class ListFruitResponseBuilder
    implements Builder<ListFruitResponse, ListFruitResponseBuilder> {
  _$ListFruitResponse? _$v;

  ListBuilder<Fruit>? _fruits;
  ListBuilder<Fruit> get fruits => _$this._fruits ??= new ListBuilder<Fruit>();
  set fruits(ListBuilder<Fruit>? fruits) => _$this._fruits = fruits;

  ListFruitResponseBuilder() {
    ListFruitResponse._defaults(this);
  }

  ListFruitResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _fruits = $v.fruits?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ListFruitResponse other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ListFruitResponse;
  }

  @override
  void update(void Function(ListFruitResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$ListFruitResponse build() {
    _$ListFruitResponse _$result;
    try {
      _$result = _$v ?? new _$ListFruitResponse._(fruits: _fruits?.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'fruits';
        _fruits?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'ListFruitResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
