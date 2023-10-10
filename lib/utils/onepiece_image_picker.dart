import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class OnepieceImagePicker {
  static Future<Uint8List?> pickWebImage() async {
    final imagePicker = ImagePicker();
    XFile? image = await imagePicker.pickImage(source: ImageSource.gallery);
    if (image!=null) {
      return image.readAsBytes();
    } else {
      print('no image is picked');
    }
  }
}