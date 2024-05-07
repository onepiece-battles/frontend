import 'dart:math';

import 'package:openapi/api.dart';

class RandomStringGenerator{
  static String generateRandomString(int length, bool isNika) {
    if (!isNika) {
      return "";
    }
    var r = Random();
    return String.fromCharCodes(List.generate(length, (index) => r.nextInt(33) + 89));
  }

  static String generateRandomName(int length, bool isNika) {
    if (!isNika) {
      return "";
    }
    final random = Random();
    const availableChars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    final randomString = List.generate(length,
            (index) => availableChars[random.nextInt(availableChars.length)]).join();
    return randomString;
  }

  static String generateRandomChineseName(int length, bool isNika) {
    if (!isNika) {
      return "";
    }
    final random = Random();
    const availableChars =
        '发货就撒开返回克拉夫等级考试垃圾大量贷记卡浪费了开始了的激昂奋进斯拉夫看我发了';
    final randomString = List.generate(length,
            (index) => availableChars[random.nextInt(availableChars.length)]).join();
    return randomString;
  }

  static I18nText generateI18n(String enString, String cnString) {
    return I18nText(enUS: enString, zhCN: cnString);
  }

  static String generateRandomNumber(int min, int max, bool isNika) {
      if (!isNika) {
        return "";
      }
      return (min + Random().nextInt(max - min)).toString();
  }

  static String generateDateString() {
    final random = Random();
    var startDate = DateTime(1000);
    var endDate = DateTime(1600);
    var diffDays = endDate.difference(startDate).inDays;
    var randomDays = random.nextInt(diffDays);
    var randomDate = startDate.add(Duration(days: randomDays));
    return "${randomDate.month}/${randomDate.day}";
  }
}