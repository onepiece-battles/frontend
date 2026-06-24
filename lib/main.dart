import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:web/web.dart' as web;
import '../../l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
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
import 'components/chat_notifier.dart';
import 'components/web_socket_service.dart';
import 'config/configure_web.dart';
import 'config/my_input_theme.dart';
import 'constants/onepiece_colors.dart';

final getIt = GetIt.instance;

void getItSetUp() {
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
  getIt.registerLazySingleton<WebSocketService>(() => WebSocketService());
  getIt.registerLazySingleton<User>(
      () => User(id: "", username: "", nickname: ""));
}

void webSocketSetUp() {}

void main() {
  final styleElement = web.document.createElement('style');
  styleElement.textContent = '''
    html, body {
      overscroll-behavior-x: none !important;
      overflow-x: hidden;
    }
  ''';
  web.document.head?.appendChild(styleElement);
  configureApp();
  getItSetUp();
  final webSocketService = getIt<WebSocketService>();
  runApp(
    MultiProvider(providers: [
      Provider<WebSocketService>.value(value: webSocketService),
      ChangeNotifierProvider<ChatNotifier>(
        create: (context) => ChatNotifier(
          context.read<WebSocketService>(),
        ),
        lazy:
            false, // Ensures ChatNotifier is created immediately and starts listening
      ),
    ], child: const MyApp()),
  );
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

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior to use ClampingScrollPhysics for all platforms
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('zh', 'CN');

  @override
  void initState() {
    super.initState();
    _setTitle("Onepiece Battles");
  }

  void _setTitle(String title) {
    web.document.title = title; // Set the title dynamically
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
      scrollBehavior: MyCustomScrollBehavior(),
      theme: ThemeData(
        // Use system fonts that are guaranteed to be available instantly —
        // no network-dependent Google Fonts CDN loading.
        fontFamily: getIt<Locale>().languageCode == "en"
            ? '.AppleSystemUIFont'
            : 'PingFang SC',
        fontFamilyFallback: const [
          'PingFang SC', // macOS / iOS Chinese
          'Microsoft YaHei', // Windows Chinese
          'Hiragino Sans GB', // older macOS
          'STHeiti', // macOS fallback
          'Heiti SC', // macOS fallback
          'sans-serif',
        ],
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
