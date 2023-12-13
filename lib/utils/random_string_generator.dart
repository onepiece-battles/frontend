import 'dart:math';

class RandomStringGenerator{
  static String generateRandomString(int length) {
    var r = Random();
    return String.fromCharCodes(List.generate(length, (index) => r.nextInt(33) + 89));
  }

  static String generateRandomName(int length) {
    final random = Random();
    const availableChars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    final randomString = List.generate(length,
            (index) => availableChars[random.nextInt(availableChars.length)]).join();
    return randomString;
  }

  static String generateRandomNumber(int min, int max) {
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