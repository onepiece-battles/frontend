// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'battle.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Battle extends Battle {
  @override
  final int actionTimestamp;
  @override
  final String battleId;
  @override
  final String userId;
  @override
  final String initiateCharacterId;
  @override
  final String receiverCharacterId;
  @override
  final BattleType type;

  factory _$Battle([void Function(BattleBuilder)? updates]) =>
      (new BattleBuilder()..update(updates)).build();

  _$Battle._(
      {required this.actionTimestamp,
      required this.battleId,
      required this.userId,
      required this.initiateCharacterId,
      required this.receiverCharacterId,
      required this.type})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        actionTimestamp, 'Battle', 'actionTimestamp');
    BuiltValueNullFieldError.checkNotNull(battleId, 'Battle', 'battleId');
    BuiltValueNullFieldError.checkNotNull(userId, 'Battle', 'userId');
    BuiltValueNullFieldError.checkNotNull(
        initiateCharacterId, 'Battle', 'initiateCharacterId');
    BuiltValueNullFieldError.checkNotNull(
        receiverCharacterId, 'Battle', 'receiverCharacterId');
    BuiltValueNullFieldError.checkNotNull(type, 'Battle', 'type');
  }

  @override
  Battle rebuild(void Function(BattleBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BattleBuilder toBuilder() => new BattleBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Battle &&
        actionTimestamp == other.actionTimestamp &&
        battleId == other.battleId &&
        userId == other.userId &&
        initiateCharacterId == other.initiateCharacterId &&
        receiverCharacterId == other.receiverCharacterId &&
        type == other.type;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc($jc($jc(0, actionTimestamp.hashCode), battleId.hashCode),
                    userId.hashCode),
                initiateCharacterId.hashCode),
            receiverCharacterId.hashCode),
        type.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Battle')
          ..add('actionTimestamp', actionTimestamp)
          ..add('battleId', battleId)
          ..add('userId', userId)
          ..add('initiateCharacterId', initiateCharacterId)
          ..add('receiverCharacterId', receiverCharacterId)
          ..add('type', type))
        .toString();
  }
}

class BattleBuilder implements Builder<Battle, BattleBuilder> {
  _$Battle? _$v;

  int? _actionTimestamp;
  int? get actionTimestamp => _$this._actionTimestamp;
  set actionTimestamp(int? actionTimestamp) =>
      _$this._actionTimestamp = actionTimestamp;

  String? _battleId;
  String? get battleId => _$this._battleId;
  set battleId(String? battleId) => _$this._battleId = battleId;

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

  BattleType? _type;
  BattleType? get type => _$this._type;
  set type(BattleType? type) => _$this._type = type;

  BattleBuilder() {
    Battle._defaults(this);
  }

  BattleBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _actionTimestamp = $v.actionTimestamp;
      _battleId = $v.battleId;
      _userId = $v.userId;
      _initiateCharacterId = $v.initiateCharacterId;
      _receiverCharacterId = $v.receiverCharacterId;
      _type = $v.type;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Battle other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$Battle;
  }

  @override
  void update(void Function(BattleBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Battle build() {
    final _$result = _$v ??
        new _$Battle._(
            actionTimestamp: BuiltValueNullFieldError.checkNotNull(
                actionTimestamp, 'Battle', 'actionTimestamp'),
            battleId: BuiltValueNullFieldError.checkNotNull(
                battleId, 'Battle', 'battleId'),
            userId: BuiltValueNullFieldError.checkNotNull(
                userId, 'Battle', 'userId'),
            initiateCharacterId: BuiltValueNullFieldError.checkNotNull(
                initiateCharacterId, 'Battle', 'initiateCharacterId'),
            receiverCharacterId: BuiltValueNullFieldError.checkNotNull(
                receiverCharacterId, 'Battle', 'receiverCharacterId'),
            type:
                BuiltValueNullFieldError.checkNotNull(type, 'Battle', 'type'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
