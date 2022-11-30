//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'login_request.g.dart';

/// LoginRequest
///
/// Properties:
/// * [userName] 
/// * [email] 
/// * [organization] 
/// * [password] 
abstract class LoginRequest implements Built<LoginRequest, LoginRequestBuilder> {
    @BuiltValueField(wireName: r'user_name')
    String get userName;

    @BuiltValueField(wireName: r'email')
    String get email;

    @BuiltValueField(wireName: r'organization')
    String? get organization;

    @BuiltValueField(wireName: r'password')
    String get password;

    LoginRequest._();

    @BuiltValueHook(initializeBuilder: true)
    static void _defaults(LoginRequestBuilder b) => b;

    factory LoginRequest([void updates(LoginRequestBuilder b)]) = _$LoginRequest;

    @BuiltValueSerializer(custom: true)
    static Serializer<LoginRequest> get serializer => _$LoginRequestSerializer();
}

class _$LoginRequestSerializer implements StructuredSerializer<LoginRequest> {
    @override
    final Iterable<Type> types = const [LoginRequest, _$LoginRequest];

    @override
    final String wireName = r'LoginRequest';

    @override
    Iterable<Object?> serialize(Serializers serializers, LoginRequest object,
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
        if (object.organization != null) {
            result
                ..add(r'organization')
                ..add(serializers.serialize(object.organization,
                    specifiedType: const FullType(String)));
        }
        result
            ..add(r'password')
            ..add(serializers.serialize(object.password,
                specifiedType: const FullType(String)));
        return result;
    }

    @override
    LoginRequest deserialize(Serializers serializers, Iterable<Object?> serialized,
        {FullType specifiedType = FullType.unspecified}) {
        final result = LoginRequestBuilder();

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
                case r'organization':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(String)) as String;
                    result.organization = valueDes;
                    break;
                case r'password':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(String)) as String;
                    result.password = valueDes;
                    break;
            }
        }
        return result.build();
    }
}

