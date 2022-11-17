//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'list_character_request.g.dart';

/// ListCharacterRequest
///
/// Properties:
/// * [pageSize] 
/// * [pageIndex] 
abstract class ListCharacterRequest implements Built<ListCharacterRequest, ListCharacterRequestBuilder> {
    @BuiltValueField(wireName: r'page_size')
    int get pageSize;

    @BuiltValueField(wireName: r'page_index')
    int get pageIndex;

    ListCharacterRequest._();

    @BuiltValueHook(initializeBuilder: true)
    static void _defaults(ListCharacterRequestBuilder b) => b;

    factory ListCharacterRequest([void updates(ListCharacterRequestBuilder b)]) = _$ListCharacterRequest;

    @BuiltValueSerializer(custom: true)
    static Serializer<ListCharacterRequest> get serializer => _$ListCharacterRequestSerializer();
}

class _$ListCharacterRequestSerializer implements StructuredSerializer<ListCharacterRequest> {
    @override
    final Iterable<Type> types = const [ListCharacterRequest, _$ListCharacterRequest];

    @override
    final String wireName = r'ListCharacterRequest';

    @override
    Iterable<Object?> serialize(Serializers serializers, ListCharacterRequest object,
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
    ListCharacterRequest deserialize(Serializers serializers, Iterable<Object?> serialized,
        {FullType specifiedType = FullType.unspecified}) {
        final result = ListCharacterRequestBuilder();

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

