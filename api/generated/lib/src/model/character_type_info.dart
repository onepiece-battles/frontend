//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:openapi/src/model/character_type.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'character_type_info.g.dart';

/// List of CharacterType above can not be serialize in Response body. Use a class to wrap it.
///
/// Properties:
/// * [type] 
/// * [index] 
abstract class CharacterTypeInfo implements Built<CharacterTypeInfo, CharacterTypeInfoBuilder> {
    @BuiltValueField(wireName: r'type')
    CharacterType? get type;
    // enum typeEnum {  Katana,  Fist,  Foot,  Shooter,  Body,  Skill,  };

    @BuiltValueField(wireName: r'index')
    int? get index;

    CharacterTypeInfo._();

    @BuiltValueHook(initializeBuilder: true)
    static void _defaults(CharacterTypeInfoBuilder b) => b;

    factory CharacterTypeInfo([void updates(CharacterTypeInfoBuilder b)]) = _$CharacterTypeInfo;

    @BuiltValueSerializer(custom: true)
    static Serializer<CharacterTypeInfo> get serializer => _$CharacterTypeInfoSerializer();
}

class _$CharacterTypeInfoSerializer implements StructuredSerializer<CharacterTypeInfo> {
    @override
    final Iterable<Type> types = const [CharacterTypeInfo, _$CharacterTypeInfo];

    @override
    final String wireName = r'CharacterTypeInfo';

    @override
    Iterable<Object?> serialize(Serializers serializers, CharacterTypeInfo object,
        {FullType specifiedType = FullType.unspecified}) {
        final result = <Object?>[];
        if (object.type != null) {
            result
                ..add(r'type')
                ..add(serializers.serialize(object.type,
                    specifiedType: const FullType(CharacterType)));
        }
        if (object.index != null) {
            result
                ..add(r'index')
                ..add(serializers.serialize(object.index,
                    specifiedType: const FullType(int)));
        }
        return result;
    }

    @override
    CharacterTypeInfo deserialize(Serializers serializers, Iterable<Object?> serialized,
        {FullType specifiedType = FullType.unspecified}) {
        final result = CharacterTypeInfoBuilder();

        final iterator = serialized.iterator;
        while (iterator.moveNext()) {
            final key = iterator.current as String;
            iterator.moveNext();
            final Object? value = iterator.current;
            
            switch (key) {
                case r'type':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(CharacterType)) as CharacterType;
                    result.type = valueDes;
                    break;
                case r'index':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(int)) as int;
                    result.index = valueDes;
                    break;
            }
        }
        return result.build();
    }
}

