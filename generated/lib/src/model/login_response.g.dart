// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$LoginResponse extends LoginResponse {
  @override
  final UserInfo? userInfo;
  @override
  final I18nText? verification;

  factory _$LoginResponse([void Function(LoginResponseBuilder)? updates]) =>
      (new LoginResponseBuilder()..update(updates)).build();

  _$LoginResponse._({this.userInfo, this.verification}) : super._();

  @override
  LoginResponse rebuild(void Function(LoginResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LoginResponseBuilder toBuilder() => new LoginResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is LoginResponse &&
        userInfo == other.userInfo &&
        verification == other.verification;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, userInfo.hashCode), verification.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('LoginResponse')
          ..add('userInfo', userInfo)
          ..add('verification', verification))
        .toString();
  }
}

class LoginResponseBuilder
    implements Builder<LoginResponse, LoginResponseBuilder> {
  _$LoginResponse? _$v;

  UserInfoBuilder? _userInfo;
  UserInfoBuilder get userInfo => _$this._userInfo ??= new UserInfoBuilder();
  set userInfo(UserInfoBuilder? userInfo) => _$this._userInfo = userInfo;

  I18nTextBuilder? _verification;
  I18nTextBuilder get verification =>
      _$this._verification ??= new I18nTextBuilder();
  set verification(I18nTextBuilder? verification) =>
      _$this._verification = verification;

  LoginResponseBuilder() {
    LoginResponse._defaults(this);
  }

  LoginResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _userInfo = $v.userInfo?.toBuilder();
      _verification = $v.verification?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(LoginResponse other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$LoginResponse;
  }

  @override
  void update(void Function(LoginResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$LoginResponse build() {
    _$LoginResponse _$result;
    try {
      _$result = _$v ??
          new _$LoginResponse._(
              userInfo: _userInfo?.build(),
              verification: _verification?.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'userInfo';
        _userInfo?.build();
        _$failedField = 'verification';
        _verification?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'LoginResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
