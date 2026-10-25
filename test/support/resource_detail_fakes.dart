import 'dart:convert';

import 'package:openapi/api.dart';
import 'resource_list_fakes.dart';

class DetailCharacterFake extends ListCharacterFake {
  @override
  Future<CharacterFullView?> getCharacter(
          GetCharacterFullViewRequest request) async =>
      CharacterFullView.fromJson(jsonDecode(jsonEncode(sampleCharacter(0))));
}

class DetailFruitFake extends ListFruitFake {
  @override
  Future<FruitFullView?> get(GetFruitRequest request) async {
    final response = await list(ListFruitRequest(pageSize: 24, pageIndex: 1));
    return FruitFullView.fromJson(
        jsonDecode(jsonEncode(response!.fruits.first)));
  }
}

class DetailGroupFake extends ListGroupFake {
  @override
  Future<GroupFullView?> getGroupFullView(GetGroupRequest request) async {
    final response =
        await listGroups(ListGroupRequest(pageSize: 24, pageIndex: 1));
    return GroupFullView.fromJson(
        jsonDecode(jsonEncode(response!.groups.first)));
  }
}

class DetailBattleFake extends ListBattleFake {
  @override
  Future<BattleFullView?> getBattleFullView(
      GetBattleFullViewRequest request) async {
    final response =
        await listBattles(ListBattleRequest(pageSize: 24, pageIndex: 1));
    final battle = BattleFullView.fromJson(
        jsonDecode(jsonEncode(response!.battles.first)))!;
    battle.battleExecution!.battleReportStage = BattleReportStage.WAITING;
    return battle;
  }

  @override
  Future<BattleExecution?> getBattleExecution(
          GetBattleExecutionRequest request) async =>
      BattleExecution(
          battleStatus: BattleStatus.CREATED,
          battleReportStage: BattleReportStage.WAITING);
}
