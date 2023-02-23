// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'i18n_text.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$I18nText extends I18nText {
  @override
  final String? enUS;
  @override
  final String? zhCN;

  factory _$I18nText([void Function(I18nTextBuilder)? updates]) =>
      (new I18nTextBuilder()..update(updates)).build();

  _$I18nText._({this.enUS, this.zhCN}) : super._();

  @override
  I18nText rebuild(void Function(I18nTextBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  I18nTextBuilder toBuilder() => new I18nTextBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is I18nText && enUS == other.enUS && zhCN == other.zhCN;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, enUS.hashCode), zhCN.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('I18nText')
          ..add('enUS', enUS)
          ..add('zhCN', zhCN))
        .toString();
  }
}

class I18nTextBuilder implements Builder<I18nText, I18nTextBuilder> {
  _$I18nText? _$v;

  String? _enUS;
  String? get enUS => _$this._enUS;
  set enUS(String? enUS) => _$this._enUS = enUS;

  String? _zhCN;
  String? get zhCN => _$this._zhCN;
  set zhCN(String? zhCN) => _$this._zhCN = zhCN;

  I18nTextBuilder() {
    I18nText._defaults(this);
  }

  I18nTextBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _enUS = $v.enUS;
      _zhCN = $v.zhCN;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(I18nText other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$I18nText;
  }

  @override
  void update(void Function(I18nTextBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$I18nText build() {
    final _$result = _$v ?? new _$I18nText._(enUS: enUS, zhCN: zhCN);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
