import 'package:openapi/api.dart';

class FruitDao {
  FruitApi fruitApi = FruitApi();
  FruitDao.empty();

  FruitDao(ApiClient apiClient) {
    fruitApi = FruitApi(apiClient);
  }

  Future<ListFruitResponse?> list(ListFruitRequest request) async {
    return await fruitApi.listFruit(request);
  }

  Future<Fruit?> add(AddFruitRequest request) async {
    return await fruitApi.addFruit(request);
  }

  Future<Fruit?> update(UpdateFruitRequest request) async {
    return await fruitApi.updateFruit(request);
  }
}