import 'dart:typed_data';
import '../utils/base64_helper.dart';
import '../utils/image_helper.dart';

class ImageCacheManager {
  static Map<String, Uint8List> uriToImageMap = {};

  static Future<Uint8List> getImage(String uri) async {
    if (uriToImageMap[uri] == null) {
      String image = await ImageHelper.loadImageByUri(uri);
      Uint8List decodedImage = Base64Helper.decode(image);
      uriToImageMap[uri] = decodedImage;
      return decodedImage;
    }
    return uriToImageMap[uri]!;
  }
}
