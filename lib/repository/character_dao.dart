import 'package:openapi/api.dart';

class CharacterDao {
  CharacterApi characterApi = CharacterApi();
  CharacterDao(ApiClient apiClient) {
    characterApi = CharacterApi(apiClient);
  }
  CharacterDao.empty();

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

  Future<CharacterFullView?> getCharacter(GetCharacterFullViewRequest request) async {
    return await characterApi.getCharacterFullView(request);
  }
}
