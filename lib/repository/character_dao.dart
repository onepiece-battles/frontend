import 'package:flutter/widgets.dart';
import 'package:one_piece_battles_flutter/authentication_holder.dart';
import 'package:openapi/api.dart';

class CharacterRepository {
  ApiClient apiClient = ApiClient();
  CharacterApi characterApi = CharacterApi();

  Future<ListCharacterResponse?> listCharacter(
      ListCharacterRequest listCharacterRequest) async {
    return await characterApi.listCharacters(listCharacterRequest);
  }

  Future<Character?> addCharacter(
      AddCharacterRequest addCharacterRequest) async {
    var authentication = AuthenticationHolder.getAuthentication();
    var accessToken = authentication.accessToken;
    debugPrint('access token in character api: $accessToken');
    characterApi = CharacterApi(ApiClient(authentication: AuthenticationHolder.getAuthentication()));
    return await characterApi.addCharacter(addCharacterRequest);
  }

  Future<EatFruitResponse?> eatFruit(EatFruitRequest eatFruitRequest) async {
    return await characterApi.eatFruit(eatFruitRequest);
  }
}
