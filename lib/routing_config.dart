import 'package:flutter/material.dart';
import 'package:one_piece_battles_flutter/login_page.dart';
import 'package:one_piece_battles_flutter/register_page.dart';

class RoutingConfig extends StatelessWidget {
  const RoutingConfig({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateRoute: (settings) {
        if (settings.name == '/login') {
          return MaterialPageRoute(
              settings: settings, builder: (context) => const LoginPage());
        }
        if (settings.name == '/register') {
          return MaterialPageRoute(
              settings: settings, builder: (context) => const RegisterPage());
        }
        return MaterialPageRoute(
            settings: settings, builder: (context) => const LoginPage());
      },
    );
  }
}
