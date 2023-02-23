//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:openapi/src/model/fruit_type.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'add_fruit_request.g.dart';

/// AddFruitRequest
///
/// Properties:
/// * [name] 
/// * [fruitType] 
/// * [groupGainStrengthen] 
/// * [magicConsume] 
/// * [attackStrengthen] 
/// * [defenseStrengthen] 
/// * [intelligenceStrengthen] 
/// * [bloodStrengthen] 
/// * [speedStrengthen] 
abstract class AddFruitRequest implements Built<AddFruitRequest, AddFruitRequestBuilder> {
    @BuiltValueField(wireName: r'name')
    String? get name;

    @BuiltValueField(wireName: r'fruit_type')
    FruitType? get fruitType;
    // enum fruitTypeEnum {  Paramecia,  Logia,  Zoan,  Ancient_Zoan,  Mythical_Zoan,  Artificial_Zoan,  };

    @BuiltValueField(wireName: r'group_gain_strengthen')
    int? get groupGainStrengthen;

    @BuiltValueField(wireName: r'magic_consume')
    int? get magicConsume;

    @BuiltValueField(wireName: r'attack_strengthen')
    int? get attackStrengthen;

    @BuiltValueField(wireName: r'defense_strengthen')
    int? get defenseStrengthen;

    @BuiltValueField(wireName: r'intelligence_strengthen')
    int? get intelligenceStrengthen;

    @BuiltValueField(wireName: r'blood_strengthen')
    int? get bloodStrengthen;

    @BuiltValueField(wireName: r'speed_strengthen')
    int? get speedStrengthen;

    AddFruitRequest._();

    @BuiltValueHook(initializeBuilder: true)
    static void _defaults(AddFruitRequestBuilder b) => b;

    factory AddFruitRequest([void updates(AddFruitRequestBuilder b)]) = _$AddFruitRequest;

    @BuiltValueSerializer(custom: true)
    static Serializer<AddFruitRequest> get serializer => _$AddFruitRequestSerializer();
}

class _$AddFruitRequestSerializer implements StructuredSerializer<AddFruitRequest> {
    @override
    final Iterable<Type> types = const [AddFruitRequest, _$AddFruitRequest];

    @override
    final String wireName = r'AddFruitRequest';

    @override
    Iterable<Object?> serialize(Serializers serializers, AddFruitRequest object,
        {FullType specifiedType = FullType.unspecified}) {
        final result = <Object?>[];
        if (object.name != null) {
            result
                ..add(r'name')
                ..add(serializers.serialize(object.name,
                    specifiedType: const FullType(String)));
        }
        if (object.fruitType != null) {
            result
                ..add(r'fruit_type')
                ..add(serializers.serialize(object.fruitType,
                    specifiedType: const FullType(FruitType)));
        }
        if (object.groupGainStrengthen != null) {
            result
                ..add(r'group_gain_strengthen')
                ..add(serializers.serialize(object.groupGainStrengthen,
                    specifiedType: const FullType(int)));
        }
        if (object.magicConsume != null) {
            result
                ..add(r'magic_consume')
                ..add(serializers.serialize(object.magicConsume,
                    specifiedType: const FullType(int)));
        }
        if (object.attackStrengthen != null) {
            result
                ..add(r'attack_strengthen')
                ..add(serializers.serialize(object.attackStrengthen,
                    specifiedType: const FullType(int)));
        }
        if (object.defenseStrengthen != null) {
            result
                ..add(r'defense_strengthen')
                ..add(serializers.serialize(object.defenseStrengthen,
                    specifiedType: const FullType(int)));
        }
        if (object.intelligenceStrengthen != null) {
            result
                ..add(r'intelligence_strengthen')
                ..add(serializers.serialize(object.intelligenceStrengthen,
                    specifiedType: const FullType(int)));
        }
        if (object.bloodStrengthen != null) {
            result
                ..add(r'blood_strengthen')
                ..add(serializers.serialize(object.bloodStrengthen,
                    specifiedType: const FullType(int)));
        }
        if (object.speedStrengthen != null) {
            result
                ..add(r'speed_strengthen')
                ..add(serializers.serialize(object.speedStrengthen,
                    specifiedType: const FullType(int)));
        }
        return result;
    }

    @override
    AddFruitRequest deserialize(Serializers serializers, Iterable<Object?> serialized,
        {FullType specifiedType = FullType.unspecified}) {
        final result = AddFruitRequestBuilder();

        final iterator = serialized.iterator;
        while (iterator.moveNext()) {
            final key = iterator.current as String;
            iterator.moveNext();
            final Object? value = iterator.current;
            
            switch (key) {
                case r'name':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(String)) as String;
                    result.name = valueDes;
                    break;
                case r'fruit_type':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(FruitType)) as FruitType;
                    result.fruitType = valueDes;
                    break;
                case r'group_gain_strengthen':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(int)) as int;
                    result.groupGainStrengthen = valueDes;
                    break;
                case r'magic_consume':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(int)) as int;
                    result.magicConsume = valueDes;
                    break;
                case r'attack_strengthen':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(int)) as int;
                    result.attackStrengthen = valueDes;
                    break;
                case r'defense_strengthen':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(int)) as int;
                    result.defenseStrengthen = valueDes;
                    break;
                case r'intelligence_strengthen':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(int)) as int;
                    result.intelligenceStrengthen = valueDes;
                    break;
                case r'blood_strengthen':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(int)) as int;
                    result.bloodStrengthen = valueDes;
                    break;
                case r'speed_strengthen':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(int)) as int;
                    result.speedStrengthen = valueDes;
                    break;
            }
        }
        return result.build();
    }
}

