import 'package:flutter/material.dart';
import 'package:one_piece_battles_flutter/register_page.dart';
import 'package:one_piece_battles_flutter/responsive/desktop_scaffold.dart';
import 'package:one_piece_battles_flutter/responsive/mobile_scaffold.dart';
import 'package:one_piece_battles_flutter/responsive/responsive_layout.dart';
import 'package:one_piece_battles_flutter/responsive/tablet_scaffold.dart';
import 'package:openapi/api.dart';
import 'login_page.dart';

class MyRouter {
  static const String homePage = '/home';
  static const String loginPage = '/login';
  static const String registerPage = '/register';
  static Route<dynamic> generateRoute(RouteSettings settings) {
    List<ResourceType> currentArguments = [];
    if (settings.arguments != null) {
      currentArguments = settings.arguments as List<ResourceType>;
    }
    switch (settings.name) {
      case homePage:
        return MaterialPageRoute(
            settings: settings,
            builder: (context) => const ResponsiveLayout(
                desktopScaffold: DesktopScaffold(),
                mobileScaffold: MobileScaffold(),
                tabletScaffold: TabletScaffold()));
      case loginPage:
        return MaterialPageRoute(
            settings: settings, builder: (context) => const LoginPage());
      case registerPage:
        return MaterialPageRoute(
            settings: settings, builder: (context) => const RegisterPage());
      default:
        return MaterialPageRoute(
            settings: settings, builder: (context) => const LoginPage());
    }
  }
}
