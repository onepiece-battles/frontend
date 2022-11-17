//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'register_request.g.dart';

/// RegisterRequest
///
/// Properties:
/// * [userName] 
/// * [email] 
/// * [password] 
/// * [confirmedPassword] 
/// * [organization] 
abstract class RegisterRequest implements Built<RegisterRequest, RegisterRequestBuilder> {
    @BuiltValueField(wireName: r'user_name')
    String get userName;

    @BuiltValueField(wireName: r'email')
    String get email;

    @BuiltValueField(wireName: r'password')
    String get password;

    @BuiltValueField(wireName: r'confirmed_password')
    String get confirmedPassword;

    @BuiltValueField(wireName: r'organization')
    String get organization;

    RegisterRequest._();

    @BuiltValueHook(initializeBuilder: true)
    static void _defaults(RegisterRequestBuilder b) => b;

    factory RegisterRequest([void updates(RegisterRequestBuilder b)]) = _$RegisterRequest;

    @BuiltValueSerializer(custom: true)
    static Serializer<RegisterRequest> get serializer => _$RegisterRequestSerializer();
}

class _$RegisterRequestSerializer implements StructuredSerializer<RegisterRequest> {
    @override
    final Iterable<Type> types = const [RegisterRequest, _$RegisterRequest];

    @override
    final String wireName = r'RegisterRequest';

    @override
    Iterable<Object?> serialize(Serializers serializers, RegisterRequest object,
        {FullType specifiedType = FullType.unspecified}) {
        final result = <Object?>[];
        result
            ..add(r'user_name')
            ..add(serializers.serialize(object.userName,
                specifiedType: const FullType(String)));
        result
            ..add(r'email')
            ..add(serializers.serialize(object.email,
                specifiedType: const FullType(String)));
        result
            ..add(r'password')
            ..add(serializers.serialize(object.password,
                specifiedType: const FullType(String)));
        result
            ..add(r'confirmed_password')
            ..add(serializers.serialize(object.confirmedPassword,
                specifiedType: const FullType(String)));
        result
            ..add(r'organization')
            ..add(serializers.serialize(object.organization,
                specifiedType: const FullType(String)));
        return result;
    }

    @override
    RegisterRequest deserialize(Serializers serializers, Iterable<Object?> serialized,
        {FullType specifiedType = FullType.unspecified}) {
        final result = RegisterRequestBuilder();

        final iterator = serialized.iterator;
        while (iterator.moveNext()) {
            final key = iterator.current as String;
            iterator.moveNext();
            final Object? value = iterator.current;
            
            switch (key) {
                case r'user_name':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(String)) as String;
                    result.userName = valueDes;
                    break;
                case r'email':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(String)) as String;
                    result.email = valueDes;
                    break;
                case r'password':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(String)) as String;
                    result.password = valueDes;
                    break;
                case r'confirmed_password':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(String)) as String;
                    result.confirmedPassword = valueDes;
                    break;
                case r'organization':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(String)) as String;
                    result.organization = valueDes;
                    break;
            }
        }
        return result.build();
    }
}

