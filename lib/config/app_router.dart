import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/views/battle_view.dart';
import 'package:one_piece_battles_flutter/views/character_view.dart';
import 'package:one_piece_battles_flutter/views/fruit_view.dart';
import 'package:one_piece_battles_flutter/views/settings_view.dart';
import 'package:one_piece_battles_flutter/views/user_view.dart';
import 'package:one_piece_battles_flutter/register_page.dart';
import 'package:one_piece_battles_flutter/login_page.dart';
import 'package:one_piece_battles_flutter/home_page.dart';
import 'package:openapi/api.dart';

GetIt getIt = GetIt.instance;
 GlobalKey<NavigatorState> _rootNavigatorState =
GlobalKey<NavigatorState>();
 GlobalKey<NavigatorState> _homeNavigatorState =
GlobalKey<NavigatorState>();
class AppRouter {
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
    routes: <RouteBase>[
      ShellRoute(
          navigatorKey: _homeNavigatorState,
          pageBuilder: (context, state, child) {
            return NoTransitionPage(
              child: HomePage(
                mainScreen: child,
              ),
            );
          },
          routes: <RouteBase>[
            GoRoute(
              path: characterPath,
              name: "character",
              parentNavigatorKey: _homeNavigatorState,
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: CharacterView());
              },
            ),
            GoRoute(
              path: fruitPath,
              name: "fruit",
              parentNavigatorKey: _homeNavigatorState,
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: FruitView());
              },
            ),
            GoRoute(
              path: battlePath,
              name: "battle",
              parentNavigatorKey: _homeNavigatorState,
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: BattleView());
              },
            ),
            GoRoute(
              path: userPath,
              name: "user",
              parentNavigatorKey: _homeNavigatorState,
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: UserView());
              },
            ),
            GoRoute(
              path: settingPath,
              name: "setting",
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
      final registering = state.matchedLocation == AppRouter.registerPath;
      final goingHome = state.matchedLocation == 'home';

      if (registering) {
        return AppRouter.registerPath;
      }
      if (!loggedIn && !loggingIn) {
        return AppRouter.loginPath;
      }
      if (loggedIn) {
        return state.matchedLocation;
      }
      if (goingHome) {
        return AppRouter.homePath;
      }
      return null;
    },
  );
}
