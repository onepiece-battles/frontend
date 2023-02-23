//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:openapi/src/model/character.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'eat_fruit_response.g.dart';

/// EatFruitResponse
///
/// Properties:
/// * [character] 
/// * [fruitMessage] 
abstract class EatFruitResponse implements Built<EatFruitResponse, EatFruitResponseBuilder> {
    @BuiltValueField(wireName: r'character')
    Character get character;

    @BuiltValueField(wireName: r'fruit_message')
    String get fruitMessage;

    EatFruitResponse._();

    @BuiltValueHook(initializeBuilder: true)
    static void _defaults(EatFruitResponseBuilder b) => b;

    factory EatFruitResponse([void updates(EatFruitResponseBuilder b)]) = _$EatFruitResponse;

    @BuiltValueSerializer(custom: true)
    static Serializer<EatFruitResponse> get serializer => _$EatFruitResponseSerializer();
}

class _$EatFruitResponseSerializer implements StructuredSerializer<EatFruitResponse> {
    @override
    final Iterable<Type> types = const [EatFruitResponse, _$EatFruitResponse];

    @override
    final String wireName = r'EatFruitResponse';

    @override
    Iterable<Object?> serialize(Serializers serializers, EatFruitResponse object,
        {FullType specifiedType = FullType.unspecified}) {
        final result = <Object?>[];
        result
            ..add(r'character')
            ..add(serializers.serialize(object.character,
                specifiedType: const FullType(Character)));
        result
            ..add(r'fruit_message')
            ..add(serializers.serialize(object.fruitMessage,
                specifiedType: const FullType(String)));
        return result;
    }

    @override
    EatFruitResponse deserialize(Serializers serializers, Iterable<Object?> serialized,
        {FullType specifiedType = FullType.unspecified}) {
        final result = EatFruitResponseBuilder();

        final iterator = serialized.iterator;
        while (iterator.moveNext()) {
            final key = iterator.current as String;
            iterator.moveNext();
            final Object? value = iterator.current;
            
            switch (key) {
                case r'character':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(Character)) as Character;
                    result.character.replace(valueDes);
                    break;
                case r'fruit_message':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(String)) as String;
                    result.fruitMessage = valueDes;
                    break;
            }
        }
        return result.build();
    }
}

