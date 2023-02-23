//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:openapi/src/model/battle_result.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'start_battle_response.g.dart';

/// StartBattleResponse
///
/// Properties:
/// * [battleId] 
/// * [result] 
abstract class StartBattleResponse implements Built<StartBattleResponse, StartBattleResponseBuilder> {
    @BuiltValueField(wireName: r'battle_id')
    String? get battleId;

    @BuiltValueField(wireName: r'result')
    BattleResult? get result;

    StartBattleResponse._();

    @BuiltValueHook(initializeBuilder: true)
    static void _defaults(StartBattleResponseBuilder b) => b;

    factory StartBattleResponse([void updates(StartBattleResponseBuilder b)]) = _$StartBattleResponse;

    @BuiltValueSerializer(custom: true)
    static Serializer<StartBattleResponse> get serializer => _$StartBattleResponseSerializer();
}

class _$StartBattleResponseSerializer implements StructuredSerializer<StartBattleResponse> {
    @override
    final Iterable<Type> types = const [StartBattleResponse, _$StartBattleResponse];

    @override
    final String wireName = r'StartBattleResponse';

    @override
    Iterable<Object?> serialize(Serializers serializers, StartBattleResponse object,
        {FullType specifiedType = FullType.unspecified}) {
        final result = <Object?>[];
        if (object.battleId != null) {
            result
                ..add(r'battle_id')
                ..add(serializers.serialize(object.battleId,
                    specifiedType: const FullType(String)));
        }
        if (object.result != null) {
            result
                ..add(r'result')
                ..add(serializers.serialize(object.result,
                    specifiedType: const FullType(BattleResult)));
        }
        return result;
    }

    @override
    StartBattleResponse deserialize(Serializers serializers, Iterable<Object?> serialized,
        {FullType specifiedType = FullType.unspecified}) {
        final result = StartBattleResponseBuilder();

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
                case r'result':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(BattleResult)) as BattleResult;
                    result.result.replace(valueDes);
                    break;
            }
        }
        return result.build();
    }
}

