//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'battle_result.g.dart';

/// BattleResult
///
/// Properties:
/// * [winnerId] - character id of winner.
/// * [loserId] - character id of loser.
/// * [winnerRemainBloodPercentage] - remaining blood/ total blood
abstract class BattleResult implements Built<BattleResult, BattleResultBuilder> {
    /// character id of winner.
    @BuiltValueField(wireName: r'winner_id')
    String? get winnerId;

    /// character id of loser.
    @BuiltValueField(wireName: r'loser_id')
    String? get loserId;

    /// remaining blood/ total blood
    @BuiltValueField(wireName: r'winner_remain_blood_percentage')
    double? get winnerRemainBloodPercentage;

    BattleResult._();

    @BuiltValueHook(initializeBuilder: true)
    static void _defaults(BattleResultBuilder b) => b;

    factory BattleResult([void updates(BattleResultBuilder b)]) = _$BattleResult;

    @BuiltValueSerializer(custom: true)
    static Serializer<BattleResult> get serializer => _$BattleResultSerializer();
}

class _$BattleResultSerializer implements StructuredSerializer<BattleResult> {
    @override
    final Iterable<Type> types = const [BattleResult, _$BattleResult];

    @override
    final String wireName = r'BattleResult';

    @override
    Iterable<Object?> serialize(Serializers serializers, BattleResult object,
        {FullType specifiedType = FullType.unspecified}) {
        final result = <Object?>[];
        if (object.winnerId != null) {
            result
                ..add(r'winner_id')
                ..add(serializers.serialize(object.winnerId,
                    specifiedType: const FullType(String)));
        }
        if (object.loserId != null) {
            result
                ..add(r'loser_id')
                ..add(serializers.serialize(object.loserId,
                    specifiedType: const FullType(String)));
        }
        if (object.winnerRemainBloodPercentage != null) {
            result
                ..add(r'winner_remain_blood_percentage')
                ..add(serializers.serialize(object.winnerRemainBloodPercentage,
                    specifiedType: const FullType(double)));
        }
        return result;
    }

    @override
    BattleResult deserialize(Serializers serializers, Iterable<Object?> serialized,
        {FullType specifiedType = FullType.unspecified}) {
        final result = BattleResultBuilder();

        final iterator = serialized.iterator;
        while (iterator.moveNext()) {
            final key = iterator.current as String;
            iterator.moveNext();
            final Object? value = iterator.current;
            
            switch (key) {
                case r'winner_id':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(String)) as String;
                    result.winnerId = valueDes;
                    break;
                case r'loser_id':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(String)) as String;
                    result.loserId = valueDes;
                    break;
                case r'winner_remain_blood_percentage':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(double)) as double;
                    result.winnerRemainBloodPercentage = valueDes;
                    break;
            }
        }
        return result.build();
    }
}

