import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class OnepieceImagePicker {
  static Future<XFile?> pickWebImage() async {
    final imagePicker = ImagePicker();
    XFile? image = await imagePicker.pickImage(source: ImageSource.gallery);
    if (image!=null) {
      print('new image is picked');
      return image;
    } else {
      print('no image is picked');
    }
  }
}