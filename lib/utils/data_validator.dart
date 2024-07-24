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
    if (name.trim().contains(RegExp(r"[^a-zA-Z|\d\u4e00-\u9fa5\s-·.]"))) {
      return false;
    }
    return true;
  }
}
