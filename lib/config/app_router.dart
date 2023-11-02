import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/views/battle_view.dart';
import 'package:one_piece_battles_flutter/views/character_detail_view.dart';
import 'package:one_piece_battles_flutter/views/character_view.dart';
import 'package:one_piece_battles_flutter/views/fruit_view.dart';
import 'package:one_piece_battles_flutter/views/issue_view.dart';
import 'package:one_piece_battles_flutter/views/settings_view.dart';
import 'package:one_piece_battles_flutter/views/user_view.dart';
import 'package:one_piece_battles_flutter/register_page.dart';
import 'package:one_piece_battles_flutter/login_page.dart';
import 'package:one_piece_battles_flutter/home_page.dart';
import 'package:openapi/api.dart';

GetIt getIt = GetIt.instance;
GlobalKey<NavigatorState> _rootNavigatorState = GlobalKey<NavigatorState>();
GlobalKey<NavigatorState> _homeNavigatorState = GlobalKey<NavigatorState>();

class AppRouter {
  // main paths
  static const loginPath = '/login';
  static const homePath = '/home/characters';
  static const registerPath = '/register';

  // sub-paths
  static const characterPath = '/home/characters';
  static const fruitPath = '/home/fruits';
  static const battlePath = '/home/battles';
  static const userPath = '/home/users';
  static const settingPath = '/home/setting';
  static const issuePath = '/home/issues';

  static final router = GoRouter(
    navigatorKey: _rootNavigatorState,
    initialLocation: loginPath,
    routes: [
      ShellRoute(
          navigatorKey: _homeNavigatorState,
          pageBuilder: (context, state, child) {
            return NoTransitionPage(
              child: HomePage(
                mainScreen: child,
              ),
            );
          },
          routes: [
            GoRoute(
              path: characterPath,
              name: "characters",
              parentNavigatorKey: _homeNavigatorState,
              pageBuilder: (context, state) {
                return  NoTransitionPage(child: const CharacterView(),   key : UniqueKey(),);
              },
              routes: [
                GoRoute(
                  path: ':name',
                  name: 'characterDetails',
                  parentNavigatorKey: _homeNavigatorState,
                  pageBuilder: (context, state) {
                    String characterId = state.extra as String;
                    debugPrint('character id router is $characterId');
                    return NoTransitionPage(
                      child: CharacterDetail(
                        characterId: characterId,
                      ),
                    );
                  },
                ),
              ]
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
            GoRoute(
              path: issuePath,
              name: "issue",
              parentNavigatorKey: _homeNavigatorState,
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: IssueView());
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
    // debugLogDiagnostics: true,
    redirect: (context, state) {
      // if the user is not logged in, they need to login
      final loggedIn = getIt<User>().name != '';
      final loggingIn = state.matchedLocation == AppRouter.loginPath;
      final registering = state.matchedLocation == AppRouter.registerPath;
      final goingHome = state.matchedLocation == 'home';
      debugPrint('matched location is ${state.matchedLocation}');

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
