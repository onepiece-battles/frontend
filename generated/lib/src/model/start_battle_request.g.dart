// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'start_battle_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$StartBattleRequest extends StartBattleRequest {
  @override
  final String battleId;

  factory _$StartBattleRequest(
          [void Function(StartBattleRequestBuilder)? updates]) =>
      (new StartBattleRequestBuilder()..update(updates)).build();

  _$StartBattleRequest._({required this.battleId}) : super._() {
    BuiltValueNullFieldError.checkNotNull(
        battleId, 'StartBattleRequest', 'battleId');
  }

  @override
  StartBattleRequest rebuild(
          void Function(StartBattleRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  StartBattleRequestBuilder toBuilder() =>
      new StartBattleRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is StartBattleRequest && battleId == other.battleId;
  }

  @override
  int get hashCode {
    return $jf($jc(0, battleId.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('StartBattleRequest')
          ..add('battleId', battleId))
        .toString();
  }
}

class StartBattleRequestBuilder
    implements Builder<StartBattleRequest, StartBattleRequestBuilder> {
  _$StartBattleRequest? _$v;

  String? _battleId;
  String? get battleId => _$this._battleId;
  set battleId(String? battleId) => _$this._battleId = battleId;

  StartBattleRequestBuilder() {
    StartBattleRequest._defaults(this);
  }

  StartBattleRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _battleId = $v.battleId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(StartBattleRequest other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$StartBattleRequest;
  }

  @override
  void update(void Function(StartBattleRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$StartBattleRequest build() {
    final _$result = _$v ??
        new _$StartBattleRequest._(
            battleId: BuiltValueNullFieldError.checkNotNull(
                battleId, 'StartBattleRequest', 'battleId'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
