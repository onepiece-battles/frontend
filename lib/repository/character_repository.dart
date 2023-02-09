import 'package:flutter/foundation.dart';
import 'package:openapi/openapi.dart';
import 'package:dio/dio.dart';

class CharacterRepository {
  final CharacterApi characterApi = Openapi().getCharacterApi();

  Future<ListCharacterResponse> listCharacter(
      ListCharacterRequest listCharacterRequest) async {
    Response<ListCharacterResponse> response = await characterApi
        .listCharacters(listCharacterRequest: listCharacterRequest);
    return response.data!;
  }

  Future<Character> addCharacter(
      AddCharacterRequest addCharacterRequest) async {
    Response<Character> character = await characterApi.addCharacter(
        addCharacterRequest: addCharacterRequest);
    return character.data!;
  }

  Future<EatFruitResponse> eatFruit(EatFruitRequest eatFruitRequest) async {
    Response<EatFruitResponse> eatFruitResponse =
        await characterApi.eatFruit(eatFruitRequest: eatFruitRequest);
    return eatFruitResponse.data!;
  }

  Future<Uint8List> getProfile(String id) async {
    Response<Uint8List> profile = await characterApi.getProfile(id: id);
    return profile.data!;
  }

  Future<Uint8List> updateProfile(
      String characterId, MultipartFile profileImage) async {
    Response<Uint8List> profile = await characterApi.updateProfile(
        characterId: characterId, profileImage: profileImage);
    return profile.data!;
  }
}
