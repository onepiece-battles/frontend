import 'package:flutter/cupertino.dart';

import '../utils/image_helper.dart';

class ImageCacheManager {

  static Map<String, String> uriToImageMap = {};

  static Future<String> getImage(String uri) async {
    if (uriToImageMap[uri]==null) {
      String image = await ImageHelper.loadImageByUri(uri);
      uriToImageMap[uri] = image;
      return image;
    }
    return uriToImageMap[uri]!;
  }
}
