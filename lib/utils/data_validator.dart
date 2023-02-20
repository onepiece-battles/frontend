class DataValidator {
  static bool isInt(String inputString) {
    if (inputString.isEmpty) {
      return false;
    }
    return int.tryParse(inputString) == null ? false : true;
  }
}
