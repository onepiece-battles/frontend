// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RegisterResponse extends RegisterResponse {
  @override
  final bool registerResult;
  @override
  final String verification;

  factory _$RegisterResponse(
          [void Function(RegisterResponseBuilder)? updates]) =>
      (new RegisterResponseBuilder()..update(updates)).build();

  _$RegisterResponse._(
      {required this.registerResult, required this.verification})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        registerResult, 'RegisterResponse', 'registerResult');
    BuiltValueNullFieldError.checkNotNull(
        verification, 'RegisterResponse', 'verification');
  }

  @override
  RegisterResponse rebuild(void Function(RegisterResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RegisterResponseBuilder toBuilder() =>
      new RegisterResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RegisterResponse &&
        registerResult == other.registerResult &&
        verification == other.verification;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, registerResult.hashCode), verification.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('RegisterResponse')
          ..add('registerResult', registerResult)
          ..add('verification', verification))
        .toString();
  }
}

class RegisterResponseBuilder
    implements Builder<RegisterResponse, RegisterResponseBuilder> {
  _$RegisterResponse? _$v;

  bool? _registerResult;
  bool? get registerResult => _$this._registerResult;
  set registerResult(bool? registerResult) =>
      _$this._registerResult = registerResult;

  String? _verification;
  String? get verification => _$this._verification;
  set verification(String? verification) => _$this._verification = verification;

  RegisterResponseBuilder() {
    RegisterResponse._defaults(this);
  }

  RegisterResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _registerResult = $v.registerResult;
      _verification = $v.verification;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RegisterResponse other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$RegisterResponse;
  }

  @override
  void update(void Function(RegisterResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$RegisterResponse build() {
    final _$result = _$v ??
        new _$RegisterResponse._(
            registerResult: BuiltValueNullFieldError.checkNotNull(
                registerResult, 'RegisterResponse', 'registerResult'),
            verification: BuiltValueNullFieldError.checkNotNull(
                verification, 'RegisterResponse', 'verification'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
