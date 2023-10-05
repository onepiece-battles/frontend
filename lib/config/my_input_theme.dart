import 'package:flutter/material.dart';

class MyInputTheme {
  TextStyle _buildTextStyle(Color color, {double size = 16.0}) {
    return TextStyle(color: color, fontSize: size);
  }

  OutlineInputBorder _buildBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: color, width: 1.0),
    );
  }

  InputDecorationTheme theme() => InputDecorationTheme(
        contentPadding: const EdgeInsets.all(16),
        floatingLabelBehavior: FloatingLabelBehavior.always,

        // borders
        enabledBorder: _buildBorder(Colors.grey[600]!),
        errorBorder: _buildBorder(Colors.red),
        focusedErrorBorder: _buildBorder(Colors.red),
        border: _buildBorder(Colors.yellow),
        focusedBorder: _buildBorder(Colors.blue),
        disabledBorder: _buildBorder(Colors.grey[400]!),

        // text styles
        suffixStyle: _buildTextStyle(Colors.black),
        counterStyle: _buildTextStyle(Colors.grey, size: 12.0),
        floatingLabelStyle: _buildTextStyle(Colors.black),

        errorStyle: _buildTextStyle(Colors.red, size: 12),
        helperStyle: _buildTextStyle(Colors.black, size: 12),
        hintStyle: _buildTextStyle(Colors.grey),
        labelStyle: _buildTextStyle(Colors.black),
        prefixStyle: _buildTextStyle(Colors.black),
      );
}
