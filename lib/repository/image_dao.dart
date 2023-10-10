import 'package:openapi/api.dart';
import 'package:http/http.dart';
class ImageDao {
  ImageApi imageApi  = ImageApi();
  ImageDao(ApiClient apiClient) {
    imageApi = ImageApi(apiClient);
  }
  ImageDao.empty();

  Future<MultipartFile?> addImage(String id, ResourceType resourceType, MultipartFile multipartFile) {
    return imageApi.addImage(id:id, type:resourceType, image: multipartFile);
  }
}