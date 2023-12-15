import 'package:flutter/material.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:openapi/api.dart';

class OnepieceTag {

  static Map<FruitType, Color> fruitTypeToColor = {
    FruitType.logia: OnepieceColors.fruitLogia,
    FruitType.paramecia: OnepieceColors.fruitParamecia,
    FruitType.zoan: OnepieceColors.fruitZoan,
    FruitType.ancientZoan: OnepieceColors.fruitAncientZoan,
    FruitType.mythicalZoan: OnepieceColors.fruitMythicalZoan,
    FruitType.artificialZoan: OnepieceColors.fruitArtificialZoan
  };


  static getFruitTag(FruitType fruitType, String text) {
    return Container(
      height: 25,
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          color: fruitTypeToColor[fruitType]
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Text(text, style: OnepieceFonts.tagStyle,),
      ),
    );
  }
}