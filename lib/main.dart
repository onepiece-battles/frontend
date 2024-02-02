import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/repository/battle_dao.dart';
import 'package:one_piece_battles_flutter/repository/character_dao.dart';
import 'package:one_piece_battles_flutter/repository/file_dao.dart';
import 'package:one_piece_battles_flutter/repository/fruit_dao.dart';
import 'package:one_piece_battles_flutter/repository/group_dao.dart';
import 'package:one_piece_battles_flutter/repository/image_dao.dart';
import 'package:one_piece_battles_flutter/repository/issue_dao.dart';
import 'package:one_piece_battles_flutter/repository/user_dao.dart';
import 'package:openapi/api.dart';
import 'app_router.dart';
import 'config/my_input_theme.dart';

final getIt = GetIt.instance;

void setup() {
  getIt.allowReassignment = true;
  getIt.registerLazySingleton<UserDao>(() => UserDao.empty());
  getIt.registerLazySingleton<CharacterDao>(() => CharacterDao.empty());
  getIt.registerLazySingleton<ImageDao>(() => ImageDao.empty());
  getIt.registerLazySingleton<IssueDao>(() => IssueDao.empty());
  getIt.registerLazySingleton<BattleDao>(() => BattleDao.empty());
  getIt.registerLazySingleton<FruitDao>(() => FruitDao.empty());
  getIt.registerLazySingleton<FileDao>(() => FileDao.empty());
  getIt.registerLazySingleton<GroupDao>(() => GroupDao.empty());
  getIt.registerLazySingleton<User>(
      () => User(id: "", username: "", nickname: ""));
}

void main() {
  setup();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();

  static void setLocale(BuildContext context, Locale locale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(locale);
    getIt.registerLazySingleton<Locale>(() => locale);
  }
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('zh', 'CN');

  setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    getIt.registerLazySingleton<Locale>(() => _locale);
    return MaterialApp.router(
      locale: _locale,
      theme: ThemeData(inputDecorationTheme: MyInputTheme().theme()),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', 'US'), Locale('zh', 'CN')],
      routerConfig: AppRouter.router,
    );
  }
}
