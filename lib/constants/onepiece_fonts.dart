import 'package:flutter/material.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';

class OnepieceFonts {
  static const double maxSize = 65;
  static const double loadingSize = 30;
  static const double headerFontSize = 27;
  static const double smallHeaderFontSize = 20;
  static const FontWeight headerFontWeight = FontWeight.bold;
  static const Color headerFontColor = Colors.black;
  static const double contentFontSize = 18;
  static const double bigContentFontSize = 22;
  static const double tableHeaderFontSize = 15;
  static const double dropDownFontSize = 16;
  static const double smallContentFontSize = 16;
  static const double superSmallContentFontSize = 12;
  static const Color contentFontColor = Colors.black54;
  static const FontWeight sideMenuFontWeight = FontWeight.w500;
  static const double tagFont = 12;

  static const TextStyle contentStyle = TextStyle(
      color: OnepieceFonts.contentFontColor,
      fontSize: OnepieceFonts.contentFontSize);
  static const pageInputStyle = TextStyle(
      color: OnepieceFonts.contentFontColor,
      fontSize: OnepieceFonts.contentFontSize,
      height: 1);
  static const TextStyle contentStyleAlert = TextStyle(
      color: Colors.red,
      fontSize: OnepieceFonts.contentFontSize);
  static const TextStyle contentStylePass = TextStyle(
      color: Colors.green,
      fontSize: OnepieceFonts.contentFontSize);
  static const TextStyle tagStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w400,
      fontSize: OnepieceFonts.tagFont);
  static const TextStyle hintFont = TextStyle(
      color: OnepieceColors.menuIconColor,
      fontSize: OnepieceFonts.contentFontSize);
  static const TextStyle fancyBlueHintFont = TextStyle(
      color: OnepieceColors.fancyBlue, fontSize: OnepieceFonts.contentFontSize);

  static const TextStyle boldFancyBlueHintFont = TextStyle(
      color: OnepieceColors.fancyBlue, fontSize: OnepieceFonts.contentFontSize, fontWeight: FontWeight.w600);
  static const TextStyle fancyBlueSmallTitle = TextStyle(
      color: OnepieceColors.fancyBlue, fontSize: OnepieceFonts.bigContentFontSize);
  static const TextStyle liteFancyBlueHintFont = TextStyle(
      color: OnepieceColors.liteFancyBlue,
      fontSize: OnepieceFonts.contentFontSize);
  static const TextStyle deepBlackHintFont = TextStyle(
      color: OnepieceColors.black, fontSize: OnepieceFonts.contentFontSize);
  static const TextStyle loadingFont = TextStyle(
      color: OnepieceColors.fancyBlue, fontSize: OnepieceFonts.loadingSize);
  static const TextStyle smallContentStyle = TextStyle(
      color: OnepieceFonts.contentFontColor,
      fontSize: OnepieceFonts.smallContentFontSize);
  static const TextStyle superSmallContentStyle = TextStyle(
      color: OnepieceFonts.contentFontColor,
      fontSize: OnepieceFonts.superSmallContentFontSize);
  static const TextStyle smallContentStyleWhite = TextStyle(
      color: Colors.white, fontSize: OnepieceFonts.smallContentFontSize);
  static const TextStyle superSmallContentStyleWhite = TextStyle(
      color: Colors.white, fontSize: OnepieceFonts.superSmallContentFontSize);
  static const TextStyle contentStyleBold = TextStyle(
      color: OnepieceFonts.contentFontColor,
      fontSize: OnepieceFonts.contentFontSize,
      fontWeight: FontWeight.w600);

  static const TextStyle contentStyleBoldWhite = TextStyle(
      color: Colors.white,
      fontSize: OnepieceFonts.contentFontSize,
      fontWeight: FontWeight.w600);

  static const TextStyle contentStyleBoldFancyBlue = TextStyle(
      color: OnepieceColors.fancyBlue,
      fontSize: OnepieceFonts.bigContentFontSize,
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

  static const TextStyle smallHeaderStyleWhite = TextStyle(
      color: Colors.white,
      fontSize: OnepieceFonts.smallHeaderFontSize,
      fontWeight: OnepieceFonts.headerFontWeight);

  static const TextStyle smallHeaderStyleFancyBlue = TextStyle(
      color: OnepieceColors.fancyBlue,
      fontSize: OnepieceFonts.smallHeaderFontSize,
      fontWeight: OnepieceFonts.headerFontWeight);

  static const TextStyle headerStyleWhite = TextStyle(
      color: Colors.white,
      fontSize: OnepieceFonts.headerFontSize,
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
      fontSize: 14,
      fontWeight: FontWeight.normal,
      fontStyle: FontStyle.italic);

  static const TextStyle navigationTopBarStyleClickable = TextStyle(
      color: OnepieceColors.fancyBlue,
      fontSize: 16,
      fontWeight: FontWeight.w700);

  static const TextStyle tableHeightStyle = TextStyle(
      color: OnepieceColors.fancyBlue,
      fontSize: 16,
      fontWeight: FontWeight.w700);

  static const TextStyle navigationTopBarStyleBold = TextStyle(
      color: contentFontColor, fontSize: 16, fontWeight: FontWeight.w700);
}
