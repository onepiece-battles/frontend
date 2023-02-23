//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'add_battle_request.g.dart';

/// AddBattleRequest
///
/// Properties:
/// * [userId] 
/// * [initiateCharacterId] 
/// * [receiverCharacterId] 
abstract class AddBattleRequest implements Built<AddBattleRequest, AddBattleRequestBuilder> {
    @BuiltValueField(wireName: r'user_id')
    String get userId;

    @BuiltValueField(wireName: r'initiate_character_id')
    String get initiateCharacterId;

    @BuiltValueField(wireName: r'receiver_character_id')
    String get receiverCharacterId;

    AddBattleRequest._();

    @BuiltValueHook(initializeBuilder: true)
    static void _defaults(AddBattleRequestBuilder b) => b;

    factory AddBattleRequest([void updates(AddBattleRequestBuilder b)]) = _$AddBattleRequest;

    @BuiltValueSerializer(custom: true)
    static Serializer<AddBattleRequest> get serializer => _$AddBattleRequestSerializer();
}

class _$AddBattleRequestSerializer implements StructuredSerializer<AddBattleRequest> {
    @override
    final Iterable<Type> types = const [AddBattleRequest, _$AddBattleRequest];

    @override
    final String wireName = r'AddBattleRequest';

    @override
    Iterable<Object?> serialize(Serializers serializers, AddBattleRequest object,
        {FullType specifiedType = FullType.unspecified}) {
        final result = <Object?>[];
        result
            ..add(r'user_id')
            ..add(serializers.serialize(object.userId,
                specifiedType: const FullType(String)));
        result
            ..add(r'initiate_character_id')
            ..add(serializers.serialize(object.initiateCharacterId,
                specifiedType: const FullType(String)));
        result
            ..add(r'receiver_character_id')
            ..add(serializers.serialize(object.receiverCharacterId,
                specifiedType: const FullType(String)));
        return result;
    }

    @override
    AddBattleRequest deserialize(Serializers serializers, Iterable<Object?> serialized,
        {FullType specifiedType = FullType.unspecified}) {
        final result = AddBattleRequestBuilder();

        final iterator = serialized.iterator;
        while (iterator.moveNext()) {
            final key = iterator.current as String;
            iterator.moveNext();
            final Object? value = iterator.current;
            
            switch (key) {
                case r'user_id':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(String)) as String;
                    result.userId = valueDes;
                    break;
                case r'initiate_character_id':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(String)) as String;
                    result.initiateCharacterId = valueDes;
                    break;
                case r'receiver_character_id':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(String)) as String;
                    result.receiverCharacterId = valueDes;
                    break;
            }
        }
        return result.build();
    }
}

