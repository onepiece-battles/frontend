//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:openapi/src/model/fruit_in_character.dart';
import 'package:built_collection/built_collection.dart';
import 'package:openapi/src/model/character_type_info.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'character.g.dart';

/// Character that contains all necessary information. 
///
/// Properties:
/// * [id] 
/// * [characterTypes] - type of fighting skills
/// * [name] 
/// * [groupOid] - Which group this character is in.
/// * [hasFruits] - Whether this character has eaten fruit
/// * [fruits] 
/// * [fruitLimit] - Maximum number of fruit this character can eat.
/// * [groupGain] 
/// * [attack] 
/// * [defense] 
/// * [intelligence] 
/// * [blood] 
/// * [speed] 
/// * [magic] 
abstract class Character implements Built<Character, CharacterBuilder> {
    @BuiltValueField(wireName: r'id')
    String get id;

    /// type of fighting skills
    @BuiltValueField(wireName: r'character_types')
    BuiltList<CharacterTypeInfo>? get characterTypes;

    @BuiltValueField(wireName: r'name')
    String get name;

    /// Which group this character is in.
    @BuiltValueField(wireName: r'group_oid')
    String? get groupOid;

    /// Whether this character has eaten fruit
    @BuiltValueField(wireName: r'has_fruits')
    bool get hasFruits;

    @BuiltValueField(wireName: r'fruits')
    BuiltList<FruitInCharacter>? get fruits;

    /// Maximum number of fruit this character can eat.
    @BuiltValueField(wireName: r'fruit_limit')
    int get fruitLimit;

    @BuiltValueField(wireName: r'group_gain')
    int get groupGain;

    @BuiltValueField(wireName: r'attack')
    int get attack;

    @BuiltValueField(wireName: r'defense')
    int get defense;

    @BuiltValueField(wireName: r'intelligence')
    int get intelligence;

    @BuiltValueField(wireName: r'blood')
    int get blood;

    @BuiltValueField(wireName: r'speed')
    int get speed;

    @BuiltValueField(wireName: r'magic')
    int get magic;

    Character._();

    @BuiltValueHook(initializeBuilder: true)
    static void _defaults(CharacterBuilder b) => b
        ..fruitLimit = 1;

    factory Character([void updates(CharacterBuilder b)]) = _$Character;

    @BuiltValueSerializer(custom: true)
    static Serializer<Character> get serializer => _$CharacterSerializer();
}

class _$CharacterSerializer implements StructuredSerializer<Character> {
    @override
    final Iterable<Type> types = const [Character, _$Character];

    @override
    final String wireName = r'Character';

    @override
    Iterable<Object?> serialize(Serializers serializers, Character object,
        {FullType specifiedType = FullType.unspecified}) {
        final result = <Object?>[];
        result
            ..add(r'id')
            ..add(serializers.serialize(object.id,
                specifiedType: const FullType(String)));
        if (object.characterTypes != null) {
            result
                ..add(r'character_types')
                ..add(serializers.serialize(object.characterTypes,
                    specifiedType: const FullType(BuiltList, [FullType(CharacterTypeInfo)])));
        }
        result
            ..add(r'name')
            ..add(serializers.serialize(object.name,
                specifiedType: const FullType(String)));
        if (object.groupOid != null) {
            result
                ..add(r'group_oid')
                ..add(serializers.serialize(object.groupOid,
                    specifiedType: const FullType(String)));
        }
        result
            ..add(r'has_fruits')
            ..add(serializers.serialize(object.hasFruits,
                specifiedType: const FullType(bool)));
        if (object.fruits != null) {
            result
                ..add(r'fruits')
                ..add(serializers.serialize(object.fruits,
                    specifiedType: const FullType(BuiltList, [FullType(FruitInCharacter)])));
        }
        result
            ..add(r'fruit_limit')
            ..add(serializers.serialize(object.fruitLimit,
                specifiedType: const FullType(int)));
        result
            ..add(r'group_gain')
            ..add(serializers.serialize(object.groupGain,
                specifiedType: const FullType(int)));
        result
            ..add(r'attack')
            ..add(serializers.serialize(object.attack,
                specifiedType: const FullType(int)));
        result
            ..add(r'defense')
            ..add(serializers.serialize(object.defense,
                specifiedType: const FullType(int)));
        result
            ..add(r'intelligence')
            ..add(serializers.serialize(object.intelligence,
                specifiedType: const FullType(int)));
        result
            ..add(r'blood')
            ..add(serializers.serialize(object.blood,
                specifiedType: const FullType(int)));
        result
            ..add(r'speed')
            ..add(serializers.serialize(object.speed,
                specifiedType: const FullType(int)));
        result
            ..add(r'magic')
            ..add(serializers.serialize(object.magic,
                specifiedType: const FullType(int)));
        return result;
    }

    @override
    Character deserialize(Serializers serializers, Iterable<Object?> serialized,
        {FullType specifiedType = FullType.unspecified}) {
        final result = CharacterBuilder();

        final iterator = serialized.iterator;
        while (iterator.moveNext()) {
            final key = iterator.current as String;
            iterator.moveNext();
            final Object? value = iterator.current;
            
            switch (key) {
                case r'id':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(String)) as String;
                    result.id = valueDes;
                    break;
                case r'character_types':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(BuiltList, [FullType(CharacterTypeInfo)])) as BuiltList<CharacterTypeInfo>;
                    result.characterTypes.replace(valueDes);
                    break;
                case r'name':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(String)) as String;
                    result.name = valueDes;
                    break;
                case r'group_oid':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(String)) as String;
                    result.groupOid = valueDes;
                    break;
                case r'has_fruits':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(bool)) as bool;
                    result.hasFruits = valueDes;
                    break;
                case r'fruits':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(BuiltList, [FullType(FruitInCharacter)])) as BuiltList<FruitInCharacter>;
                    result.fruits.replace(valueDes);
                    break;
                case r'fruit_limit':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(int)) as int;
                    result.fruitLimit = valueDes;
                    break;
                case r'group_gain':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(int)) as int;
                    result.groupGain = valueDes;
                    break;
                case r'attack':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(int)) as int;
                    result.attack = valueDes;
                    break;
                case r'defense':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(int)) as int;
                    result.defense = valueDes;
                    break;
                case r'intelligence':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(int)) as int;
                    result.intelligence = valueDes;
                    break;
                case r'blood':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(int)) as int;
                    result.blood = valueDes;
                    break;
                case r'speed':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(int)) as int;
                    result.speed = valueDes;
                    break;
                case r'magic':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(int)) as int;
                    result.magic = valueDes;
                    break;
            }
        }
        return result.build();
    }
}

