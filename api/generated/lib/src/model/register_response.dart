//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'register_response.g.dart';

/// RegisterResponse
///
/// Properties:
/// * [registerResult] - Whether user has successfully registered into system.
/// * [verification] - OK if successfully registered, otherwise explain why register failed.
abstract class RegisterResponse implements Built<RegisterResponse, RegisterResponseBuilder> {
    /// Whether user has successfully registered into system.
    @BuiltValueField(wireName: r'register_result')
    bool get registerResult;

    /// OK if successfully registered, otherwise explain why register failed.
    @BuiltValueField(wireName: r'verification')
    String get verification;

    RegisterResponse._();

    @BuiltValueHook(initializeBuilder: true)
    static void _defaults(RegisterResponseBuilder b) => b;

    factory RegisterResponse([void updates(RegisterResponseBuilder b)]) = _$RegisterResponse;

    @BuiltValueSerializer(custom: true)
    static Serializer<RegisterResponse> get serializer => _$RegisterResponseSerializer();
}

class _$RegisterResponseSerializer implements StructuredSerializer<RegisterResponse> {
    @override
    final Iterable<Type> types = const [RegisterResponse, _$RegisterResponse];

    @override
    final String wireName = r'RegisterResponse';

    @override
    Iterable<Object?> serialize(Serializers serializers, RegisterResponse object,
        {FullType specifiedType = FullType.unspecified}) {
        final result = <Object?>[];
        result
            ..add(r'register_result')
            ..add(serializers.serialize(object.registerResult,
                specifiedType: const FullType(bool)));
        result
            ..add(r'verification')
            ..add(serializers.serialize(object.verification,
                specifiedType: const FullType(String)));
        return result;
    }

    @override
    RegisterResponse deserialize(Serializers serializers, Iterable<Object?> serialized,
        {FullType specifiedType = FullType.unspecified}) {
        final result = RegisterResponseBuilder();

        final iterator = serialized.iterator;
        while (iterator.moveNext()) {
            final key = iterator.current as String;
            iterator.moveNext();
            final Object? value = iterator.current;
            
            switch (key) {
                case r'register_result':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(bool)) as bool;
                    result.registerResult = valueDes;
                    break;
                case r'verification':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(String)) as String;
                    result.verification = valueDes;
                    break;
            }
        }
        return result.build();
    }
}

