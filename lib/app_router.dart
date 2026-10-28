import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'components/resource_loading.dart';
import 'components/deferred_page.dart';
import 'components/resource_detail_route.dart';
import 'utils/resource_routes.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/personal_home.dart'
    deferred as personal_home;
import 'package:one_piece_battles_flutter/retrieve_password.dart'
    deferred as retrieve_password_view;
import 'package:one_piece_battles_flutter/views/battle/battle_detail_view.dart'
    deferred as battle_detail;
import 'package:one_piece_battles_flutter/views/battle/battle_view.dart'
    deferred as battle_list;
import 'package:one_piece_battles_flutter/views/character/character_detail_view.dart'
    deferred as character_detail;
import 'package:one_piece_battles_flutter/views/character/character_view.dart'
    deferred as character_list;
import 'package:one_piece_battles_flutter/views/battle/create_battle_view.dart'
    deferred as create_battle;
import 'package:one_piece_battles_flutter/views/character/create_character_view.dart'
    deferred as create_character;
import 'package:one_piece_battles_flutter/views/chatting/chatting_view.dart'
    deferred as chatting_view;
import 'package:one_piece_battles_flutter/views/assistant/assistant_view.dart'
    deferred as assistant_view;
import 'package:one_piece_battles_flutter/views/fruit/create_fruit_view.dart'
    deferred as create_fruit;
import 'package:one_piece_battles_flutter/views/fruit/fruit_detail_view.dart'
    deferred as fruit_detail;
import 'package:one_piece_battles_flutter/views/fruit/fruit_view.dart'
    deferred as fruit_list;
import 'package:one_piece_battles_flutter/views/group/create_group_view.dart'
    deferred as create_group;
import 'package:one_piece_battles_flutter/views/group/group_detail_view.dart'
    deferred as group_detail;
import 'package:one_piece_battles_flutter/views/group/group_view.dart'
    deferred as group_list;
import 'package:one_piece_battles_flutter/views/issue/issue_detail_view.dart'
    deferred as issue_detail;
import 'package:one_piece_battles_flutter/views/issue/issue_view.dart'
    deferred as issue_list;
import 'package:one_piece_battles_flutter/views/user/user_detail_view.dart'
    deferred as user_detail;
import 'package:one_piece_battles_flutter/views/user/user_profile.dart'
    deferred as user_profile;
import 'package:one_piece_battles_flutter/views/user/user_view.dart'
    deferred as user_list;
import 'package:one_piece_battles_flutter/register_page.dart'
    deferred as register_view;
