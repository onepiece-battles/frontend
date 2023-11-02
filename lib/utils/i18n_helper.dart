import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';
GetIt getIt = GetIt.instance;
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

  static String getI18nByLocale2(I18nText? i18nText) {
    var locale = getIt<Locale>();
    if (i18nText == null) {
      return "";
    }
    if (locale.languageCode == 'en') {
      return i18nText.enUS ?? "";
    } else {
      return i18nText.zhCN ?? "";
    }
  }

  static OnepieceLocale convertToOnepieceLocale(Locale locale) {
    if (locale.toString() == const Locale('en', 'US').toString()) {
      return OnepieceLocale.enUS;
    }
    return OnepieceLocale.zhCN;
  }

}
//--dart-define=http_proxy=http://127.0.0.1:59527 --dart-define=https_proxy=https://127.0.0.1:59527
