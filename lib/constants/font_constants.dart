
import 'package:flutter/material.dart';

class FontConstant {
  static const double headerFontSize = 27;
  static const FontWeight headerFontWeight = FontWeight.bold;
  static const Color headerFontColor = Colors.black;
  static const double contentFontSize = 18;
  static const Color contentFontColor = Colors.black54;

  static const TextStyle contentStyle =TextStyle(
  color: FontConstant.contentFontColor,
  fontSize: FontConstant.contentFontSize);

  static const TextStyle headerStyle =   TextStyle(
      color: FontConstant.headerFontColor,
      fontSize: FontConstant.headerFontSize,
      fontWeight: FontConstant.headerFontWeight);

  static const TextStyle tableHeaderStyle = TextStyle(
      color: FontConstant.contentFontColor,
      fontSize: FontConstant.contentFontSize,
      fontWeight: FontConstant.headerFontWeight
  );
}