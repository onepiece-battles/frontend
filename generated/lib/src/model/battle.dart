//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:openapi/src/model/battle_type.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'battle.g.dart';

/// Battle
///
/// Properties:
/// * [actionTimestamp] - the timestamp this battle is created
/// * [battleId] 
/// * [userId] 
/// * [initiateCharacterId] 
/// * [receiverCharacterId] 
/// * [type] 
abstract class Battle implements Built<Battle, BattleBuilder> {
    /// the timestamp this battle is created
    @BuiltValueField(wireName: r'action_timestamp')
    int get actionTimestamp;

    @BuiltValueField(wireName: r'battle_id')
    String get battleId;

    @BuiltValueField(wireName: r'user_id')
    String get userId;

    @BuiltValueField(wireName: r'initiate_character_id')
    String get initiateCharacterId;

    @BuiltValueField(wireName: r'receiver_character_id')
    String get receiverCharacterId;

    @BuiltValueField(wireName: r'type')
    BattleType get type;
    // enum typeEnum {  Single,  Group,  };

    Battle._();

    @BuiltValueHook(initializeBuilder: true)
    static void _defaults(BattleBuilder b) => b;

    factory Battle([void updates(BattleBuilder b)]) = _$Battle;

    @BuiltValueSerializer(custom: true)
    static Serializer<Battle> get serializer => _$BattleSerializer();
}

class _$BattleSerializer implements StructuredSerializer<Battle> {
    @override
    final Iterable<Type> types = const [Battle, _$Battle];

    @override
    final String wireName = r'Battle';

    @override
    Iterable<Object?> serialize(Serializers serializers, Battle object,
        {FullType specifiedType = FullType.unspecified}) {
        final result = <Object?>[];
        result
            ..add(r'action_timestamp')
            ..add(serializers.serialize(object.actionTimestamp,
                specifiedType: const FullType(int)));
        result
            ..add(r'battle_id')
            ..add(serializers.serialize(object.battleId,
                specifiedType: const FullType(String)));
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
        result
            ..add(r'type')
            ..add(serializers.serialize(object.type,
                specifiedType: const FullType(BattleType)));
        return result;
    }

    @override
    Battle deserialize(Serializers serializers, Iterable<Object?> serialized,
        {FullType specifiedType = FullType.unspecified}) {
        final result = BattleBuilder();

        final iterator = serialized.iterator;
        while (iterator.moveNext()) {
            final key = iterator.current as String;
            iterator.moveNext();
            final Object? value = iterator.current;
            
            switch (key) {
                case r'action_timestamp':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(int)) as int;
                    result.actionTimestamp = valueDes;
                    break;
                case r'battle_id':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(String)) as String;
                    result.battleId = valueDes;
                    break;
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
                case r'type':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(BattleType)) as BattleType;
                    result.type = valueDes;
                    break;
            }
        }
        return result.build();
    }
}

