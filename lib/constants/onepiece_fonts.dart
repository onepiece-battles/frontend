import 'package:flutter/material.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';

class OnepieceFonts {
  static const double maxSize = 65;
  static const double headerFontSize = 27;
  static const double smallHeaderFontSize = 20;
  static const FontWeight headerFontWeight = FontWeight.bold;
  static const Color headerFontColor = Colors.black;
  static const double contentFontSize = 18;
  static const double tableHeaderFontSize = 15;
  static const double dropDownFontSize = 16;
  static const double smallContentFontSize = 16;
  static const Color contentFontColor = Colors.black54;
  static const FontWeight sideMenuFontWeight = FontWeight.w500;
  static const int sideMenuFontSize = 10;

  static const TextStyle contentStyle = TextStyle(
      color: OnepieceFonts.contentFontColor,
      fontSize: OnepieceFonts.contentFontSize);
  static const TextStyle hintFont = TextStyle(
      color: OnepieceColors.menuIconColor,
      fontSize: OnepieceFonts.contentFontSize);
  static const TextStyle fancyBlueHintFont = TextStyle(
      color: OnepieceColors.fancyBlue, fontSize: OnepieceFonts.contentFontSize);
  static const TextStyle smallContentStyle = TextStyle(
      color: OnepieceFonts.contentFontColor,
      fontSize: OnepieceFonts.smallContentFontSize);
  static const TextStyle contentStyleBold = TextStyle(
      color: OnepieceFonts.contentFontColor,
      fontSize: OnepieceFonts.contentFontSize,
      fontWeight: FontWeight.w600);

  static const TextStyle contentStyleBoldWhite = TextStyle(
      color: Colors.white,
      fontSize: OnepieceFonts.contentFontSize,
      fontWeight: FontWeight.w600);

  static const TextStyle headerStyle = TextStyle(
      color: OnepieceFonts.headerFontColor,
      fontSize: OnepieceFonts.headerFontSize,
      fontWeight: OnepieceFonts.headerFontWeight);

  static const TextStyle fancyMax = TextStyle(
      color: OnepieceColors.fancyBlue,
      fontSize: OnepieceFonts.maxSize,
      fontWeight: OnepieceFonts.headerFontWeight);

  static const TextStyle smallHeaderStyle = TextStyle(
      color: OnepieceFonts.headerFontColor,
      fontSize: OnepieceFonts.smallHeaderFontSize,
      fontWeight: OnepieceFonts.headerFontWeight);

  static const TextStyle tableHeaderStyle = TextStyle(
      color: OnepieceFonts.contentFontColor,
      fontSize: OnepieceFonts.tableHeaderFontSize,
      fontWeight: OnepieceFonts.headerFontWeight);
  static const TextStyle selectedTableHeaderStyle = TextStyle(
      color: OnepieceColors.fancyBlue,
      fontSize: OnepieceFonts.tableHeaderFontSize,
      fontWeight: OnepieceFonts.headerFontWeight);
  static const TextStyle dropDownItemStyle = TextStyle(
      color: OnepieceFonts.contentFontColor,
      fontSize: OnepieceFonts.dropDownFontSize);

  static const TextStyle emailFont = TextStyle(
      color: Colors.white,
      fontSize: 13,
      fontWeight: FontWeight.bold,
      fontStyle: FontStyle.italic);

  static const TextStyle navigationTopBarStyleClickable = TextStyle(
      color: OnepieceColors.fancyBlue,
      fontSize: 16,
      fontWeight: FontWeight.w700);

  static const TextStyle navigationTopBarStyleBold = TextStyle(
      color: contentFontColor, fontSize: 16, fontWeight: FontWeight.w700);
}
