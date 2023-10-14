import 'dart:typed_data';

class CompareUint8List {
  static bool equals(Uint8List list1, Uint8List list2) {
    if (identical(list1, list2)) {
      return true;
    }

    if (list1.lengthInBytes != list2.lengthInBytes) {
      return false;
    }

    // Treat the original byte lists as lists of 8-byte words.
    var numWords = list1.lengthInBytes ~/ 8;
    var words1 = list1.buffer.asUint8List(0, numWords);
    var words2 = list2.buffer.asUint8List(0, numWords);

    for (var i = 0; i < words1.length; i += 1) {
      if (words1[i] != words2[i]) {
        return false;
      }
    }

    // Compare any remaining bytes.
    for (var i = words1.lengthInBytes; i < list1.lengthInBytes; i += 1) {
      if (list1[i] != list2[i]) {
        return false;
      }
    }

    return true;
  }
}