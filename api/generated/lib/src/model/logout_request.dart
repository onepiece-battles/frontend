//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'logout_request.g.dart';

/// LogoutRequest
///
/// Properties:
/// * [userId] 
abstract class LogoutRequest implements Built<LogoutRequest, LogoutRequestBuilder> {
    @BuiltValueField(wireName: r'user_id')
    String? get userId;

    LogoutRequest._();

    @BuiltValueHook(initializeBuilder: true)
    static void _defaults(LogoutRequestBuilder b) => b;

    factory LogoutRequest([void updates(LogoutRequestBuilder b)]) = _$LogoutRequest;

    @BuiltValueSerializer(custom: true)
    static Serializer<LogoutRequest> get serializer => _$LogoutRequestSerializer();
}

class _$LogoutRequestSerializer implements StructuredSerializer<LogoutRequest> {
    @override
    final Iterable<Type> types = const [LogoutRequest, _$LogoutRequest];

    @override
    final String wireName = r'LogoutRequest';

    @override
    Iterable<Object?> serialize(Serializers serializers, LogoutRequest object,
        {FullType specifiedType = FullType.unspecified}) {
        final result = <Object?>[];
        if (object.userId != null) {
            result
                ..add(r'user_id')
                ..add(serializers.serialize(object.userId,
                    specifiedType: const FullType(String)));
        }
        return result;
    }

    @override
    LogoutRequest deserialize(Serializers serializers, Iterable<Object?> serialized,
        {FullType specifiedType = FullType.unspecified}) {
        final result = LogoutRequestBuilder();

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
            }
        }
        return result.build();
    }
}

