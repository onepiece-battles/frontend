import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';

import '../../repository/fruit_dao.dart';

/// Data-access boundary for the devil-fruit detail screen.
///
/// Fronts [FruitDao] so the view no longer reaches into the global service
/// locator for server interaction, giving the feature a single, mockable seam.
class FruitDetailController extends ChangeNotifier {
  FruitDetailController({FruitDao? fruitDao})
      : _fruitDao = fruitDao ?? GetIt.instance<FruitDao>();

  final FruitDao _fruitDao;

  /// Load the full view of a fruit (with its characters and coefficients).
  Future<FruitFullView?> get(GetFruitRequest request) => _fruitDao.get(request);

  /// Persist fruit changes (basic info and combat info share this call).
  Future<UpdateFruitResponse?> update(UpdateFruitRequest request) =>
      _fruitDao.update(request);
}
