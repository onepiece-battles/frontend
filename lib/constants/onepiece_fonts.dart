import 'package:flutter/material.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';

class OnepieceFonts {
  static const TextStyle bountyStyle = TextStyle(
    fontFamily: 'Lobster',
    fontSize: 12,
    color: Color(0xFFF57C00),
  );

  // ===========================================================================
  // 1. Dimensions & Weights
  // ===========================================================================

  static const double sizeMax = 65;
  static const double sizeLoading = 30;

  static const double sizeHeader = 27;
  static const double sizeHeaderSmall = 20;
  static const double sizeHeaderTable = 15;

  static const double sizeContentBig = 22;
  static const double sizeContent = 16;
  static const double sizeContentSmall = 14;
  static const double sizeContentSuperSmall = 12; // Also used for tags

  static const FontWeight weightHeader = FontWeight.bold;
  static const FontWeight weightSemiBold = FontWeight.w600;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightRegular = FontWeight.w400;

  // ===========================================================================
  // 2. Base Styles (Private)
  // Use these as parents for the public styles below
  // ===========================================================================

  static const TextStyle _baseHeader = TextStyle(
    color: Colors.black,
    fontSize: sizeHeader,
    fontWeight: weightHeader,
  );

  static const TextStyle _baseContent = TextStyle(
    color: Colors.black54, // default content color
    fontSize: sizeContent,
    height: 1.3, // looser line-height for CJK readability
  );

  static const TextStyle _baseSmall = TextStyle(
    color: Colors.black54,
    fontSize: sizeContentSmall,
  );

  static const TextStyle _baseSuperSmall = TextStyle(
    color: Colors.black54,
    fontSize: sizeContentSuperSmall,
  );

  // ===========================================================================
  // 3. Public Styles
  // ===========================================================================

  // --- Body text (system fonts — zero network dependency) ---
  // Uses the system UI font for Latin + PingFang SC / Microsoft YaHei for
  // CJK.  No Google Fonts CDN fetch means Chinese renders crisp and
  // instantly, with no tofu (□) flash.
  static const TextStyle contentStyle = TextStyle(
    color: Colors.black54,
    fontSize: sizeContent,
    fontFamily: '.AppleSystemUIFont',
    fontFamilyFallback: [
      'PingFang SC',
      'Microsoft YaHei',
      'Hiragino Sans GB',
      'sans-serif',
    ],
  );
  static const TextStyle loadingFont = TextStyle(
      color: OnepieceColors.fancyBlue,
      fontSize: sizeLoading
  );

  // --- Headers ---
  static const TextStyle headerStyle = _baseHeader;

  static TextStyle get headerStyleWhite =>
      _baseHeader.copyWith(color: Colors.white);

  static TextStyle get smallHeaderStyle =>
      _baseHeader.copyWith(fontSize: sizeHeaderSmall);

  static TextStyle get smallHeaderStyleWhite =>
      _baseHeader.copyWith(fontSize: sizeHeaderSmall, color: Colors.white);

  static TextStyle get smallHeaderStyleFancyBlue =>
      _baseHeader.copyWith(fontSize: sizeHeaderSmall, color: OnepieceColors.fancyBlue);

  static const TextStyle fancyMax = TextStyle(
      color: OnepieceColors.fancyBlue,
      fontSize: sizeMax,
      fontWeight: weightHeader);

  // --- Content / Body ---
  static const TextStyle pageInputStyle = _baseContent;

  static TextStyle get contentStyleBold =>
      _baseContent.copyWith(fontWeight: weightSemiBold);

  static TextStyle get contentStyleBoldWhite =>
      _baseContent.copyWith(fontWeight: weightSemiBold, color: Colors.white);

  static TextStyle get contentStyleBoldFancyBlue =>
      _baseContent.copyWith(fontWeight: weightSemiBold, color: OnepieceColors.fancyBlue);

  static TextStyle get contentStyleAlert =>
      _baseContent.copyWith(color: Colors.red);

