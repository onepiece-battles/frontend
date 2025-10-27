import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:one_piece_battles_flutter/repository/battle_dao.dart';
import 'package:one_piece_battles_flutter/repository/character_dao.dart';
import 'package:one_piece_battles_flutter/repository/chatting_dao.dart';
import 'package:one_piece_battles_flutter/repository/email_dao.dart';
import 'package:one_piece_battles_flutter/repository/file_dao.dart';
import 'package:one_piece_battles_flutter/repository/fruit_dao.dart';
import 'package:one_piece_battles_flutter/repository/group_dao.dart';
import 'package:one_piece_battles_flutter/repository/image_dao.dart';
import 'package:one_piece_battles_flutter/repository/issue_dao.dart';
import 'package:one_piece_battles_flutter/repository/message_dao.dart';
import 'package:one_piece_battles_flutter/repository/notification_dao.dart';
import 'package:one_piece_battles_flutter/repository/support_dao.dart';
import 'package:one_piece_battles_flutter/repository/user_dao.dart';
import 'package:openapi/api.dart';
import 'app_router.dart';
import 'config/my_input_theme.dart';
import 'constants/onepiece_colors.dart';
import 'dart:html' as html; //

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
  getIt.registerLazySingleton<SupportDao>(() => SupportDao.empty());
  getIt.registerLazySingleton<ChattingDao>(() => ChattingDao.empty());
  getIt.registerLazySingleton<EmailDao>(() => EmailDao.empty());
  getIt.registerLazySingleton<NotificationDao>(() => NotificationDao.empty());
  getIt.registerLazySingleton<MessageDao>(() => MessageDao.empty());
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

  @override
  void initState() {
    super.initState();
    _setTitle("Onepiece Battles");
  }

  void _setTitle(String title) {
    html.document.title = title; // Set the title dynamically
  }

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
      theme: ThemeData(
        fontFamily:
            getIt<Locale>().languageCode == "en" ? 'Roboto' : 'Noto Sans SC',
        inputDecorationTheme: MyInputTheme().theme(),
        tooltipTheme: TooltipThemeData(
          showDuration: const Duration(seconds: 1),
          preferBelow: false,
          decoration: BoxDecoration(
            color: OnepieceColors.fancyBlue, // Background color
            borderRadius: BorderRadius.circular(8), // Rounded corners
            border: Border.all(
              color: Colors.white, // Border color
              width: 1, // Border width
            ),
          ),
        ),
      ),
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
