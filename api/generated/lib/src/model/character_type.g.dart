// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_type.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const CharacterType _$katana = const CharacterType._('katana');
const CharacterType _$fist = const CharacterType._('fist');
const CharacterType _$foot = const CharacterType._('foot');
const CharacterType _$shooter = const CharacterType._('shooter');
const CharacterType _$body = const CharacterType._('body');

CharacterType _$valueOf(String name) {
  switch (name) {
    case 'katana':
      return _$katana;
    case 'fist':
      return _$fist;
    case 'foot':
      return _$foot;
    case 'shooter':
      return _$shooter;
    case 'body':
      return _$body;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<CharacterType> _$values =
    new BuiltSet<CharacterType>(const <CharacterType>[
  _$katana,
  _$fist,
  _$foot,
  _$shooter,
  _$body,
]);

class _$CharacterTypeMeta {
  const _$CharacterTypeMeta();
  CharacterType get katana => _$katana;
  CharacterType get fist => _$fist;
  CharacterType get foot => _$foot;
  CharacterType get shooter => _$shooter;
  CharacterType get body => _$body;
  CharacterType valueOf(String name) => _$valueOf(name);
  BuiltSet<CharacterType> get values => _$values;
}

abstract class _$CharacterTypeMixin {
  // ignore: non_constant_identifier_names
  _$CharacterTypeMeta get CharacterType => const _$CharacterTypeMeta();
}

Serializer<CharacterType> _$characterTypeSerializer =
    new _$CharacterTypeSerializer();

class _$CharacterTypeSerializer implements PrimitiveSerializer<CharacterType> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'katana': 'Katana',
    'fist': 'Fist',
    'foot': 'Foot',
    'shooter': 'Shooter',
    'body': 'Body',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'Katana': 'katana',
    'Fist': 'fist',
    'Foot': 'foot',
    'Shooter': 'shooter',
    'Body': 'body',
  };

  @override
  final Iterable<Type> types = const <Type>[CharacterType];
  @override
  final String wireName = 'CharacterType';

  @override
  Object serialize(Serializers serializers, CharacterType object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  CharacterType deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      CharacterType.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
