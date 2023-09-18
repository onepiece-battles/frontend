import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/register_page.dart';
import 'package:one_piece_battles_flutter/responsive/desktop_scaffold.dart';
import 'package:one_piece_battles_flutter/responsive/mobile_scaffold.dart';
import 'package:one_piece_battles_flutter/responsive/responsive_layout.dart';
import 'package:one_piece_battles_flutter/responsive/tablet_scaffold.dart';
import 'login_info.dart';
import 'login_page.dart';

class AppRouter{
  static final LoginInfo loginInfo = LoginInfo();
  static final GlobalKey<NavigatorState> _rootNavigatorState = GlobalKey<NavigatorState>();
  static late final router = GoRouter(
    navigatorKey: _rootNavigatorState,
    initialLocation: '/login',
    routes: [
      GoRoute(
          path: '/home',
          builder: (context, state) => const ResponsiveLayout(
              desktopScaffold: DesktopScaffold(),
              mobileScaffold: MobileScaffold(),
              tabletScaffold: TabletScaffold())),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
          path: '/register', builder: (context, state) => const RegisterPage()),
    ],
    // redirect: (context, state) {
    //   // if the user is not logged in, they need to login
    //   final loggedIn = loginInfo.loggedIn;
    //   final loggingIn = state.matchedLocation == '/login';
    //   if (!loggedIn) return loggingIn ? null : '/login';
    //
    //   // if the user is logged in but still on the login page, send them to
    //   // the home page
    //   if (loggingIn) return '/';
    //
    //   // no need to redirect at all
    //   return null;
    // },
  );
}