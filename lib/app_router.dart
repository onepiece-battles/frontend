import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/views/battle_detail_view.dart';
import 'package:one_piece_battles_flutter/views/battle_view.dart';
import 'package:one_piece_battles_flutter/views/character/character_detail_view.dart';
import 'package:one_piece_battles_flutter/views/character/character_view.dart';
import 'package:one_piece_battles_flutter/views/create_battle_view.dart';
import 'package:one_piece_battles_flutter/views/character/create_character_view.dart';
import 'package:one_piece_battles_flutter/views/create_fruit_view.dart';
import 'package:one_piece_battles_flutter/views/fruit_detail_view.dart';
import 'package:one_piece_battles_flutter/views/fruit_view.dart';
import 'package:one_piece_battles_flutter/views/group/create_group_view.dart';
import 'package:one_piece_battles_flutter/views/group/group_detail_view.dart';
import 'package:one_piece_battles_flutter/views/group/group_view.dart';
import 'package:one_piece_battles_flutter/views/issue_view.dart';
import 'package:one_piece_battles_flutter/views/settings_view.dart';
import 'package:one_piece_battles_flutter/views/user_detail_view.dart';
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
  static const groupPath = '/home/groups';
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
                  return NoTransitionPage(
                      child: const CharacterView(), key: UniqueKey());
                },
                routes: [
                  GoRoute(
                    path: 'create',
                    name: 'createCharacter',
                    parentNavigatorKey: _homeNavigatorState,
                    pageBuilder: (context, state) {
                      return const NoTransitionPage(
                        child: CreateCharacterView(),
                      );
                    },
                  ),
                  GoRoute(
                    path: ':name',
                    name: 'characterDetails',
                    parentNavigatorKey: _homeNavigatorState,
                    pageBuilder: (context, state) {
                      String characterId = state.extra as String;
                      return NoTransitionPage(
                        child: CharacterDetail(
                          characterId: characterId,
                        ),
                      );
                    },
                  ),
                ],
            ),
            GoRoute(
              path: groupPath,
              name: "groups",
              parentNavigatorKey: _homeNavigatorState,
              pageBuilder: (context, state) {
                return NoTransitionPage(
                    child: const GroupView(), key: UniqueKey());
              },
              routes: [
                GoRoute(
                  path: 'create',
                  name: 'createGroup',
                  parentNavigatorKey: _homeNavigatorState,
                  pageBuilder: (context, state) {
                    return const NoTransitionPage(
                      child: CreateGroupView(),
                    );
                  },
                ),
                GoRoute(
                  path: ':name',
                  name: 'groupDetails',
                  parentNavigatorKey: _homeNavigatorState,
                  pageBuilder: (context, state) {
                    String groupId = state.extra as String;
                    return NoTransitionPage(
                      child: GroupDetailView(
                        groupId: groupId,
                      ),
                    );
                  },
                ),
              ],
            ),
            GoRoute(
                path: fruitPath,
                name: "fruit",
                parentNavigatorKey: _homeNavigatorState,
                pageBuilder: (context, state) {
                  return NoTransitionPage(
                      child: const FruitView(), key: UniqueKey());
                },
                routes: [
                  GoRoute(
                    path: 'create',
                    name: 'createFruit',
                    parentNavigatorKey: _homeNavigatorState,
                    pageBuilder: (context, state) {
                      return const NoTransitionPage(
                        child: CreateFruitView(),
                      );
                    },
                  ),
                  GoRoute(
                    path: ':name',
                    name: 'fruitDetails',
                    parentNavigatorKey: _homeNavigatorState,
                    pageBuilder: (context, state) {
                      String fruitId = state.extra as String;
                      return NoTransitionPage(
                        child: FruitDetailView(
                          fruitId: fruitId,
                        ),
                      );
                    },
                  ),
                ]),
            GoRoute(
                path: battlePath,
                name: "battle",
                parentNavigatorKey: _homeNavigatorState,
                pageBuilder: (context, state) {
                  return NoTransitionPage(
                      child: const BattleView(), key: UniqueKey());
                },
                routes: [
                  GoRoute(
                    path: 'create',
                    name: 'createBattle',
                    parentNavigatorKey: _homeNavigatorState,
                    pageBuilder: (context, state) {
                      return const NoTransitionPage(
                        child: CreateBattleView(),
                      );
                    },
                  ),
                  GoRoute(
                    path: ':id',
                    name: 'battleDetails',
                    parentNavigatorKey: _homeNavigatorState,
                    pageBuilder: (context, state) {
                      String battleId = state.extra as String;
                      return NoTransitionPage(
                        child: BattleDetailView(
                          battleId: battleId,
                        ),
                      );
                    },
                  ),
                ]),
            GoRoute(
              path: userPath,
              name: "user",
              parentNavigatorKey: _homeNavigatorState,
              pageBuilder: (context, state) {
                return NoTransitionPage(
                    child: const UserView(), key: UniqueKey());
              },
              routes: [
                GoRoute(
                  path: ':name',
                  name: 'userDetails',
                  parentNavigatorKey: _homeNavigatorState,
                  pageBuilder: (context, state) {
                    String userId = state.extra as String;
                    return NoTransitionPage(
                      child: UserDetailView(
                        userId: userId,
                      ),
                    );
                  },
                ),
              ]
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
                return NoTransitionPage(
                    child: const IssueView(), key: UniqueKey());
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
