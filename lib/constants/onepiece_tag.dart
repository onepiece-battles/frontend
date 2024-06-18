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

  static Map<UserRole, Color> userRoleToColor = {
    UserRole.NIKA: OnepieceColors.fancyBlue,
    UserRole.ADMIN: OnepieceColors.fancyGreen,
    UserRole.NORMAL: OnepieceColors.liteFancyBlue,
    UserRole.VISITOR: OnepieceColors.liteFancyGreen,
  };

  static Map<ResourceType, Color> resourceTypeToColor = {
    ResourceType.CHARACTER: OnepieceColors.fancyBlue,
    ResourceType.BATTLE: OnepieceColors.fancyGreen,
    ResourceType.GROUP: OnepieceColors.deepBlue,
    ResourceType.ROLE: OnepieceColors.menuHoverColor,
    ResourceType.FRUIT: OnepieceColors.liteFancyBlue,
    ResourceType.ISSUE: OnepieceColors.liteFancyGreen,
    ResourceType.USER: OnepieceColors.menuSelectedTileColor,
  };

  static Map<GroupCategory, Color> groupCategoryToColor = {
    GroupCategory.government: OnepieceColors.fancyBlue,
    GroupCategory.group: Colors.green,
    GroupCategory.pirate: OnepieceColors.black,
    GroupCategory.revolutionArmy: Colors.red,
    GroupCategory.other: Colors.grey,
    GroupCategory.underWorld: OnepieceColors.fancyGreen,
    GroupCategory.marine: OnepieceColors.liteFancyBlue,
  };

  static Map<Haki, Color> hakiToColor = {
    Haki.busoshoku: OnepieceColors.black,
    Haki.kenbunshoku: OnepieceColors.fancyGreen,
    Haki.haoshoku: Colors.deepPurple
  };

  static Color getWakeUpColor(bool wakeUp) {
    if (wakeUp) {
      return OnepieceColors.fancyBlue;
    }
    return OnepieceColors.liteFancyBlue;
  }

  static Widget getUserRoleTag(UserRole userRole, String text) {
    return Container(
      height: 25,
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          color: userRoleToColor[userRole]
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Text(text, style: OnepieceFonts.tagStyle,),
      ),
    );
  }

  static Widget getResourceTag(ResourceType resourceType, String text) {
    return Container(
      height: 25,
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          color: resourceTypeToColor[resourceType]
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Text(text, style: OnepieceFonts.tagStyle,),
      ),
    );
  }

  static Widget getHakiTag(Haki haki, String text) {
    return Container(
      height: 25,
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          color: hakiToColor[haki]
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Text(text, style: OnepieceFonts.tagStyle,),
      ),
    );
  }

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

  static getWakeUpTag(bool wakeUp, String text) {
    return Container(
      height: 25,
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          color: getWakeUpColor(wakeUp)
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Text(text, style: OnepieceFonts.tagStyle,),
      ),
    );
  }

  static getGroupTag(GroupCategory groupCategory, String text) {
    return Container(
      height: 25,
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          color: groupCategoryToColor[groupCategory]
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Text(text, style: OnepieceFonts.tagStyle,),
      ),
    );
  }
}