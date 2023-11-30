class DataValidator {
  static bool isInt(String inputString) {
    if (inputString.isEmpty) {
      return false;
    }
    return int.tryParse(inputString) == null ? false : true;
  }

  static bool validName(String name) {
    if(name.isEmpty) {
      return true;
    }
    // not case sensitive
    if (name.trim().contains(RegExp(r"[^a-zA-Z|\d\u4e00-\u9fa5]"))) {
      return false;
    }
    return true;
  }

  static bool isUuid(String uuid) {
    RegExp uuidMatcher = RegExp(r'^#?([\da-fA-F]{3}|[\da-fA-F]{6})$');
    return uuidMatcher.hasMatch(uuid);
  }
}
