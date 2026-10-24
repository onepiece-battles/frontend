import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';

import '../../repository/fruit_dao.dart';

/// Data-access boundary for the create-fruit screen.
///
/// Fronts [FruitDao] so the view no longer reaches into the global service
/// locator for server interaction, giving the feature a single, mockable seam.
class CreateFruitController extends ChangeNotifier {
  CreateFruitController({FruitDao? fruitDao})
      : _fruitDao = fruitDao ?? GetIt.instance<FruitDao>();

  final FruitDao _fruitDao;

  /// Create a new fruit.
  Future<Fruit?> add(CreateFruitRequest request) => _fruitDao.add(request);
}
