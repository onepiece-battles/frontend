import 'package:test/test.dart';
import 'package:openapi/openapi.dart';


/// tests for BattleApi
void main() {
  final instance = Openapi().getBattleApi();

  group(BattleApi, () {
    //Future<Battle> addBattle(AddBattleRequest addBattleRequest) async
    test('test addBattle', () async {
      // TODO
    });

    //Future<StartBattleResponse> startBattle(StartBattleRequest startBattleRequest) async
    test('test startBattle', () async {
      // TODO
    });

  });
}
