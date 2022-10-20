import 'package:flutter/material.dart';

class Constants extends InheritedWidget {
  const Constants({super.key, required this.child}) : super(child: child);

  final Widget child;
  static const String welcome = 'Welcome to OnePiece!';
  static const String userNameHint = "Username or Email";
  static const String passWordHint = "Your password";
  static const String userNameLable = "Username";
  static const String passwordLable = "Password";

  // PATH
  static const String loginLuffyImage = 'images/luffy-flag/luffy-flag-2.png';
  static const String registerLuffyImagePath = 'images/luffy-head/luffy.png';

  static Constants? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<Constants>();
  }

  @override
  bool updateShouldNotify(Constants oldWidget) {
    return true;
  }
}
