import 'package:one_piece_battles_flutter/utils/api_client_helper.dart';
import 'package:openapi/api.dart';

class CharacterRepository {
  final CharacterApi characterApi =
      CharacterApi(ApiClientHelper.getApiClient());

  Future<ListCharacterResponse?> listCharacter(
      ListCharacterRequest listCharacterRequest) async {
    return await characterApi.listCharacters(listCharacterRequest);
  }

  Future<Character?> addCharacter(
      AddCharacterRequest addCharacterRequest) async {
    return await characterApi.addCharacter(addCharacterRequest);
  }

  Future<EatFruitResponse?> eatFruit(EatFruitRequest eatFruitRequest) async {
    return await characterApi.eatFruit(eatFruitRequest);
  }
}
