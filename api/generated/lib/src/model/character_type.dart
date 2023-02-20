//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'character_type.g.dart';

class CharacterType extends EnumClass {

  /// types that defines how character fight in battles.
  @BuiltValueEnumConst(wireName: r'Katana')
  static const CharacterType katana = _$katana;
  /// types that defines how character fight in battles.
  @BuiltValueEnumConst(wireName: r'Fist')
  static const CharacterType fist = _$fist;
  /// types that defines how character fight in battles.
  @BuiltValueEnumConst(wireName: r'Foot')
  static const CharacterType foot = _$foot;
  /// types that defines how character fight in battles.
  @BuiltValueEnumConst(wireName: r'Shooter')
  static const CharacterType shooter = _$shooter;
  /// types that defines how character fight in battles.
  @BuiltValueEnumConst(wireName: r'Body')
  static const CharacterType body = _$body;

  static Serializer<CharacterType> get serializer => _$characterTypeSerializer;

  const CharacterType._(String name): super(name);

  static BuiltSet<CharacterType> get values => _$values;
  static CharacterType valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class CharacterTypeMixin = Object with _$CharacterTypeMixin;

