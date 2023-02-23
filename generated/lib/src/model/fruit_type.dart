//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'fruit_type.g.dart';

class FruitType extends EnumClass {

  /// different types of fruit
  @BuiltValueEnumConst(wireName: r'Paramecia')
  static const FruitType paramecia = _$paramecia;
  /// different types of fruit
  @BuiltValueEnumConst(wireName: r'Logia')
  static const FruitType logia = _$logia;
  /// different types of fruit
  @BuiltValueEnumConst(wireName: r'Zoan')
  static const FruitType zoan = _$zoan;
  /// different types of fruit
  @BuiltValueEnumConst(wireName: r'Ancient_Zoan')
  static const FruitType ancientZoan = _$ancientZoan;
  /// different types of fruit
  @BuiltValueEnumConst(wireName: r'Mythical_Zoan')
  static const FruitType mythicalZoan = _$mythicalZoan;
  /// different types of fruit
  @BuiltValueEnumConst(wireName: r'Artificial_Zoan')
  static const FruitType artificialZoan = _$artificialZoan;

  static Serializer<FruitType> get serializer => _$fruitTypeSerializer;

  const FruitType._(String name): super(name);

  static BuiltSet<FruitType> get values => _$values;
  static FruitType valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class FruitTypeMixin = Object with _$FruitTypeMixin;