import 'package:one_piece_battles_flutter/login_page.dart';
import 'package:one_piece_battles_flutter/home_page.dart';
import 'package:one_piece_battles_flutter/utils/route_notifier.dart';
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
  static final chattingPath =
      '/home/${ResourceType.CHATTING.toString().toLowerCase()}';
  static const assistantPath = '/home/assistant';

  static void updateRoutingState(String matchedLocation) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      routeNotifier.value = matchedLocation;
    });
  }

  static final router = GoRouter(
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
            path: assistantPath,
            name: "assistant",
            parentNavigatorKey: _homeNavigatorState,
            pageBuilder: (context, state) {
              updateRoutingState(state.matchedLocation);
              return NoTransitionPage(
                  child: DeferredPage(
                      load: assistant_view.loadLibrary,
                      page: () => assistant_view.AssistantView()),
                  key: state.pageKey);
            },
          ),
          GoRoute(
            path: characterPath,
            name: "characters",
            parentNavigatorKey: _homeNavigatorState,
            pageBuilder: (context, state) {
              updateRoutingState(state.matchedLocation);
              return NoTransitionPage(
                  child: DeferredPage(
                      load: character_list.loadLibrary,
                      page: () => character_list.CharacterView()),
                  key: state.pageKey);
            },
            routes: [
              GoRoute(
                path: 'create',
                name: 'create_character',
                parentNavigatorKey: _homeNavigatorState,
                pageBuilder: (context, state) {
                  updateRoutingState(state.matchedLocation);
                  return NoTransitionPage(
                    child: DeferredPage(
                        load: create_character.loadLibrary,
                        page: () => create_character.CreateCharacterView()),
                  );
                },
              ),
              GoRoute(
                path: ':name',
                name: 'characterDetails',
                parentNavigatorKey: _homeNavigatorState,
                pageBuilder: (context, state) {
                  updateRoutingState(state.matchedLocation);
                  final characterId = ResourceRoutes.id(state);
                  return NoTransitionPage(
                    child: DeferredPage(
                        load: character_detail.loadLibrary,
                        page: () => ResourceDetailRoute(
                            id: characterId,
                            type: 'character',
                            name: state.pathParameters['name'] ?? '',
                            page: (id) => character_detail.CharacterDetail(
                                characterId: id))),
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
              updateRoutingState(state.matchedLocation);
              return NoTransitionPage(
                  child: DeferredPage(
                      load: group_list.loadLibrary,
                      page: () => group_list.GroupView()),
                  key: state.pageKey);
            },
            routes: [
              GoRoute(
                path: 'create',
                name: 'create_group',
                parentNavigatorKey: _homeNavigatorState,
                pageBuilder: (context, state) {
                  updateRoutingState(state.matchedLocation);
                  return NoTransitionPage(
                    child: DeferredPage(
                        load: create_group.loadLibrary,
                        page: () => create_group.CreateGroupView()),
                  );
                },
              ),
              GoRoute(
                path: ':name',
                name: 'groupDetails',
                parentNavigatorKey: _homeNavigatorState,
                pageBuilder: (context, state) {
                  updateRoutingState(state.matchedLocation);
                  final groupId = ResourceRoutes.id(state);
                  return NoTransitionPage(
                    child: DeferredPage(
                        load: group_detail.loadLibrary,
                        page: () => ResourceDetailRoute(
                            id: groupId,
                            type: 'group',
                            name: state.pathParameters['name'] ?? '',
                            page: (id) =>
                                group_detail.GroupDetailView(groupId: id))),
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
                    child: DeferredPage(
                        load: fruit_list.loadLibrary,
                        page: () => fruit_list.FruitView()),
                    key: state.pageKey);
              },
              routes: [
                GoRoute(
                  path: 'create',
                  name: 'create_fruit',
                  parentNavigatorKey: _homeNavigatorState,
                  pageBuilder: (context, state) {
                    updateRoutingState(state.matchedLocation);
                    return NoTransitionPage(
                      child: DeferredPage(
                          load: create_fruit.loadLibrary,
                          page: () => create_fruit.CreateFruitView()),
                    );
                  },
                ),
                GoRoute(
                  path: ':name',
                  name: 'fruitDetails',
                  parentNavigatorKey: _homeNavigatorState,
                  pageBuilder: (context, state) {
                    updateRoutingState(state.matchedLocation);
                    final fruitId = ResourceRoutes.id(state);
                    return NoTransitionPage(
                      child: DeferredPage(
                          load: fruit_detail.loadLibrary,
                          page: () => ResourceDetailRoute(
                              id: fruitId,
                              type: 'fruit',
                              name: state.pathParameters['name'] ?? '',
                              page: (id) =>
                                  fruit_detail.FruitDetailView(fruitId: id))),
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
                    child: DeferredPage(
                        load: battle_list.loadLibrary,
                        page: () => battle_list.BattleView()),
                    key: state.pageKey);
              },
              routes: [
                GoRoute(
                  path: 'create',
                  name: 'create_battle',
                  parentNavigatorKey: _homeNavigatorState,
                  pageBuilder: (context, state) {
                    updateRoutingState(state.matchedLocation);
                    return NoTransitionPage(
                      child: DeferredPage(
                          load: create_battle.loadLibrary,
                          page: () => create_battle.CreateBattleView()),
                    );
                  },
                ),
                GoRoute(
                  path: ':id',
                  name: 'battleDetails',
                  parentNavigatorKey: _homeNavigatorState,
                  pageBuilder: (context, state) {
                    updateRoutingState(state.matchedLocation);
                    final battleId = ResourceRoutes.id(state);
                    return NoTransitionPage(
                      child: DeferredPage(
                          load: battle_detail.loadLibrary,
                          page: () => battleId == null
                              ? const ResourceEmptyState()
                              : battle_detail.BattleDetailView(
                                  battleId: battleId,
                                )),
                    );
                  },
                ),
              ]),
          GoRoute(
            path: chattingPath,
            name: "chatting",
            parentNavigatorKey: _homeNavigatorState,
            pageBuilder: (context, state) {
              updateRoutingState(state.matchedLocation);
              return NoTransitionPage(
                  child: DeferredPage(
                      load: chatting_view.loadLibrary,
                      page: () => chatting_view.ChattingView()),
                  key: state.pageKey);
            },
          ),
          GoRoute(
            path: userManagementPath,
            name: "userManagement",
            parentNavigatorKey: _homeNavigatorState,
            pageBuilder: (context, state) {
              updateRoutingState(state.matchedLocation);
              return NoTransitionPage(
                  child: DeferredPage(
                      load: user_list.loadLibrary,
                      page: () => user_list.UserView()),
                  key: state.pageKey);
            },
            routes: [
              GoRoute(
                path: ':name',
                name: 'userDetails',
                parentNavigatorKey: _homeNavigatorState,
                pageBuilder: (context, state) {
                  updateRoutingState(state.matchedLocation);
                  final userId = ResourceRoutes.id(state);
                  return NoTransitionPage(
                    child: DeferredPage(
                        load: user_detail.loadLibrary,
                        page: () => userId == null
                            ? const ResourceEmptyState()
                            : user_detail.UserDetailView(
                                userId: userId,
                              )),
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
                    child: DeferredPage(
                        load: issue_list.loadLibrary,
                        page: () => issue_list.IssueView()),
                    key: state.pageKey);
              },
              routes: [
                GoRoute(
                  path: ':id',
                  name: 'issueDetails',
                  parentNavigatorKey: _homeNavigatorState,
                  pageBuilder: (context, state) {
                    updateRoutingState(state.matchedLocation);
                    final issueId = ResourceRoutes.id(state);
                    return NoTransitionPage(
                      child: DeferredPage(
                          load: issue_detail.loadLibrary,
                          page: () => issueId == null
                              ? const ResourceEmptyState()
                              : issue_detail.IssueDetailView(
                                  issueId: issueId,
                                )),
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
                    child: DeferredPage(
                        load: personal_home.loadLibrary,
                        page: () =>
                            personal_home.UserHome(userId: getIt<User>().id)),
                    key: state.pageKey);
              },
              routes: [
                GoRoute(
                  path: 'profile',
                  name: 'user_profile',
                  parentNavigatorKey: _homeNavigatorState,
                  pageBuilder: (context, state) {
                    updateRoutingState(state.matchedLocation);
                    final userId = ResourceRoutes.id(state) ?? getIt<User>().id;
                    return NoTransitionPage(
                        child: DeferredPage(
                            load: user_profile.loadLibrary,
                            page: () => user_profile.UserProfile(
                                  userId: userId,
                                )),
                        key: state.pageKey);
                  },
                ),
                GoRoute(
                  path: 'setting',
                  name: 'userSetting',
                  parentNavigatorKey: _homeNavigatorState,
                  pageBuilder: (context, state) {
                    updateRoutingState(state.matchedLocation);
                    final userId = ResourceRoutes.id(state);
                    return NoTransitionPage(
                      child: DeferredPage(
                          load: user_detail.loadLibrary,
                          page: () => userId == null
                              ? const ResourceEmptyState()
                              : user_detail.UserDetailView(
                                  userId: userId,
                                )),
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
        builder: (context, state) => DeferredPage(
            load: register_view.loadLibrary,
            page: () => register_view.RegisterPage()),
      ),
      GoRoute(
        path: retrievePassword,
        builder: (context, state) => DeferredPage(
            load: retrieve_password_view.loadLibrary,
            page: () => retrieve_password_view.RetrievePassword()),
      ),
    ],
    // debugLogDiagnostics: true,
    redirect: (BuildContext context, GoRouterState state) {
      final loggedIn = getIt<User>().username.isNotEmpty;
      final uri = ResourceRoutes.canonicalUri(state);
      final publicPaths = [loginPath, registerPath, retrievePassword];
      if (!loggedIn && !publicPaths.contains(uri.path)) {
        return ResourceRoutes.loginLocation(uri);
      }
      if (loggedIn && uri.path == loginPath) {
        return ResourceRoutes.afterLogin(uri);
      }
      if (loggedIn && [homePath, '', '/'].contains(uri.path)) {
        return state.namedLocation('userHome',
            pathParameters: {'name': getIt<User>().nickname});
      }
      if (uri.toString() != state.uri.toString()) return uri.toString();
      return null;
    },
  );
}
