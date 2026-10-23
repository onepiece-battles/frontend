import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';

import '../../repository/character_dao.dart';
import '../../repository/fruit_dao.dart';
import '../../repository/image_dao.dart';

/// Data-access + business boundary for the character detail screen.
///
/// Fronts the character / fruit / image DAOs so the view no longer reaches into
/// the global service locator for server interaction. This gives the feature a
/// single, mockable seam (DAOs can be injected in tests) and decouples the
/// widget from the data layer.
///
/// NOTE: this is introduced incrementally. For now it owns data access only;
/// mutable screen state and ChangeNotifier-driven rebuilds are migrated here in
/// later refactor steps (see docs/refactor-bug-log.md and the refactor commits).
class CharacterDetailController extends ChangeNotifier {
  CharacterDetailController({
    CharacterDao? characterDao,
    FruitDao? fruitDao,
    ImageDao? imageDao,
  })  : _characterDao = characterDao ?? GetIt.instance<CharacterDao>(),
        _fruitDao = fruitDao ?? GetIt.instance<FruitDao>(),
        _imageDao = imageDao ?? GetIt.instance<ImageDao>();

  final CharacterDao _characterDao;
  final FruitDao _fruitDao;
  final ImageDao _imageDao;

  /// Load the full view of a character (with its battles, fruits and groups).
  Future<CharacterFullView?> getCharacter(GetCharacterFullViewRequest request) =>
      _characterDao.getCharacter(request);

  /// Have the character eat the given fruit.
  Future<EatFruitResponse?> eatFruit(EatFruitRequest request) =>
      _characterDao.eatFruit(request);

  /// Persist character changes (basic info and combat info share this call).
  Future<UpdateCharacterResponse?> updateCharacter(
          UpdateCharacterRequest request) =>
      _characterDao.update(request);

  /// Upload a new character avatar image.
  Future<UploadImageResponse?> uploadImage(UploadImageRequest request) =>
      _imageDao.addImage(request);

  /// Search fruits for the "eat fruit" picker.
  Future<ListFruitResponse?> listFruit(ListFruitRequest request) =>
      _fruitDao.list(request);
}
