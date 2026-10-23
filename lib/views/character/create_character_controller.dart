import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';

import '../../repository/character_dao.dart';
import '../../repository/image_dao.dart';

/// Data-access boundary for the create-character screen: creating the character
/// and uploading its avatar. Fronts the DAOs so the view no longer reaches into
/// the global service locator for its writes.
class CreateCharacterController extends ChangeNotifier {
  CreateCharacterController({
    CharacterDao? characterDao,
    ImageDao? imageDao,
  })  : _characterDao = characterDao ?? GetIt.instance<CharacterDao>(),
        _imageDao = imageDao ?? GetIt.instance<ImageDao>();

  final CharacterDao _characterDao;
  final ImageDao _imageDao;

  Future<Character?> addCharacter(CreateCharacterRequest request) =>
      _characterDao.addCharacter(request);

  Future<UploadImageResponse?> uploadImage(UploadImageRequest request) =>
      _imageDao.addImage(request);
}
