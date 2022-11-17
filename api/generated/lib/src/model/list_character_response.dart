//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:built_collection/built_collection.dart';
import 'package:openapi/src/model/character.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'list_character_response.g.dart';

/// ListCharacterResponse
///
/// Properties:
/// * [characters] 
abstract class ListCharacterResponse implements Built<ListCharacterResponse, ListCharacterResponseBuilder> {
    @BuiltValueField(wireName: r'Characters')
    BuiltList<Character>? get characters;

    ListCharacterResponse._();

    @BuiltValueHook(initializeBuilder: true)
    static void _defaults(ListCharacterResponseBuilder b) => b;

    factory ListCharacterResponse([void updates(ListCharacterResponseBuilder b)]) = _$ListCharacterResponse;

    @BuiltValueSerializer(custom: true)
    static Serializer<ListCharacterResponse> get serializer => _$ListCharacterResponseSerializer();
}

class _$ListCharacterResponseSerializer implements StructuredSerializer<ListCharacterResponse> {
    @override
    final Iterable<Type> types = const [ListCharacterResponse, _$ListCharacterResponse];

    @override
    final String wireName = r'ListCharacterResponse';

    @override
    Iterable<Object?> serialize(Serializers serializers, ListCharacterResponse object,
        {FullType specifiedType = FullType.unspecified}) {
        final result = <Object?>[];
        if (object.characters != null) {
            result
                ..add(r'Characters')
                ..add(serializers.serialize(object.characters,
                    specifiedType: const FullType(BuiltList, [FullType(Character)])));
        }
        return result;
    }

    @override
    ListCharacterResponse deserialize(Serializers serializers, Iterable<Object?> serialized,
        {FullType specifiedType = FullType.unspecified}) {
        final result = ListCharacterResponseBuilder();

        final iterator = serialized.iterator;
        while (iterator.moveNext()) {
            final key = iterator.current as String;
            iterator.moveNext();
            final Object? value = iterator.current;
            
            switch (key) {
                case r'Characters':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(BuiltList, [FullType(Character)])) as BuiltList<Character>;
                    result.characters.replace(valueDes);
                    break;
            }
        }
        return result.build();
    }
}

