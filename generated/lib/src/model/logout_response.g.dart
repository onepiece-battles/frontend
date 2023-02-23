// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logout_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$LogoutResponse extends LogoutResponse {
  @override
  final String? userName;
  @override
  final String? logoutResult;

  factory _$LogoutResponse([void Function(LogoutResponseBuilder)? updates]) =>
      (new LogoutResponseBuilder()..update(updates)).build();

  _$LogoutResponse._({this.userName, this.logoutResult}) : super._();

  @override
  LogoutResponse rebuild(void Function(LogoutResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LogoutResponseBuilder toBuilder() =>
      new LogoutResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is LogoutResponse &&
        userName == other.userName &&
        logoutResult == other.logoutResult;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, userName.hashCode), logoutResult.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('LogoutResponse')
          ..add('userName', userName)
          ..add('logoutResult', logoutResult))
        .toString();
  }
}

class LogoutResponseBuilder
    implements Builder<LogoutResponse, LogoutResponseBuilder> {
  _$LogoutResponse? _$v;

  String? _userName;
  String? get userName => _$this._userName;
  set userName(String? userName) => _$this._userName = userName;

  String? _logoutResult;
  String? get logoutResult => _$this._logoutResult;
  set logoutResult(String? logoutResult) => _$this._logoutResult = logoutResult;

  LogoutResponseBuilder() {
    LogoutResponse._defaults(this);
  }

  LogoutResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _userName = $v.userName;
      _logoutResult = $v.logoutResult;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(LogoutResponse other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$LogoutResponse;
  }

  @override
  void update(void Function(LogoutResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$LogoutResponse build() {
    final _$result = _$v ??
        new _$LogoutResponse._(userName: userName, logoutResult: logoutResult);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
