
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
  static const TextStyle contentStyleBold =TextStyle(
      color: OnepieceFonts.contentFontColor,
      fontSize: OnepieceFonts.contentFontSize,
  fontWeight: FontWeight.w600);

  static const TextStyle headerStyle =   TextStyle(
      color: OnepieceFonts.headerFontColor,
      fontSize: OnepieceFonts.headerFontSize,
      fontWeight: OnepieceFonts.headerFontWeight);

  static const TextStyle tableHeaderStyle = TextStyle(
      color: OnepieceFonts.contentFontColor,
      fontSize: OnepieceFonts.contentFontSize,
      fontWeight: OnepieceFonts.headerFontWeight
  );

  static const TextStyle emailFont = TextStyle(
    color: contentFontColor,
    fontSize: 14,
    fontWeight: FontWeight.bold,
    fontStyle: FontStyle.italic
  );

  static const TextStyle navigationTopBarStyle = TextStyle(
    color: contentFontColor,
    fontSize: 16,
    fontWeight: FontWeight.w500
  );
}