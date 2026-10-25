import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';
import 'package:one_piece_battles_flutter/config/my_input_theme.dart';
import 'package:one_piece_battles_flutter/l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:one_piece_battles_flutter/repository/character_dao.dart';
import 'package:one_piece_battles_flutter/repository/fruit_dao.dart';
import 'package:one_piece_battles_flutter/repository/group_dao.dart';
import 'package:one_piece_battles_flutter/repository/battle_dao.dart';
import 'package:one_piece_battles_flutter/repository/image_dao.dart';
import 'package:one_piece_battles_flutter/repository/file_dao.dart';
import 'package:one_piece_battles_flutter/views/character/character_detail_view.dart';
import 'package:one_piece_battles_flutter/views/fruit/fruit_detail_view.dart';
import 'package:one_piece_battles_flutter/views/group/group_detail_view.dart';
import 'package:one_piece_battles_flutter/views/battle/battle_detail_view.dart';
import 'support/resource_detail_fakes.dart';

class _Images extends ImageDao {
  _Images() : super.empty();
  @override
  Future<GetImageResponse?> getImage(GetImageRequest request) async {
    final data = await rootBundle.load(request.uri.contains('group')
        ? 'asset/images/luffy-flag/luffy_flag.png' : 'asset/images/luffy-head/luffy.png');
    return GetImageResponse(image: base64Encode(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes)));
  }
}

class _Characters extends DetailCharacterFake {
  @override
  Future<CharacterFullView?> getCharacter(GetCharacterFullViewRequest request) async {
    final character = (await super.getCharacter(request))!;
    character.imageUri = 'preview-character';
    character.name = I18nText(zhCN: '蒙奇·D·路飞', enUS: 'Monkey D. Luffy');
    character.age = 19; character.height = 174; character.birthPlace = '东海 · 风车村'; character.dateOfBirth = '05-05';
    return character;
  }
}

class _Groups extends DetailGroupFake {
  @override
  Future<GroupFullView?> getGroupFullView(GetGroupRequest request) async {
    final group = (await super.getGroupFullView(request))!;
    group.imageUri = 'preview-group';
    return group;
  }
}

class _Battles extends DetailBattleFake {
  @override
  Future<BattleFullView?> getBattleFullView(GetBattleFullViewRequest request) async {
    final battle = (await super.getBattleFullView(request))!;
    battle.starter!.imageUri = 'preview-character';
    battle.receiver!.imageUri = 'preview-group';
    battle.starter!.name = I18nText(zhCN: '蒙奇·D·路飞', enUS: 'Monkey D. Luffy');
    battle.receiver!.name = I18nText(zhCN: '罗罗诺亚·索隆', enUS: 'Roronoa Zoro');
    return battle;
  }
}

void main() {
  GetIt.instance.registerSingleton<User>(User(id: 'preview', username: 'preview', nickname: 'Preview', loginRole: UserRole.NIKA));
  GetIt.instance.registerSingleton<Locale>(const Locale('zh'));
  GetIt.instance.registerSingleton<CharacterDao>(_Characters());
  GetIt.instance.registerSingleton<FruitDao>(DetailFruitFake());
  GetIt.instance.registerSingleton<GroupDao>(_Groups());
  GetIt.instance.registerSingleton<BattleDao>(_Battles());
  GetIt.instance.registerSingleton<ImageDao>(_Images());
  GetIt.instance.registerSingleton<FileDao>(FileDao.empty());
  final pages = <String, Widget>{'character': const CharacterDetail(characterId: '0'),
    'fruit': const FruitDetailView(fruitId: '0'), 'group': const GroupDetailView(groupId: '0'), 'battle': const BattleDetailView(battleId: '0')};
  runApp(MaterialApp(debugShowCheckedModeBanner: false, locale: const Locale('zh'),
    localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData(fontFamily: 'PingFang SC', scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(seedColor: OnepieceColors.fancyBlue, primary: OnepieceColors.fancyBlue, surface: Colors.white),
      inputDecorationTheme: MyInputTheme().theme()),
    home: Scaffold(body: pages[Uri.base.queryParameters['view']] ?? pages['character']),
  ));
  FlutterNativeSplash.remove();
}
