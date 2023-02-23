//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'start_battle_request.g.dart';

/// StartBattleRequest
///
/// Properties:
/// * [battleId] 
abstract class StartBattleRequest implements Built<StartBattleRequest, StartBattleRequestBuilder> {
    @BuiltValueField(wireName: r'battle_id')
    String get battleId;

    StartBattleRequest._();

    @BuiltValueHook(initializeBuilder: true)
    static void _defaults(StartBattleRequestBuilder b) => b;

    factory StartBattleRequest([void updates(StartBattleRequestBuilder b)]) = _$StartBattleRequest;

    @BuiltValueSerializer(custom: true)
    static Serializer<StartBattleRequest> get serializer => _$StartBattleRequestSerializer();
}

class _$StartBattleRequestSerializer implements StructuredSerializer<StartBattleRequest> {
    @override
    final Iterable<Type> types = const [StartBattleRequest, _$StartBattleRequest];

    @override
    final String wireName = r'StartBattleRequest';

    @override
    Iterable<Object?> serialize(Serializers serializers, StartBattleRequest object,
        {FullType specifiedType = FullType.unspecified}) {
        final result = <Object?>[];
        result
            ..add(r'battle_id')
            ..add(serializers.serialize(object.battleId,
                specifiedType: const FullType(String)));
        return result;
    }

    @override
    StartBattleRequest deserialize(Serializers serializers, Iterable<Object?> serialized,
        {FullType specifiedType = FullType.unspecified}) {
        final result = StartBattleRequestBuilder();

        final iterator = serialized.iterator;
        while (iterator.moveNext()) {
            final key = iterator.current as String;
            iterator.moveNext();
            final Object? value = iterator.current;
            
            switch (key) {
                case r'battle_id':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(String)) as String;
                    result.battleId = valueDes;
                    break;
            }
        }
        return result.build();
    }
}

