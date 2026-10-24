import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';

import '../../repository/fruit_dao.dart';

/// Data-access boundary for the devil-fruit list screen.
///
/// Fronts [FruitDao] so the view no longer reaches into the global service
/// locator for its queries, giving the feature a single, mockable data seam.
class FruitListController extends ChangeNotifier {
  FruitListController({FruitDao? fruitDao})
      : _fruitDao = fruitDao ?? GetIt.instance<FruitDao>();

  final FruitDao _fruitDao;

  /// List fruits matching the given filter / paging / sort request.
  Future<ListFruitResponse?> list(ListFruitRequest request) =>
      _fruitDao.list(request);
}
