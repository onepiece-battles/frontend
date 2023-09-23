
import 'package:flutter/material.dart';

class OnepieceFonts {
  static const double headerFontSize = 27;
  static const FontWeight headerFontWeight = FontWeight.bold;
  static const Color headerFontColor = Colors.black;
  static const double contentFontSize = 18;
  static const Color contentFontColor = Colors.black54;
  static const FontWeight sideMenuFontWeight = FontWeight.w500;
  static const int sideMenuFontSize = 10;

  static const TextStyle contentStyle =TextStyle(
  color: OnepieceFonts.contentFontColor,
  fontSize: OnepieceFonts.contentFontSize);

  static const TextStyle headerStyle =   TextStyle(
      color: OnepieceFonts.headerFontColor,
      fontSize: OnepieceFonts.headerFontSize,
      fontWeight: OnepieceFonts.headerFontWeight);

  static const TextStyle tableHeaderStyle = TextStyle(
      color: OnepieceFonts.contentFontColor,
      fontSize: OnepieceFonts.contentFontSize,
      fontWeight: OnepieceFonts.headerFontWeight
  );
}