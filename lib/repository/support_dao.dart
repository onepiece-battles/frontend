import 'package:openapi/api.dart';

class SupportDao {
  SupportApi supportApi = SupportApi();

  SupportDao(ApiClient apiClient) {
    supportApi = SupportApi(apiClient);
  }

  SupportDao.empty();

  Future<UpdateUriResponse?> updateUri(UpdateUriRequest request) async {
    return await supportApi.updateUri(request);
  }

  Future<BatchCreateFruitResponse?> batchCreateFruit(
      BatchCreateFruitRequest request) async {
    return await supportApi.batchCreateFruit(request);
  }

  Future<void> updateCharacterBasic() async {
    return await supportApi.updateCharacterBasic();
  }
}
