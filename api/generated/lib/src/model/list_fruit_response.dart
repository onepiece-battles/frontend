//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:built_collection/built_collection.dart';
import 'package:openapi/src/model/fruit.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'list_fruit_response.g.dart';

/// ListFruitResponse
///
/// Properties:
/// * [fruits] 
abstract class ListFruitResponse implements Built<ListFruitResponse, ListFruitResponseBuilder> {
    @BuiltValueField(wireName: r'fruits')
    BuiltList<Fruit>? get fruits;

    ListFruitResponse._();

    @BuiltValueHook(initializeBuilder: true)
    static void _defaults(ListFruitResponseBuilder b) => b;

    factory ListFruitResponse([void updates(ListFruitResponseBuilder b)]) = _$ListFruitResponse;

    @BuiltValueSerializer(custom: true)
    static Serializer<ListFruitResponse> get serializer => _$ListFruitResponseSerializer();
}

class _$ListFruitResponseSerializer implements StructuredSerializer<ListFruitResponse> {
    @override
    final Iterable<Type> types = const [ListFruitResponse, _$ListFruitResponse];

    @override
    final String wireName = r'ListFruitResponse';

    @override
    Iterable<Object?> serialize(Serializers serializers, ListFruitResponse object,
        {FullType specifiedType = FullType.unspecified}) {
        final result = <Object?>[];
        if (object.fruits != null) {
            result
                ..add(r'fruits')
                ..add(serializers.serialize(object.fruits,
                    specifiedType: const FullType(BuiltList, [FullType(Fruit)])));
        }
        return result;
    }

    @override
    ListFruitResponse deserialize(Serializers serializers, Iterable<Object?> serialized,
        {FullType specifiedType = FullType.unspecified}) {
        final result = ListFruitResponseBuilder();

        final iterator = serialized.iterator;
        while (iterator.moveNext()) {
            final key = iterator.current as String;
            iterator.moveNext();
            final Object? value = iterator.current;
            
            switch (key) {
                case r'fruits':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(BuiltList, [FullType(Fruit)])) as BuiltList<Fruit>;
                    result.fruits.replace(valueDes);
                    break;
            }
        }
        return result.build();
    }
}

