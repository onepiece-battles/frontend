import 'package:flutter/cupertino.dart';
import 'package:openapi/api.dart';

class FileDao {
  FileApi fileApi = FileApi();

  FileDao.empty();

  FileDao(ApiClient apiClient) {
    fileApi = FileApi(apiClient);
  }

  Future<DownloadFileResponse?> downloadFile(
      DownloadFileRequest request) async {
    debugPrint('start downloading pdf');
    return await fileApi.downloadFile(request);
  }
}
