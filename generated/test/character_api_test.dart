import 'package:test/test.dart';
import 'package:openapi/openapi.dart';


/// tests for CharacterApi
void main() {
  final instance = Openapi().getCharacterApi();

  group(CharacterApi, () {
    //Future<Character> addCharacter(AddCharacterRequest addCharacterRequest) async
    test('test addCharacter', () async {
      // TODO
    });

    //Future<EatFruitResponse> eatFruit(EatFruitRequest eatFruitRequest) async
    test('test eatFruit', () async {
      // TODO
    });

    //Future<Uint8List> getProfile(String id) async
    test('test getProfile', () async {
      // TODO
    });

    //Future<ListCharacterResponse> listCharacters(ListCharacterRequest listCharacterRequest) async
    test('test listCharacters', () async {
      // TODO
    });

    //Future<Uint8List> updateProfile({ String characterId, MultipartFile profileImage }) async
    test('test updateProfile', () async {
      // TODO
    });

  });
}
