import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';

import '../../repository/character_dao.dart';

/// Data-access boundary for the character list / roster screen.
///
/// Fronts [CharacterDao] so the view no longer reaches into the global service
/// locator for its queries, giving the feature a single, mockable data seam.
class CharacterListController extends ChangeNotifier {
  CharacterListController({CharacterDao? characterDao})
      : _characterDao = characterDao ?? GetIt.instance<CharacterDao>();

  final CharacterDao _characterDao;

  /// List characters matching the given filter / paging / sort request.
  Future<ListCharacterResponse?> listCharacter(ListCharacterRequest request) =>
      _characterDao.listCharacter(request);
}
