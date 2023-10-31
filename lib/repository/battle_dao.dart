import 'package:openapi/api.dart';

class BattleDao{
  BattleApi battleApi = BattleApi();
  BattleDao.empty();

  BattleDao(ApiClient apiClient) {
    battleApi = BattleApi(apiClient);
  }

  Future<ListBattleByIdResponse?> batchFindByIds(ListBattleByIdsRequest request) async {
    return await battleApi.listBattleByIds(request);
  }
}