import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/components/battle_view.dart';
import 'package:one_piece_battles_flutter/components/character_view.dart';
import 'package:one_piece_battles_flutter/components/fruit_view.dart';
import 'package:one_piece_battles_flutter/components/settings_view.dart';
import 'package:one_piece_battles_flutter/components/user_view.dart';
import 'package:one_piece_battles_flutter/register_page.dart';
import 'package:one_piece_battles_flutter/login_page.dart';
import 'package:one_piece_battles_flutter/responsive/desktop_scaffold.dart';
import 'package:openapi/api.dart';

GetIt getIt = GetIt.instance;

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorState =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> _homeNavigatorState =
      GlobalKey<NavigatorState>();
  // main paths
  static const loginPath = '/login';
  static const homePath = '/home/character';
  static const registerPath = '/register';

  // sub-paths
  static const characterPath = '/home/character';
  static const fruitPath = '/home/fruit';
  static const battlePath = '/home/battle';
  static const userPath = '/home/user';
  static const settingPath = '/home/setting';

  static final router = GoRouter(
    navigatorKey: _rootNavigatorState,
    initialLocation: loginPath,
    routes: [
      ShellRoute(
          navigatorKey: _homeNavigatorState,
          pageBuilder: (context, state, child) {
            return NoTransitionPage(
              child: DesktopScaffold(
                mainScreen: child,
              ),
            );
          },
          routes: [
            GoRoute(
              path: characterPath,
              parentNavigatorKey: _homeNavigatorState,
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: CharacterView());
              },
            ),
            GoRoute(
              path: fruitPath,
              parentNavigatorKey: _homeNavigatorState,
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: FruitView());
              },
            ),
            GoRoute(
              path: battlePath,
              parentNavigatorKey: _homeNavigatorState,
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: BattleView());
              },
            ),
            GoRoute(
              path: userPath,
              parentNavigatorKey: _homeNavigatorState,
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: UserView());
              },
            ),
            GoRoute(
              path: settingPath,
              parentNavigatorKey: _homeNavigatorState,
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: SettingsView());
              },
            ),
          ]),
      GoRoute(
        path: loginPath,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
          path: registerPath,
          builder: (context, state) => const RegisterPage()),
    ],
    redirect: (context, state) {
      // if the user is not logged in, they need to login
      final loggedIn = getIt<User>().name != '';
      final loggingIn = state.matchedLocation == AppRouter.loginPath;

      if (!loggedIn && !loggingIn) {
        return AppRouter.loginPath;
      }

      if (loggingIn && loggedIn) {
        return AppRouter.homePath;
      }

      return null;
    },
  );
}