  static TextStyle get contentStylePass =>
      _baseContent.copyWith(color: Colors.green);

  static TextStyle get alertTitle =>
      _baseContent.copyWith(color: Colors.red, fontWeight: weightSemiBold);

  static TextStyle get fancyBlueSmallTitle =>
      _baseContent.copyWith(color: OnepieceColors.fancyBlue, fontSize: sizeContentBig);

  // --- Hints ---
  static TextStyle get hintFont =>
      _baseContent.copyWith(color: OnepieceColors.menuIconColor);

  static TextStyle get deepBlackHintFont =>
      _baseContent.copyWith(color: OnepieceColors.black);

  static TextStyle get whiteHintFont =>
      _baseContent.copyWith(color: Colors.white);

  static TextStyle get fancyBlueHintFont =>
      _baseContent.copyWith(color: OnepieceColors.fancyBlue);

  static TextStyle get liteFancyBlueHintFont =>
      _baseContent.copyWith(color: OnepieceColors.liteFancyBlue);

  static TextStyle get boldFancyBlueHintFont =>
      _baseContent.copyWith(color: OnepieceColors.fancyBlue, fontWeight: weightSemiBold);

  static TextStyle get boldLiteFancyBlueHintFont =>
      _baseContent.copyWith(color: OnepieceColors.liteFancyBlue, fontWeight: weightSemiBold);

  // --- Small & Super Small Content ---
  static const TextStyle smallContentStyle = _baseSmall;

  static TextStyle get smallContentStyleWhite =>
      _baseSmall.copyWith(color: Colors.white);

  static TextStyle get smallContentFancyBlueStyle =>
      _baseSmall.copyWith(color: OnepieceColors.fancyBlue, fontWeight: weightSemiBold);

  static const TextStyle superSmallContentStyle = _baseSuperSmall;

  static TextStyle get superSmallContentStyleWhite =>
      _baseSuperSmall.copyWith(color: Colors.white);

  static TextStyle get boldFancyWhiteSmallFont =>
      _baseSuperSmall.copyWith(color: Colors.white, fontWeight: weightSemiBold);

  static TextStyle get boldFancySmallFont =>
      _baseSuperSmall.copyWith(color: OnepieceColors.fancyBlue, fontWeight: weightSemiBold);

  static TextStyle get boldLiteFancySmallFont =>
      _baseSuperSmall.copyWith(color: OnepieceColors.liteFancyBlue, fontWeight: weightSemiBold);

  // --- UI Elements (Tables, Tags, Dropdowns) ---
  static const TextStyle tableHeaderStyle = TextStyle(
      color: Colors.black54,
      fontSize: sizeHeaderTable,
      fontWeight: weightHeader);

  static TextStyle get selectedTableHeaderStyle =>
      tableHeaderStyle.copyWith(color: OnepieceColors.fancyBlue);

  static const TextStyle dropDownItemStyle = TextStyle(
      color: Colors.black54,
      fontSize: sizeContentSmall);

  static const TextStyle tagStyle = TextStyle(
      color: Colors.white,
      fontWeight: weightRegular,
      fontSize: sizeContentSuperSmall);

  static const TextStyle navigationTopBarStyleClickable = TextStyle(
      color: OnepieceColors.fancyBlue,
      fontSize: 16,
      fontWeight: FontWeight.w700);

  static const TextStyle navigationTopBarStyleBold = TextStyle(
      color: Colors.black54,
      fontSize: 16,
      fontWeight: FontWeight.w700);

  static const TextStyle tableHeightStyle = TextStyle(
      color: OnepieceColors.fancyBlue,
      fontSize: 16,
      fontWeight: FontWeight.w700);

  // --- Italic / Special ---
  static const TextStyle emailFont = TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.normal,
      fontStyle: FontStyle.italic);

  static const TextStyle contentStyleWhite = TextStyle(
      color: Colors.white,
      fontSize: 10,
      fontWeight: FontWeight.normal,
      fontStyle: FontStyle.italic);
}
