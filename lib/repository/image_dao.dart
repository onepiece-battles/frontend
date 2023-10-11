import 'package:openapi/api.dart';

class ImageDao {
  ImageApi imageApi  = ImageApi();
  ImageDao(ApiClient apiClient) {
    imageApi = ImageApi(apiClient);
  }
  ImageDao.empty();

  Future<UploadImageResponse?> addImage(UploadImageRequest uploadImageRequest) {
    return imageApi.uploadImage(uploadImageRequest);
  }
}