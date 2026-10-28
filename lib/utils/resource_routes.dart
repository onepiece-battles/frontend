import 'package:go_router/go_router.dart';

/// Detail URLs carry the ID so reloads, copied links and browser history do
/// not depend on GoRouter's in-memory extra value.
class ResourceRoutes {
  static const detailNames = {
    'characterDetails',
    'fruitDetails',
    'groupDetails',
    'battleDetails',
    'userDetails',
    'issueDetails',
    'user_profile',
    'userSetting',
  };

  static String? id(GoRouterState state) {
    final query = state.uri.queryParameters['id'];
    if (query != null && query.trim().isNotEmpty) return query;
    if (state.extra is String && (state.extra as String).trim().isNotEmpty) {
      return state.extra as String;
    }
    final pathId = state.pathParameters['id'];
    if (pathId != null && pathId.isNotEmpty) return pathId;
    final name = state.pathParameters['name'];
    if (name != null &&
        RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
                caseSensitive: false)
            .hasMatch(name)) {
      return name;
    }
    return null;
  }

  static Uri canonicalUri(GoRouterState state) {
    if (!detailNames.contains(state.name ?? state.topRoute?.name)) {
      return state.uri;
    }
    final extra = state.extra;
    if (extra is! String || extra.trim().isEmpty) return state.uri;
    return state.uri.replace(queryParameters: {
      ...state.uri.queryParameters,
      'id': extra,
    });
  }

  static String loginLocation(Uri destination) => Uri(
        path: '/login',
        queryParameters: {'from': destination.toString()},
      ).toString();

  static String afterLogin(Uri loginUri) {
    final target = Uri.tryParse(loginUri.queryParameters['from'] ?? '');
    if (target != null &&
        !target.hasScheme &&
        !target.hasAuthority &&
        target.path.startsWith('/home/')) {
      return target.toString();
    }
    return '/home/assistant';
  }
}
