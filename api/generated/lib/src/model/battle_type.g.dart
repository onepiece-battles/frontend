// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'battle_type.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const BattleType _$single = const BattleType._('single');
const BattleType _$group = const BattleType._('group');

BattleType _$valueOf(String name) {
  switch (name) {
    case 'single':
      return _$single;
    case 'group':
      return _$group;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<BattleType> _$values =
    new BuiltSet<BattleType>(const <BattleType>[
  _$single,
  _$group,
]);

class _$BattleTypeMeta {
  const _$BattleTypeMeta();
  BattleType get single => _$single;
  BattleType get group => _$group;
  BattleType valueOf(String name) => _$valueOf(name);
  BuiltSet<BattleType> get values => _$values;
}

abstract class _$BattleTypeMixin {
  // ignore: non_constant_identifier_names
  _$BattleTypeMeta get BattleType => const _$BattleTypeMeta();
}

Serializer<BattleType> _$battleTypeSerializer = new _$BattleTypeSerializer();

class _$BattleTypeSerializer implements PrimitiveSerializer<BattleType> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'single': 'Single',
    'group': 'Group',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'Single': 'single',
    'Group': 'group',
  };

  @override
  final Iterable<Type> types = const <Type>[BattleType];
  @override
  final String wireName = 'BattleType';

  @override
  Object serialize(Serializers serializers, BattleType object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  BattleType deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      BattleType.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
