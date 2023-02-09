import 'package:flutter/material.dart';
import 'package:one_piece_battles_flutter/home_page.dart';
import 'package:one_piece_battles_flutter/register_page.dart';
import 'package:one_piece_battles_flutter/responsive/desktop_scaffold.dart';
import 'package:one_piece_battles_flutter/responsive/mobile_scaffold.dart';
import 'package:one_piece_battles_flutter/responsive/responsive_layout.dart';
import 'package:one_piece_battles_flutter/responsive/tablet_scaffold.dart';
import 'login_page.dart';

class MyRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
            settings: settings,
            builder: (context) => ResponsiveLayout(
                desktopScaffold: const DesktopScaffold(),
                mobileScaffold: const MobileScaffold(),
                tabletScaffold: const TabletScaffold()));
      case '/login':
        return MaterialPageRoute(
            settings: settings, builder: (context) => const LoginPage());
      case '/register':
        return MaterialPageRoute(
            settings: settings, builder: (context) => const RegisterPage());
      default:
        return MaterialPageRoute(
            settings: settings, builder: (context) => const LoginPage());
    }
  }
}
