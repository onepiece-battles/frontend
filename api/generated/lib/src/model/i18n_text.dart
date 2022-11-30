//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'i18n_text.g.dart';

/// I18nText
///
/// Properties:
/// * [enUS] 
/// * [zhCN] 
abstract class I18nText implements Built<I18nText, I18nTextBuilder> {
    @BuiltValueField(wireName: r'en-US')
    String? get enUS;

    @BuiltValueField(wireName: r'zh-CN')
    String? get zhCN;

    I18nText._();

    @BuiltValueHook(initializeBuilder: true)
    static void _defaults(I18nTextBuilder b) => b;

    factory I18nText([void updates(I18nTextBuilder b)]) = _$I18nText;

    @BuiltValueSerializer(custom: true)
    static Serializer<I18nText> get serializer => _$I18nTextSerializer();
}

class _$I18nTextSerializer implements StructuredSerializer<I18nText> {
    @override
    final Iterable<Type> types = const [I18nText, _$I18nText];

    @override
    final String wireName = r'I18nText';

    @override
    Iterable<Object?> serialize(Serializers serializers, I18nText object,
        {FullType specifiedType = FullType.unspecified}) {
        final result = <Object?>[];
        if (object.enUS != null) {
            result
                ..add(r'en-US')
                ..add(serializers.serialize(object.enUS,
                    specifiedType: const FullType(String)));
        }
        if (object.zhCN != null) {
            result
                ..add(r'zh-CN')
                ..add(serializers.serialize(object.zhCN,
                    specifiedType: const FullType(String)));
        }
        return result;
    }

    @override
    I18nText deserialize(Serializers serializers, Iterable<Object?> serialized,
        {FullType specifiedType = FullType.unspecified}) {
        final result = I18nTextBuilder();

        final iterator = serialized.iterator;
        while (iterator.moveNext()) {
            final key = iterator.current as String;
            iterator.moveNext();
            final Object? value = iterator.current;
            
            switch (key) {
                case r'en-US':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(String)) as String;
                    result.enUS = valueDes;
                    break;
                case r'zh-CN':
                    final valueDes = serializers.deserialize(value,
                        specifiedType: const FullType(String)) as String;
                    result.zhCN = valueDes;
                    break;
            }
        }
        return result.build();
    }
}

