// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_info.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UserInfo extends UserInfo {
  @override
  final String userId;
  @override
  final String userName;
  @override
  final String? organization;

  factory _$UserInfo([void Function(UserInfoBuilder)? updates]) =>
      (new UserInfoBuilder()..update(updates)).build();

  _$UserInfo._(
      {required this.userId, required this.userName, this.organization})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(userId, 'UserInfo', 'userId');
    BuiltValueNullFieldError.checkNotNull(userName, 'UserInfo', 'userName');
  }

  @override
  UserInfo rebuild(void Function(UserInfoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UserInfoBuilder toBuilder() => new UserInfoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UserInfo &&
        userId == other.userId &&
        userName == other.userName &&
        organization == other.organization;
  }

  @override
  int get hashCode {
    return $jf($jc($jc($jc(0, userId.hashCode), userName.hashCode),
        organization.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('UserInfo')
          ..add('userId', userId)
          ..add('userName', userName)
          ..add('organization', organization))
        .toString();
  }
}

class UserInfoBuilder implements Builder<UserInfo, UserInfoBuilder> {
  _$UserInfo? _$v;

  String? _userId;
  String? get userId => _$this._userId;
  set userId(String? userId) => _$this._userId = userId;

  String? _userName;
  String? get userName => _$this._userName;
  set userName(String? userName) => _$this._userName = userName;

  String? _organization;
  String? get organization => _$this._organization;
  set organization(String? organization) => _$this._organization = organization;

  UserInfoBuilder() {
    UserInfo._defaults(this);
  }

  UserInfoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _userId = $v.userId;
      _userName = $v.userName;
      _organization = $v.organization;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UserInfo other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$UserInfo;
  }

  @override
  void update(void Function(UserInfoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$UserInfo build() {
    final _$result = _$v ??
        new _$UserInfo._(
            userId: BuiltValueNullFieldError.checkNotNull(
                userId, 'UserInfo', 'userId'),
            userName: BuiltValueNullFieldError.checkNotNull(
                userName, 'UserInfo', 'userName'),
            organization: organization);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
