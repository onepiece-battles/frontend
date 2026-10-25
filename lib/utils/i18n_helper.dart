import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';

GetIt getIt = GetIt.instance;

class I18nHelper {
  final Map<Character, I18nText> characterTypeMap = HashMap();

  static String getDisplayNameFromI18nByLocale(
      I18nText? i18nText, Locale locale) {
    if (i18nText == null) return '';
    final primary = locale.languageCode == 'en' ? i18nText.enUS : i18nText.zhCN;
    final fallback =
        locale.languageCode == 'en' ? i18nText.zhCN : i18nText.enUS;
    return primary == null || primary.trim().isEmpty ? fallback ?? '' : primary;
  }

  static String getDisplayNameFromI18n(I18nText? i18nText) =>
      getDisplayNameFromI18nByLocale(i18nText, getIt<Locale>());

  /// Editing must use the selected language's own value, never its fallback.
  static String getEditableNameFromI18n(I18nText? text, Locale locale) =>
      (locale.languageCode == 'en' ? text?.enUS : text?.zhCN) ?? '';

  static I18nText getI18nFromDisplayName(
      I18nText i18nText, String displayName) {
    var locale = getIt<Locale>();
    if (locale.languageCode == 'en') {
      i18nText.enUS = displayName;
    } else {
      i18nText.zhCN = displayName;
    }
    return i18nText;
  }

  static OnepieceLocale convertToOnepieceLocale(Locale locale) {
    if (locale.languageCode == 'en') {
      return OnepieceLocale.enUS;
    }
    return OnepieceLocale.zhCN;
  }

  static LanguageCode getLanguageCode() {
    var locale = getIt<Locale>();
    if (locale.languageCode == "en") {
      return LanguageCode.enUS;
    } else {
      return LanguageCode.zhCN;
    }
  }
}
//--dart-define=http_proxy=http://127.0.0.1:59527 --dart-define=https_proxy=https://127.0.0.1:59527
