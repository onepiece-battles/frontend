import 'package:flutter/material.dart';

class LoginInfo extends ChangeNotifier{
  var _userName = '';
  var _token = '';

  String get userName => _userName;
  String get token => _token;
  bool get loggedIn => _userName.isNotEmpty;

  void login(String username, String token) {
    _userName = username;
    _token = token;
  }

  void logout() {
    _userName = '';
    _token = '';
  }
}