//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'eat_fruit_request.g.dart';

/// EatFruitRequest
///
/// Properties:
/// * [characterId] 
/// * [fruitId] 
abstract class EatFruitRequest implements Built<EatFruitRequest, EatFruitRequestBuilder> {
    @BuiltValueField(wireName: r'character_id')
    String get characterId;

    @BuiltValueField(wireName: r'fruit_id')
    String get fruitId;

    EatFruitRequest._();

    @BuiltValueHook(initializeBuilder: true)
    static void _defaults(EatFruitRequestBuilder b) => b;

    factory EatFruitRequest([void updates(EatFruitRequestBuilder b)]) = _$EatFruitRequest;

    @BuiltValueSerializer(custom: true)
    static Serializer<EatFruitRequest> get serializer => _$EatFruitRequestSerializer();
}

class _$EatFruitRequestSerializer implements StructuredSerializer<EatFruitRequest> {
    @override
    final Iterable<Type> types = const [EatFruitRequest, _$EatFruitRequest];

    @override
    final String wireName = r'EatFruitRequest';

    @override
    Iterable<Object?> serialize(Serializers serializers, EatFruitRequest object,
        {FullType specifiedType = FullType.unspecified}) {
        final result = <Object?>[];
        result
            ..add(r'character_id')
            ..add(serializers.serialize(object.characterId,
                specifiedType: const FullType(String)));
        result
            ..add(r'fruit_id')
            ..add(serializers.serialize(object.fruitId,
                specifiedType: const FullType(String)));
        return result;
    }

    @override
    EatFruitRequest deserialize(Serializers serializers, Iterable<Object?> serialized,
        {FullType specifiedType = FullType.unspecified}) {
        final result = EatFruitRequestBuilder();

        final iterator = serialized.iterator;
        while (iterator.moveNext()) {
            final key = iterator.current as String;
            iterator.moveNext();
            final Object? value = iterator.current;
            
            switch (key) {
                case r'character_id':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(String)) as String;
                    result.characterId = valueDes;
                    break;
                case r'fruit_id':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(String)) as String;
                    result.fruitId = valueDes;
                    break;
            }
        }
        return result.build();
    }
}

