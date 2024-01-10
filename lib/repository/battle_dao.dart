import 'package:openapi/api.dart';

class BattleDao{
  BattleApi battleApi = BattleApi();
  BattleDao.empty();

  BattleDao(ApiClient apiClient) {
    battleApi = BattleApi(apiClient);
  }

  Future<ListBattleByIdsResponse?> batchFindByIds(ListBattleByIdsRequest request) async {
    return await battleApi.listBattleByIds(request);
  }

  Future<ListBattleResponse?> listBattles(ListBattleRequest request) async {
    return await battleApi.listBattles(request);
  }

  Future<Battle?> addBattle(AddBattleRequest request) async {
    return await battleApi.addBattle(request);
  }

  Future<StartBattleResponse?> startBattle(StartBattleRequest request) async {
    return await battleApi.startBattle(request);
  }

  Future<BattleFullView?> getBattleFullView(GetBattleFullViewRequest request)async {
    return await battleApi.getBattleFullView(request);
  }

  Future<BattleExecution?> getBattleExecution(GetBattleExecutionRequest request) async {
    return await battleApi.getBattleExecution(request);
  }
}