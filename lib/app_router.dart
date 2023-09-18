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
  static final GlobalKey<NavigatorState> _rootNavigatorState = GlobalKey<NavigatorState>();
  static String loginPath = '/login';
  static String homePath = '/home';
  static String registerPath = '/register';
  static final router = GoRouter(
    navigatorKey: _rootNavigatorState,
    initialLocation: loginPath,
    routes: [
      GoRoute(
          path: homePath,
          builder: (context, state) => const ResponsiveLayout(
              desktopScaffold: DesktopScaffold(),
              mobileScaffold: MobileScaffold(),
              tabletScaffold: TabletScaffold())),
      GoRoute(
        path: loginPath,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
          path: registerPath, builder: (context, state) => const RegisterPage()),
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