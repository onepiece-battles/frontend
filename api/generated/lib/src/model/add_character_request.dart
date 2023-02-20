//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:built_collection/built_collection.dart';
import 'package:openapi/src/model/character_type_info.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'add_character_request.g.dart';

/// AddCharacterRequest
///
/// Properties:
/// * [characterTypes] - type of fighting skills
/// * [name] 
/// * [groupOid] - Which group this character is in.
/// * [fruitLimit] - Maximum number of fruit this character can eat.
/// * [groupGain] 
/// * [attack] 
/// * [defense] 
/// * [intelligence] 
/// * [blood] 
/// * [speed] 
/// * [magic] 
abstract class AddCharacterRequest implements Built<AddCharacterRequest, AddCharacterRequestBuilder> {
    /// type of fighting skills
    @BuiltValueField(wireName: r'character_types')
    BuiltList<CharacterTypeInfo> get characterTypes;

    @BuiltValueField(wireName: r'name')
    String get name;

    /// Which group this character is in.
    @BuiltValueField(wireName: r'group_oid')
    String? get groupOid;

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

    AddCharacterRequest._();

    @BuiltValueHook(initializeBuilder: true)
    static void _defaults(AddCharacterRequestBuilder b) => b;

    factory AddCharacterRequest([void updates(AddCharacterRequestBuilder b)]) = _$AddCharacterRequest;

    @BuiltValueSerializer(custom: true)
    static Serializer<AddCharacterRequest> get serializer => _$AddCharacterRequestSerializer();
}

class _$AddCharacterRequestSerializer implements StructuredSerializer<AddCharacterRequest> {
    @override
    final Iterable<Type> types = const [AddCharacterRequest, _$AddCharacterRequest];

    @override
    final String wireName = r'AddCharacterRequest';

    @override
    Iterable<Object?> serialize(Serializers serializers, AddCharacterRequest object,
        {FullType specifiedType = FullType.unspecified}) {
        final result = <Object?>[];
        result
            ..add(r'character_types')
            ..add(serializers.serialize(object.characterTypes,
                specifiedType: const FullType(BuiltList, [FullType(CharacterTypeInfo)])));
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
    AddCharacterRequest deserialize(Serializers serializers, Iterable<Object?> serialized,
        {FullType specifiedType = FullType.unspecified}) {
        final result = AddCharacterRequestBuilder();

        final iterator = serialized.iterator;
        while (iterator.moveNext()) {
            final key = iterator.current as String;
            iterator.moveNext();
            final Object? value = iterator.current;
            
            switch (key) {
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

