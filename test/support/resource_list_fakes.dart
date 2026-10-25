import 'package:openapi/api.dart';
import 'package:one_piece_battles_flutter/repository/character_dao.dart';
import 'package:one_piece_battles_flutter/repository/fruit_dao.dart';
import 'package:one_piece_battles_flutter/repository/group_dao.dart';
import 'package:one_piece_battles_flutter/repository/battle_dao.dart';

CharacterListView sampleCharacter(int index) => CharacterListView(
      id: '$index',
      name: I18nText(zhCN: '蒙奇·D·路飞 $index', enUS: 'Monkey D. Luffy $index'),
      maximumFruitCount: 1,
      score: 9000,
      baseGroupGain: 100,
      baseAttack: 1000,
      baseDefense: 800,
      baseIntelligence: 120,
      baseBlood: 8000,
      baseSpeed: 150,
      attack: 1000,
      defense: 800,
      intelligence: 120,
      blood: 8000,
      speed: 150,
      groupGain: 100,
      energy: 200,
      battleStyle: BattleStyle.BODY,
      race: Race.HUMAN,
      imageUri: '',
      bounty: 3000000000,
      hakis: [Haki.busoshoku, Haki.kenbunshoku],
    );

class ListCharacterFake extends CharacterDao {
  ListCharacterFake() : super.empty();
  int? pageSize;
  @override
  Future<ListCharacterResponse?> listCharacter(
      ListCharacterRequest request) async {
    pageSize = request.pageSize;
    return ListCharacterResponse(
        totalSize: 96, characters: List.generate(24, sampleCharacter));
  }
}

class ListFruitFake extends FruitDao {
  ListFruitFake() : super.empty();
  int? pageSize;
  @override
  Future<ListFruitResponse?> list(ListFruitRequest request) async {
    pageSize = request.pageSize;
    return ListFruitResponse(
        totalSize: 96,
        fruits: List.generate(
            24,
            (index) => FruitListView(
                  id: '$index',
                  name: I18nText(
                      zhCN: '橡胶果实 $index', enUS: 'Gum-Gum Fruit $index'),
                  fruitType: FruitType.paramecia,
                  energyConsume: 5,
                  attackSlope: 1,
                  attackIntercept: 10,
                  defenseSlope: 1,
                  defenseIntercept: 20,
                  bloodSlope: 1,
                  bloodIntercept: 30,
                  intelligenceSlope: 1,
                  intelligenceIntercept: 40,
                  speedSlope: 1,
                  speedIntercept: 50,
                  groupGainSlope: 1,
                  groupGainIntercept: 60,
                )));
  }
}

class ListGroupFake extends GroupDao {
  ListGroupFake() : super.empty();
  int? pageSize;
  String? userId;
  @override
  Future<ListGroupResponse?> listGroups(ListGroupRequest request) async {
    pageSize = request.pageSize;
    userId = request.groupFilter?.userId;
    return ListGroupResponse(
        totalSize: 96,
        groups: List.generate(
            24,
            (index) => GroupListView(
                  id: '$index',
                  name: I18nText(
                      zhCN: '草帽海贼团 $index', enUS: 'Straw Hat Pirates $index'),
                  imageUri: '',
                  groupCategory: GroupCategory.pirate,
                )));
  }
}

class ListBattleFake extends BattleDao {
  ListBattleFake() : super.empty();
  int? pageSize;
  @override
  Future<ListBattleResponse?> listBattles(ListBattleRequest request) async {
    pageSize = request.pageSize;
    return ListBattleResponse(
        totalSize: 96,
        battles: List.generate(
            24,
            (index) => BattleListView(
                  id: '$index',
                  starterId: '0',
                  receiverId: '1',
                  type: BattleType.values.first,
                  creationRecordId: 1,
                  modificationRecordId: 1,
                  starter: Character(
                      id: '0',
                      name: I18nText(zhCN: '路飞与索隆', enUS: 'Luffy and Zoro'),
                      maximumFruitCount: 1,
                      score: 9000,
                      baseGroupGain: 100,
                      baseAttack: 1000,
                      baseDefense: 800,
                      baseIntelligence: 120,
                      baseBlood: 8000,
                      baseSpeed: 150,
                      attack: 1000,
                      defense: 800,
                      intelligence: 120,
                      blood: 8000,
                      speed: 150,
                      groupGain: 100,
                      energy: 200,
                      battleStyle: BattleStyle.BODY,
                      race: Race.HUMAN,
                      imageUri: ''),
                  receiver: Character(
                      id: '1',
                      name: I18nText(zhCN: '路飞与索隆', enUS: 'Luffy and Zoro'),
                      maximumFruitCount: 1,
                      score: 9000,
                      baseGroupGain: 100,
                      baseAttack: 1000,
                      baseDefense: 800,
                      baseIntelligence: 120,
                      baseBlood: 8000,
                      baseSpeed: 150,
                      attack: 1000,
                      defense: 800,
                      intelligence: 120,
                      blood: 8000,
                      speed: 150,
                      groupGain: 100,
                      energy: 200,
                      battleStyle: BattleStyle.BODY,
                      race: Race.HUMAN,
                      imageUri: ''),
                  battleExecution: BattleExecution(
                      battleStatus: BattleStatus.CREATED,
                      starterScoreBefore: 9000,
                      receiverScoreBefore: 8500),
                )));
  }
}
