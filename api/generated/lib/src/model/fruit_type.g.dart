// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fruit_type.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const FruitType _$paramecia = const FruitType._('paramecia');
const FruitType _$logia = const FruitType._('logia');
const FruitType _$zoan = const FruitType._('zoan');
const FruitType _$ancientZoan = const FruitType._('ancientZoan');
const FruitType _$mythicalZoan = const FruitType._('mythicalZoan');
const FruitType _$artificialZoan = const FruitType._('artificialZoan');

FruitType _$valueOf(String name) {
  switch (name) {
    case 'paramecia':
      return _$paramecia;
    case 'logia':
      return _$logia;
    case 'zoan':
      return _$zoan;
    case 'ancientZoan':
      return _$ancientZoan;
    case 'mythicalZoan':
      return _$mythicalZoan;
    case 'artificialZoan':
      return _$artificialZoan;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<FruitType> _$values = new BuiltSet<FruitType>(const <FruitType>[
  _$paramecia,
  _$logia,
  _$zoan,
  _$ancientZoan,
  _$mythicalZoan,
  _$artificialZoan,
]);

class _$FruitTypeMeta {
  const _$FruitTypeMeta();
  FruitType get paramecia => _$paramecia;
  FruitType get logia => _$logia;
  FruitType get zoan => _$zoan;
  FruitType get ancientZoan => _$ancientZoan;
  FruitType get mythicalZoan => _$mythicalZoan;
  FruitType get artificialZoan => _$artificialZoan;
  FruitType valueOf(String name) => _$valueOf(name);
  BuiltSet<FruitType> get values => _$values;
}

abstract class _$FruitTypeMixin {
  // ignore: non_constant_identifier_names
  _$FruitTypeMeta get FruitType => const _$FruitTypeMeta();
}

Serializer<FruitType> _$fruitTypeSerializer = new _$FruitTypeSerializer();

class _$FruitTypeSerializer implements PrimitiveSerializer<FruitType> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'paramecia': 'Paramecia',
    'logia': 'Logia',
    'zoan': 'Zoan',
    'ancientZoan': 'Ancient_Zoan',
    'mythicalZoan': 'Mythical_Zoan',
    'artificialZoan': 'Artificial_Zoan',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'Paramecia': 'paramecia',
    'Logia': 'logia',
    'Zoan': 'zoan',
    'Ancient_Zoan': 'ancientZoan',
    'Mythical_Zoan': 'mythicalZoan',
    'Artificial_Zoan': 'artificialZoan',
  };

  @override
  final Iterable<Type> types = const <Type>[FruitType];
  @override
  final String wireName = 'FruitType';

  @override
  Object serialize(Serializers serializers, FruitType object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  FruitType deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      FruitType.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
