// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'start_battle_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$StartBattleResponse extends StartBattleResponse {
  @override
  final String? battleId;
  @override
  final BattleResult? result;

  factory _$StartBattleResponse(
          [void Function(StartBattleResponseBuilder)? updates]) =>
      (new StartBattleResponseBuilder()..update(updates)).build();

  _$StartBattleResponse._({this.battleId, this.result}) : super._();

  @override
  StartBattleResponse rebuild(
          void Function(StartBattleResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  StartBattleResponseBuilder toBuilder() =>
      new StartBattleResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is StartBattleResponse &&
        battleId == other.battleId &&
        result == other.result;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, battleId.hashCode), result.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('StartBattleResponse')
          ..add('battleId', battleId)
          ..add('result', result))
        .toString();
  }
}

class StartBattleResponseBuilder
    implements Builder<StartBattleResponse, StartBattleResponseBuilder> {
  _$StartBattleResponse? _$v;

  String? _battleId;
  String? get battleId => _$this._battleId;
  set battleId(String? battleId) => _$this._battleId = battleId;

  BattleResultBuilder? _result;
  BattleResultBuilder get result =>
      _$this._result ??= new BattleResultBuilder();
  set result(BattleResultBuilder? result) => _$this._result = result;

  StartBattleResponseBuilder() {
    StartBattleResponse._defaults(this);
  }

  StartBattleResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _battleId = $v.battleId;
      _result = $v.result?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(StartBattleResponse other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$StartBattleResponse;
  }

  @override
  void update(void Function(StartBattleResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$StartBattleResponse build() {
    _$StartBattleResponse _$result;
    try {
      _$result = _$v ??
          new _$StartBattleResponse._(
              battleId: battleId, result: _result?.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'result';
        _result?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'StartBattleResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
