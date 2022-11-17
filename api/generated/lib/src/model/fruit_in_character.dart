//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'fruit_in_character.g.dart';

/// describe the fruit condition after it is eaten by character 
///
/// Properties:
/// * [fruitId] 
/// * [wakeUp] 
abstract class FruitInCharacter implements Built<FruitInCharacter, FruitInCharacterBuilder> {
    @BuiltValueField(wireName: r'fruit_id')
    String get fruitId;

    @BuiltValueField(wireName: r'wake_up')
    bool get wakeUp;

    FruitInCharacter._();

    @BuiltValueHook(initializeBuilder: true)
    static void _defaults(FruitInCharacterBuilder b) => b;

    factory FruitInCharacter([void updates(FruitInCharacterBuilder b)]) = _$FruitInCharacter;

    @BuiltValueSerializer(custom: true)
    static Serializer<FruitInCharacter> get serializer => _$FruitInCharacterSerializer();
}

class _$FruitInCharacterSerializer implements StructuredSerializer<FruitInCharacter> {
    @override
    final Iterable<Type> types = const [FruitInCharacter, _$FruitInCharacter];

    @override
    final String wireName = r'FruitInCharacter';

    @override
    Iterable<Object?> serialize(Serializers serializers, FruitInCharacter object,
        {FullType specifiedType = FullType.unspecified}) {
        final result = <Object?>[];
        result
            ..add(r'fruit_id')
            ..add(serializers.serialize(object.fruitId,
                specifiedType: const FullType(String)));
        result
            ..add(r'wake_up')
            ..add(serializers.serialize(object.wakeUp,
                specifiedType: const FullType(bool)));
        return result;
    }

    @override
    FruitInCharacter deserialize(Serializers serializers, Iterable<Object?> serialized,
        {FullType specifiedType = FullType.unspecified}) {
        final result = FruitInCharacterBuilder();

        final iterator = serialized.iterator;
        while (iterator.moveNext()) {
            final key = iterator.current as String;
            iterator.moveNext();
            final Object? value = iterator.current;
            
            switch (key) {
                case r'fruit_id':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(String)) as String;
                    result.fruitId = valueDes;
                    break;
                case r'wake_up':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(bool)) as bool;
                    result.wakeUp = valueDes;
                    break;
            }
        }
        return result.build();
    }
}

