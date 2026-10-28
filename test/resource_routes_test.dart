import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/utils/resource_routes.dart';

void main() {
  for (final entry in {
    'characterDetails': '/home/character/:name',
    'fruitDetails': '/home/fruit/:name',
    'groupDetails': '/home/group/:name',
    'battleDetails': '/home/battle/:id',
    'issueDetails': '/home/issue/:id',
    'userDetails': '/home/user/:name',
    'user_profile': '/home/:name/profile',
  }.entries) {
    testWidgets('${entry.key} stores IDs in reloadable URLs', (tester) async {
      final route = GoRoute(
          path: entry.value,
          name: entry.key,
          builder: (_, state) => Text('resource:${ResourceRoutes.id(state)}'));
      GoRouter router(String initial) => GoRouter(
            initialLocation: initial,
            routes: [
              GoRoute(path: '/', builder: (_, __) => const SizedBox()),
              route
            ],
            redirect: (_, state) {
              final canonical = ResourceRoutes.canonicalUri(state);
              return canonical == state.uri ? null : canonical.toString();
            },
          );
      final live = router('/');
      final pathKey = entry.value.endsWith(':id') ? 'id' : 'name';
      await tester.pumpWidget(MaterialApp.router(routerConfig: live));
      live.goNamed(entry.key,
          pathParameters: {pathKey: 'label'},
          extra: 'real-id',
          queryParameters: {'tab': 'history'});
      await tester.pumpAndSettle();
      final uri = live.routeInformationProvider.value.uri;
      expect(uri.queryParameters['id'], 'real-id');
      expect(uri.queryParameters['tab'], 'history');
      expect(find.text('resource:real-id'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      live.dispose();

      // A newly created router has no extra value, just like a copied link.
      final restored = router(uri.toString());
      await tester.pumpWidget(MaterialApp.router(routerConfig: restored));
      await tester.pumpAndSettle();
      expect(find.text('resource:real-id'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      restored.dispose();
    });
  }

  testWidgets('battle ID is read from its path without extra', (tester) async {
    final router = GoRouter(initialLocation: '/battle/battle-id', routes: [
      GoRoute(
          path: '/battle/:id',
          builder: (_, state) => Text(ResourceRoutes.id(state) ?? 'missing')),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.text('battle-id'), findsOneWidget);
  });

  test('login preserves resource destination and rejects external redirects',
      () {
    final resource = Uri.parse('/home/character/Luffy?id=ace&tab=battles');
    expect(
        ResourceRoutes.afterLogin(
            Uri.parse(ResourceRoutes.loginLocation(resource))),
        resource.toString());
    expect(
        ResourceRoutes.afterLogin(
            Uri.parse('/login?from=https://example.com/home/a')),
        '/home/assistant');
    expect(ResourceRoutes.afterLogin(Uri.parse('/login')), '/home/assistant');
  });
}
