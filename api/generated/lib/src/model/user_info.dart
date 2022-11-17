//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'user_info.g.dart';

/// UserInfo
///
/// Properties:
/// * [userId] 
/// * [userName] 
/// * [organization] 
abstract class UserInfo implements Built<UserInfo, UserInfoBuilder> {
    @BuiltValueField(wireName: r'user_id')
    String get userId;

    @BuiltValueField(wireName: r'user_name')
    String get userName;

    @BuiltValueField(wireName: r'organization')
    String? get organization;

    UserInfo._();

    @BuiltValueHook(initializeBuilder: true)
    static void _defaults(UserInfoBuilder b) => b;

    factory UserInfo([void updates(UserInfoBuilder b)]) = _$UserInfo;

    @BuiltValueSerializer(custom: true)
    static Serializer<UserInfo> get serializer => _$UserInfoSerializer();
}

class _$UserInfoSerializer implements StructuredSerializer<UserInfo> {
    @override
    final Iterable<Type> types = const [UserInfo, _$UserInfo];

    @override
    final String wireName = r'UserInfo';

    @override
    Iterable<Object?> serialize(Serializers serializers, UserInfo object,
        {FullType specifiedType = FullType.unspecified}) {
        final result = <Object?>[];
        result
            ..add(r'user_id')
            ..add(serializers.serialize(object.userId,
                specifiedType: const FullType(String)));
        result
            ..add(r'user_name')
            ..add(serializers.serialize(object.userName,
                specifiedType: const FullType(String)));
        if (object.organization != null) {
            result
                ..add(r'organization')
                ..add(serializers.serialize(object.organization,
                    specifiedType: const FullType(String)));
        }
        return result;
    }

    @override
    UserInfo deserialize(Serializers serializers, Iterable<Object?> serialized,
        {FullType specifiedType = FullType.unspecified}) {
        final result = UserInfoBuilder();

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
                case r'user_name':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(String)) as String;
                    result.userName = valueDes;
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

