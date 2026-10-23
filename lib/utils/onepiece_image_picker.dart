import 'package:image_picker/image_picker.dart';

class OnepieceImagePicker {
  static Future<XFile?> pickWebImage() {
    return ImagePicker().pickImage(source: ImageSource.gallery);
  }
}
