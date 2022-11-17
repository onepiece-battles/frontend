// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_character_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ListCharacterRequest extends ListCharacterRequest {
  @override
  final int pageSize;
  @override
  final int pageIndex;

  factory _$ListCharacterRequest(
          [void Function(ListCharacterRequestBuilder)? updates]) =>
      (new ListCharacterRequestBuilder()..update(updates)).build();

  _$ListCharacterRequest._({required this.pageSize, required this.pageIndex})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        pageSize, 'ListCharacterRequest', 'pageSize');
    BuiltValueNullFieldError.checkNotNull(
        pageIndex, 'ListCharacterRequest', 'pageIndex');
  }

  @override
  ListCharacterRequest rebuild(
          void Function(ListCharacterRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ListCharacterRequestBuilder toBuilder() =>
      new ListCharacterRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ListCharacterRequest &&
        pageSize == other.pageSize &&
        pageIndex == other.pageIndex;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, pageSize.hashCode), pageIndex.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('ListCharacterRequest')
          ..add('pageSize', pageSize)
          ..add('pageIndex', pageIndex))
        .toString();
  }
}

class ListCharacterRequestBuilder
    implements Builder<ListCharacterRequest, ListCharacterRequestBuilder> {
  _$ListCharacterRequest? _$v;

  int? _pageSize;
  int? get pageSize => _$this._pageSize;
  set pageSize(int? pageSize) => _$this._pageSize = pageSize;

  int? _pageIndex;
  int? get pageIndex => _$this._pageIndex;
  set pageIndex(int? pageIndex) => _$this._pageIndex = pageIndex;

  ListCharacterRequestBuilder() {
    ListCharacterRequest._defaults(this);
  }

  ListCharacterRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _pageSize = $v.pageSize;
      _pageIndex = $v.pageIndex;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ListCharacterRequest other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ListCharacterRequest;
  }

  @override
  void update(void Function(ListCharacterRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$ListCharacterRequest build() {
    final _$result = _$v ??
        new _$ListCharacterRequest._(
            pageSize: BuiltValueNullFieldError.checkNotNull(
                pageSize, 'ListCharacterRequest', 'pageSize'),
            pageIndex: BuiltValueNullFieldError.checkNotNull(
                pageIndex, 'ListCharacterRequest', 'pageIndex'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
