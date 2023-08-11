import 'dart:math';

class RandomStringGenerator{
  static String generateRandomString(int length) {
    var r = Random();
    return String.fromCharCodes(List.generate(length, (index) => r.nextInt(33) + 89));
  }
}