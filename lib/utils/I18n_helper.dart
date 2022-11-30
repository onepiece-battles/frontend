import 'package:flutter/material.dart';
import 'package:openapi/openapi.dart';

class I18nHelper {
  static String getI18nByLocale(I18nText? i18nText, Locale locale) {
    if (i18nText == null) {
      return "";
    }
    if (locale.languageCode == 'en') {
      return i18nText.enUS ?? "";
    } else {
      return i18nText.zhCN ?? "";
    }
  }
}
