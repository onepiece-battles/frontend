import 'package:openapi/api.dart';
import 'package:http/http.dart';

class FileDao{
  FileApi fileApi= FileApi();
  FileDao.empty();

  FileDao(ApiClient apiClient) {
    fileApi = FileApi(apiClient);
  }

  Future<MultipartFile?> downloadFile(DownloadFileRequest request) async {
    return await fileApi.downloadFile(request);
  }
}