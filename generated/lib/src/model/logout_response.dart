//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'logout_response.g.dart';

/// LogoutResponse
///
/// Properties:
/// * [userName] 
/// * [logoutResult] - whether user has successfully logout.
abstract class LogoutResponse implements Built<LogoutResponse, LogoutResponseBuilder> {
    @BuiltValueField(wireName: r'user_name')
    String? get userName;

    /// whether user has successfully logout.
    @BuiltValueField(wireName: r'logout_result')
    String? get logoutResult;

    LogoutResponse._();

    @BuiltValueHook(initializeBuilder: true)
    static void _defaults(LogoutResponseBuilder b) => b;

    factory LogoutResponse([void updates(LogoutResponseBuilder b)]) = _$LogoutResponse;

    @BuiltValueSerializer(custom: true)
    static Serializer<LogoutResponse> get serializer => _$LogoutResponseSerializer();
}

class _$LogoutResponseSerializer implements StructuredSerializer<LogoutResponse> {
    @override
    final Iterable<Type> types = const [LogoutResponse, _$LogoutResponse];

    @override
    final String wireName = r'LogoutResponse';

    @override
    Iterable<Object?> serialize(Serializers serializers, LogoutResponse object,
        {FullType specifiedType = FullType.unspecified}) {
        final result = <Object?>[];
        if (object.userName != null) {
            result
                ..add(r'user_name')
                ..add(serializers.serialize(object.userName,
                    specifiedType: const FullType(String)));
        }
        if (object.logoutResult != null) {
            result
                ..add(r'logout_result')
                ..add(serializers.serialize(object.logoutResult,
                    specifiedType: const FullType(String)));
        }
        return result;
    }

    @override
    LogoutResponse deserialize(Serializers serializers, Iterable<Object?> serialized,
        {FullType specifiedType = FullType.unspecified}) {
        final result = LogoutResponseBuilder();

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
                case r'logout_result':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(String)) as String;
                    result.logoutResult = valueDes;
                    break;
            }
        }
        return result.build();
    }
}

