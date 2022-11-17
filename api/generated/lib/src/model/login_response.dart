//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:openapi/src/model/user_info.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'login_response.g.dart';

/// LoginResponse
///
/// Properties:
/// * [userInfo] 
/// * [verification] 
abstract class LoginResponse implements Built<LoginResponse, LoginResponseBuilder> {
    @BuiltValueField(wireName: r'user_info')
    UserInfo? get userInfo;

    @BuiltValueField(wireName: r'verification')
    String? get verification;

    LoginResponse._();

    @BuiltValueHook(initializeBuilder: true)
    static void _defaults(LoginResponseBuilder b) => b;

    factory LoginResponse([void updates(LoginResponseBuilder b)]) = _$LoginResponse;

    @BuiltValueSerializer(custom: true)
    static Serializer<LoginResponse> get serializer => _$LoginResponseSerializer();
}

class _$LoginResponseSerializer implements StructuredSerializer<LoginResponse> {
    @override
    final Iterable<Type> types = const [LoginResponse, _$LoginResponse];

    @override
    final String wireName = r'LoginResponse';

    @override
    Iterable<Object?> serialize(Serializers serializers, LoginResponse object,
        {FullType specifiedType = FullType.unspecified}) {
        final result = <Object?>[];
        if (object.userInfo != null) {
            result
                ..add(r'user_info')
                ..add(serializers.serialize(object.userInfo,
                    specifiedType: const FullType(UserInfo)));
        }
        if (object.verification != null) {
            result
                ..add(r'verification')
                ..add(serializers.serialize(object.verification,
                    specifiedType: const FullType(String)));
        }
        return result;
    }

    @override
    LoginResponse deserialize(Serializers serializers, Iterable<Object?> serialized,
        {FullType specifiedType = FullType.unspecified}) {
        final result = LoginResponseBuilder();

        final iterator = serialized.iterator;
        while (iterator.moveNext()) {
            final key = iterator.current as String;
            iterator.moveNext();
            final Object? value = iterator.current;
            
            switch (key) {
                case r'user_info':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(UserInfo)) as UserInfo;
                    result.userInfo.replace(valueDes);
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

