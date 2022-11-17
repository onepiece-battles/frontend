//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'list_fruit_request.g.dart';

/// ListFruitRequest
///
/// Properties:
/// * [pageSize] 
/// * [pageIndex] 
abstract class ListFruitRequest implements Built<ListFruitRequest, ListFruitRequestBuilder> {
    @BuiltValueField(wireName: r'page_size')
    int get pageSize;

    @BuiltValueField(wireName: r'page_index')
    int get pageIndex;

    ListFruitRequest._();

    @BuiltValueHook(initializeBuilder: true)
    static void _defaults(ListFruitRequestBuilder b) => b;

    factory ListFruitRequest([void updates(ListFruitRequestBuilder b)]) = _$ListFruitRequest;

    @BuiltValueSerializer(custom: true)
    static Serializer<ListFruitRequest> get serializer => _$ListFruitRequestSerializer();
}

class _$ListFruitRequestSerializer implements StructuredSerializer<ListFruitRequest> {
    @override
    final Iterable<Type> types = const [ListFruitRequest, _$ListFruitRequest];

    @override
    final String wireName = r'ListFruitRequest';

    @override
    Iterable<Object?> serialize(Serializers serializers, ListFruitRequest object,
        {FullType specifiedType = FullType.unspecified}) {
        final result = <Object?>[];
        result
            ..add(r'page_size')
            ..add(serializers.serialize(object.pageSize,
                specifiedType: const FullType(int)));
        result
            ..add(r'page_index')
            ..add(serializers.serialize(object.pageIndex,
                specifiedType: const FullType(int)));
        return result;
    }

    @override
    ListFruitRequest deserialize(Serializers serializers, Iterable<Object?> serialized,
        {FullType specifiedType = FullType.unspecified}) {
        final result = ListFruitRequestBuilder();

        final iterator = serialized.iterator;
        while (iterator.moveNext()) {
            final key = iterator.current as String;
            iterator.moveNext();
            final Object? value = iterator.current;
            
            switch (key) {
                case r'page_size':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(int)) as int;
                    result.pageSize = valueDes;
                    break;
                case r'page_index':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(int)) as int;
                    result.pageIndex = valueDes;
                    break;
            }
        }
        return result.build();
    }
}

