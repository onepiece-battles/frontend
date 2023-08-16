import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:openapi/api.dart';

class I18nHelper {
  final Map<Character, I18nText> characterTypeMap = HashMap();
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
//--dart-define=http_proxy=http://127.0.0.1:59527 --dart-define=https_proxy=https://127.0.0.1:59527
