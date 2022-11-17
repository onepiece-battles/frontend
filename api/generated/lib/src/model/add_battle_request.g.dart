// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_battle_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AddBattleRequest extends AddBattleRequest {
  @override
  final String userId;
  @override
  final String initiateCharacterId;
  @override
  final String receiverCharacterId;

  factory _$AddBattleRequest(
          [void Function(AddBattleRequestBuilder)? updates]) =>
      (new AddBattleRequestBuilder()..update(updates)).build();

  _$AddBattleRequest._(
      {required this.userId,
      required this.initiateCharacterId,
      required this.receiverCharacterId})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(userId, 'AddBattleRequest', 'userId');
    BuiltValueNullFieldError.checkNotNull(
        initiateCharacterId, 'AddBattleRequest', 'initiateCharacterId');
    BuiltValueNullFieldError.checkNotNull(
        receiverCharacterId, 'AddBattleRequest', 'receiverCharacterId');
  }

  @override
  AddBattleRequest rebuild(void Function(AddBattleRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AddBattleRequestBuilder toBuilder() =>
      new AddBattleRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AddBattleRequest &&
        userId == other.userId &&
        initiateCharacterId == other.initiateCharacterId &&
        receiverCharacterId == other.receiverCharacterId;
  }

  @override
  int get hashCode {
    return $jf($jc($jc($jc(0, userId.hashCode), initiateCharacterId.hashCode),
        receiverCharacterId.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('AddBattleRequest')
          ..add('userId', userId)
          ..add('initiateCharacterId', initiateCharacterId)
          ..add('receiverCharacterId', receiverCharacterId))
        .toString();
  }
}

class AddBattleRequestBuilder
    implements Builder<AddBattleRequest, AddBattleRequestBuilder> {
  _$AddBattleRequest? _$v;

  String? _userId;
  String? get userId => _$this._userId;
  set userId(String? userId) => _$this._userId = userId;

  String? _initiateCharacterId;
  String? get initiateCharacterId => _$this._initiateCharacterId;
  set initiateCharacterId(String? initiateCharacterId) =>
      _$this._initiateCharacterId = initiateCharacterId;

  String? _receiverCharacterId;
  String? get receiverCharacterId => _$this._receiverCharacterId;
  set receiverCharacterId(String? receiverCharacterId) =>
      _$this._receiverCharacterId = receiverCharacterId;

  AddBattleRequestBuilder() {
    AddBattleRequest._defaults(this);
  }

  AddBattleRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _userId = $v.userId;
      _initiateCharacterId = $v.initiateCharacterId;
      _receiverCharacterId = $v.receiverCharacterId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AddBattleRequest other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$AddBattleRequest;
  }

  @override
  void update(void Function(AddBattleRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$AddBattleRequest build() {
    final _$result = _$v ??
        new _$AddBattleRequest._(
            userId: BuiltValueNullFieldError.checkNotNull(
                userId, 'AddBattleRequest', 'userId'),
            initiateCharacterId: BuiltValueNullFieldError.checkNotNull(
                initiateCharacterId, 'AddBattleRequest', 'initiateCharacterId'),
            receiverCharacterId: BuiltValueNullFieldError.checkNotNull(
                receiverCharacterId,
                'AddBattleRequest',
                'receiverCharacterId'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
