import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/personal_home.dart';
import 'package:one_piece_battles_flutter/retrieve_password.dart';
import 'package:one_piece_battles_flutter/views/battle/battle_detail_view.dart';
import 'package:one_piece_battles_flutter/views/battle/battle_view.dart';
import 'package:one_piece_battles_flutter/views/character/character_detail_view.dart';
import 'package:one_piece_battles_flutter/views/character/character_view.dart';
import 'package:one_piece_battles_flutter/views/battle/create_battle_view.dart';
import 'package:one_piece_battles_flutter/views/character/create_character_view.dart';
import 'package:one_piece_battles_flutter/views/fruit/create_fruit_view.dart';
import 'package:one_piece_battles_flutter/views/fruit/fruit_detail_view.dart';
import 'package:one_piece_battles_flutter/views/fruit/fruit_view.dart';
import 'package:one_piece_battles_flutter/views/group/create_group_view.dart';
import 'package:one_piece_battles_flutter/views/group/group_detail_view.dart';
import 'package:one_piece_battles_flutter/views/group/group_view.dart';
import 'package:one_piece_battles_flutter/views/issue/issue_detail_view.dart';
import 'package:one_piece_battles_flutter/views/issue/issue_view.dart';
import 'package:one_piece_battles_flutter/views/user/user_detail_view.dart';
import 'package:one_piece_battles_flutter/views/user/user_profile.dart';
import 'package:one_piece_battles_flutter/views/user/user_view.dart';
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
  static const homePath = '/home';
  static const registerPath = '/register';
  static const retrievePassword = '/retrievePassword';
  // sub-paths
  static final characterPath =
      '/home/${ResourceType.CHARACTER.toString().toLowerCase()}';
  static final fruitPath =
      '/home/${ResourceType.FRUIT.toString().toLowerCase()}';
  static final battlePath =
      '/home/${ResourceType.BATTLE.toString().toLowerCase()}';
  static final groupPath =
      '/home/${ResourceType.GROUP.toString().toLowerCase()}';
  static final userManagementPath =
      '/home/${ResourceType.USER.toString().toLowerCase()}';
  static final issuePath =
      '/home/${ResourceType.ISSUE.toString().toLowerCase()}';
  
  static void updateRoutingState(String matchedLocation) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      routeNotifier.value = matchedLocation;
    });
  }

  static final  router = GoRouter(
    navigatorKey: _rootNavigatorState,
    initialLocation: homePath,
    routes: [
      ShellRoute(
        navigatorKey: _homeNavigatorState,
        pageBuilder: (context, state, child) {
          return NoTransitionPage(
              child: HomePage(
                mainScreen: child,
              ),
              key: state.pageKey);
        },
        routes: [
          GoRoute(
            path: characterPath,
            name: "characters",
            parentNavigatorKey: _homeNavigatorState,
            pageBuilder: (context, state) {
              updateRoutingState(state.matchedLocation);
              return NoTransitionPage(
                  child: const CharacterView(), key: UniqueKey());
            },
            routes: [
              GoRoute(
                path: 'create',
                name: 'createCharacter',
                parentNavigatorKey: _homeNavigatorState,
                pageBuilder: (context, state) {
                  updateRoutingState(state.matchedLocation);
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
                  updateRoutingState(state.matchedLocation);
                  String characterId = state.extra as String;
                  return NoTransitionPage(
                      child: CharacterDetail(
                        characterId: characterId,
                      ),);
                },
              ),
            ],
          ),
          GoRoute(
            path: groupPath,
            name: "groups",
            parentNavigatorKey: _homeNavigatorState,
            pageBuilder: (context, state) {
              updateRoutingState(state.matchedLocation);
              return NoTransitionPage(
                  child: const GroupView(), key: UniqueKey());
            },
            routes: [
              GoRoute(
                path: 'create',
                name: 'createGroup',
                parentNavigatorKey: _homeNavigatorState,
                pageBuilder: (context, state) {
                  updateRoutingState(state.matchedLocation);
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
                  updateRoutingState(state.matchedLocation);
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
                updateRoutingState(state.matchedLocation);
                return NoTransitionPage(
                    child: const FruitView(), key: UniqueKey());
              },
              routes: [
                GoRoute(
                  path: 'create',
                  name: 'createFruit',
                  parentNavigatorKey: _homeNavigatorState,
                  pageBuilder: (context, state) {
                    updateRoutingState(state.matchedLocation);
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
                    updateRoutingState(state.matchedLocation);
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
                updateRoutingState(state.matchedLocation);
                return NoTransitionPage(
                    child: const BattleView(), key: UniqueKey());
              },
              routes: [
                GoRoute(
                  path: 'create',
                  name: 'createBattle',
                  parentNavigatorKey: _homeNavigatorState,
                  pageBuilder: (context, state) {
                    updateRoutingState(state.matchedLocation);
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
                    updateRoutingState(state.matchedLocation);
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
            path: userManagementPath,
            name: "userManagement",
            parentNavigatorKey: _homeNavigatorState,
            pageBuilder: (context, state) {
              updateRoutingState(state.matchedLocation);
              return NoTransitionPage(
                  child: const UserView(), key: UniqueKey());
            },
            routes: [
              GoRoute(
                path: ':name',
                name: 'userDetails',
                parentNavigatorKey: _homeNavigatorState,
                pageBuilder: (context, state) {
                  updateRoutingState(state.matchedLocation);
                  String userId = state.extra as String;
                  return NoTransitionPage(
                    child: UserDetailView(
                      userId: userId,
                    ),
                  );
                },
              ),
            ],
          ),
          GoRoute(
              path: issuePath,
              name: "issue",
              parentNavigatorKey: _homeNavigatorState,
              pageBuilder: (context, state) {
                updateRoutingState(state.matchedLocation);
                return NoTransitionPage(
                    child: const IssueView(), key: UniqueKey());
              },
              routes: [
                GoRoute(
                  path: ':id',
                  name: 'issueDetails',
                  parentNavigatorKey: _homeNavigatorState,
                  pageBuilder: (context, state) {
                    updateRoutingState(state.matchedLocation);
                    String issueId = state.extra as String;
                    return NoTransitionPage(
                      child: IssueDetailView(
                        issueId: issueId,
                      ),
                    );
                  },
                ),
              ]),
          GoRoute(
              path: "${AppRouter.homePath}/:name",
              name: "userHome",
              parentNavigatorKey: _homeNavigatorState,
              pageBuilder: (context, state) {
                updateRoutingState(state.matchedLocation);
                return NoTransitionPage(
                    child: UserHome(userId: getIt<User>().id),
                    key: UniqueKey());
              },
              routes: [
                GoRoute(
                  path: 'profile',
                  name: 'userProfile',
                  parentNavigatorKey: _homeNavigatorState,
                  pageBuilder: (context, state) {
                    updateRoutingState(state.matchedLocation);
                    String userId = state.extra as String;
                    return NoTransitionPage(
                        child: UserProfile(
                          userId: userId,
                        ),
                        key: UniqueKey());
                  },
                ),
                GoRoute(
                  path: 'setting',
                  name: 'userSetting',
                  parentNavigatorKey: _homeNavigatorState,
                  pageBuilder: (context, state) {
                    updateRoutingState(state.matchedLocation);
                    String userId = state.extra as String;
                    return NoTransitionPage(
                      child: UserDetailView(
                        userId: userId,
                      ),
                    );
                  },
                ),
              ]),
        ],
      ),
      GoRoute(
        path: loginPath,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: registerPath,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: retrievePassword,
        builder: (context, state) => const RetrievePassword(),
      ),
    ],
    // debugLogDiagnostics: true,
    redirect: (BuildContext context, GoRouterState state) {
      // if the user is not logged in, they need to login
      final loggedIn = getIt<User>().username != '';
      final loggingIn = state.matchedLocation == AppRouter.loginPath;
      final registering = state.matchedLocation == AppRouter.registerPath;
      final retrievePassword =
          state.matchedLocation == AppRouter.retrievePassword;
      List<String> homePaths = [AppRouter.homePath, "", "/"];
      final goingHome = homePaths.contains(state.matchedLocation);
      if (registering) {
        return AppRouter.registerPath;
      }
      if (retrievePassword) {
        return AppRouter.retrievePassword;
      }
      if (!loggedIn && !loggingIn) {
        return AppRouter.loginPath;
      }
      if (goingHome) {
        return state.namedLocation("userHome",
            pathParameters: {"name": getIt<User>().nickname});
      }
      if (loggedIn) {
        return state.matchedLocation;
      }
      return null;
    },
  );
}
