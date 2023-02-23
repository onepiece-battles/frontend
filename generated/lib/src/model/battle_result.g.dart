// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'battle_result.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$BattleResult extends BattleResult {
  @override
  final String? winnerId;
  @override
  final String? loserId;
  @override
  final double? winnerRemainBloodPercentage;

  factory _$BattleResult([void Function(BattleResultBuilder)? updates]) =>
      (new BattleResultBuilder()..update(updates)).build();

  _$BattleResult._(
      {this.winnerId, this.loserId, this.winnerRemainBloodPercentage})
      : super._();

  @override
  BattleResult rebuild(void Function(BattleResultBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BattleResultBuilder toBuilder() => new BattleResultBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BattleResult &&
        winnerId == other.winnerId &&
        loserId == other.loserId &&
        winnerRemainBloodPercentage == other.winnerRemainBloodPercentage;
  }

  @override
  int get hashCode {
    return $jf($jc($jc($jc(0, winnerId.hashCode), loserId.hashCode),
        winnerRemainBloodPercentage.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('BattleResult')
          ..add('winnerId', winnerId)
          ..add('loserId', loserId)
          ..add('winnerRemainBloodPercentage', winnerRemainBloodPercentage))
        .toString();
  }
}

class BattleResultBuilder
    implements Builder<BattleResult, BattleResultBuilder> {
  _$BattleResult? _$v;

  String? _winnerId;
  String? get winnerId => _$this._winnerId;
  set winnerId(String? winnerId) => _$this._winnerId = winnerId;

  String? _loserId;
  String? get loserId => _$this._loserId;
  set loserId(String? loserId) => _$this._loserId = loserId;

  double? _winnerRemainBloodPercentage;
  double? get winnerRemainBloodPercentage =>
      _$this._winnerRemainBloodPercentage;
  set winnerRemainBloodPercentage(double? winnerRemainBloodPercentage) =>
      _$this._winnerRemainBloodPercentage = winnerRemainBloodPercentage;

  BattleResultBuilder() {
    BattleResult._defaults(this);
  }

  BattleResultBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _winnerId = $v.winnerId;
      _loserId = $v.loserId;
      _winnerRemainBloodPercentage = $v.winnerRemainBloodPercentage;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BattleResult other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$BattleResult;
  }

  @override
  void update(void Function(BattleResultBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$BattleResult build() {
    final _$result = _$v ??
        new _$BattleResult._(
            winnerId: winnerId,
            loserId: loserId,
            winnerRemainBloodPercentage: winnerRemainBloodPercentage);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
