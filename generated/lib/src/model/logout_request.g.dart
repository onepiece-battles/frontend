// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logout_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$LogoutRequest extends LogoutRequest {
  @override
  final String? userId;

  factory _$LogoutRequest([void Function(LogoutRequestBuilder)? updates]) =>
      (new LogoutRequestBuilder()..update(updates)).build();

  _$LogoutRequest._({this.userId}) : super._();

  @override
  LogoutRequest rebuild(void Function(LogoutRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LogoutRequestBuilder toBuilder() => new LogoutRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is LogoutRequest && userId == other.userId;
  }

  @override
  int get hashCode {
    return $jf($jc(0, userId.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('LogoutRequest')..add('userId', userId))
        .toString();
  }
}

class LogoutRequestBuilder
    implements Builder<LogoutRequest, LogoutRequestBuilder> {
  _$LogoutRequest? _$v;

  String? _userId;
  String? get userId => _$this._userId;
  set userId(String? userId) => _$this._userId = userId;

  LogoutRequestBuilder() {
    LogoutRequest._defaults(this);
  }

  LogoutRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _userId = $v.userId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(LogoutRequest other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$LogoutRequest;
  }

  @override
  void update(void Function(LogoutRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$LogoutRequest build() {
    final _$result = _$v ?? new _$LogoutRequest._(userId: userId);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
