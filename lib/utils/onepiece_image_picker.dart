import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

class OnepieceImagePicker {
  static Future<XFile?> pickWebImage() async {
    final imagePicker = ImagePicker();
    XFile? image = await imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      debugPrint('new image is picked');
      return image;
    } else {
      debugPrint('no image is picked');
    }
    return null;
  }
}
