import 'dart:convert';
import 'dart:typed_data';
class Base64Helper {

  static String encode(List<int> bytes) {
    return base64Encode(bytes);
  }

  static Uint8List decode(String source) {
    return base64Decode(source);
  }
}