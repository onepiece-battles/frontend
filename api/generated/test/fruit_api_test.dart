import 'package:test/test.dart';
import 'package:openapi/openapi.dart';


/// tests for FruitApi
void main() {
  final instance = Openapi().getFruitApi();

  group(FruitApi, () {
    //Future<Fruit> addFruit(AddFruitRequest addFruitRequest) async
    test('test addFruit', () async {
      // TODO
    });

    //Future<ListFruitResponse> listFruit(ListFruitRequest listFruitRequest) async
    test('test listFruit', () async {
      // TODO
    });

    //Future<Fruit> updateFruit(UpdateFruitRequest updateFruitRequest) async
    test('test updateFruit', () async {
      // TODO
    });

  });
}
