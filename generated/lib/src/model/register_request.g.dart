// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RegisterRequest extends RegisterRequest {
  @override
  final String userName;
  @override
  final String email;
  @override
  final String password;
  @override
  final String confirmedPassword;
  @override
  final String organization;

  factory _$RegisterRequest([void Function(RegisterRequestBuilder)? updates]) =>
      (new RegisterRequestBuilder()..update(updates)).build();

  _$RegisterRequest._(
      {required this.userName,
      required this.email,
      required this.password,
      required this.confirmedPassword,
      required this.organization})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        userName, 'RegisterRequest', 'userName');
    BuiltValueNullFieldError.checkNotNull(email, 'RegisterRequest', 'email');
    BuiltValueNullFieldError.checkNotNull(
        password, 'RegisterRequest', 'password');
    BuiltValueNullFieldError.checkNotNull(
        confirmedPassword, 'RegisterRequest', 'confirmedPassword');
    BuiltValueNullFieldError.checkNotNull(
        organization, 'RegisterRequest', 'organization');
  }

  @override
  RegisterRequest rebuild(void Function(RegisterRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RegisterRequestBuilder toBuilder() =>
      new RegisterRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RegisterRequest &&
        userName == other.userName &&
        email == other.email &&
        password == other.password &&
        confirmedPassword == other.confirmedPassword &&
        organization == other.organization;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc($jc($jc(0, userName.hashCode), email.hashCode),
                password.hashCode),
            confirmedPassword.hashCode),
        organization.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('RegisterRequest')
          ..add('userName', userName)
          ..add('email', email)
          ..add('password', password)
          ..add('confirmedPassword', confirmedPassword)
          ..add('organization', organization))
        .toString();
  }
}

class RegisterRequestBuilder
    implements Builder<RegisterRequest, RegisterRequestBuilder> {
  _$RegisterRequest? _$v;

  String? _userName;
  String? get userName => _$this._userName;
  set userName(String? userName) => _$this._userName = userName;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  String? _password;
  String? get password => _$this._password;
  set password(String? password) => _$this._password = password;

  String? _confirmedPassword;
  String? get confirmedPassword => _$this._confirmedPassword;
  set confirmedPassword(String? confirmedPassword) =>
      _$this._confirmedPassword = confirmedPassword;

  String? _organization;
  String? get organization => _$this._organization;
  set organization(String? organization) => _$this._organization = organization;

  RegisterRequestBuilder() {
    RegisterRequest._defaults(this);
  }

  RegisterRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _userName = $v.userName;
      _email = $v.email;
      _password = $v.password;
      _confirmedPassword = $v.confirmedPassword;
      _organization = $v.organization;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RegisterRequest other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$RegisterRequest;
  }

  @override
  void update(void Function(RegisterRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$RegisterRequest build() {
    final _$result = _$v ??
        new _$RegisterRequest._(
            userName: BuiltValueNullFieldError.checkNotNull(
                userName, 'RegisterRequest', 'userName'),
            email: BuiltValueNullFieldError.checkNotNull(
                email, 'RegisterRequest', 'email'),
            password: BuiltValueNullFieldError.checkNotNull(
                password, 'RegisterRequest', 'password'),
            confirmedPassword: BuiltValueNullFieldError.checkNotNull(
                confirmedPassword, 'RegisterRequest', 'confirmedPassword'),
            organization: BuiltValueNullFieldError.checkNotNull(
                organization, 'RegisterRequest', 'organization'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
