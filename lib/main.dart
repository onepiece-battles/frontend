import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
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
import 'config/api_initializer.dart';
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
  // Single source of truth for the app locale. Updated via _MyAppState.setLocale.
  getIt.registerSingleton<Locale>(const Locale('zh', 'CN'));
}

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
  ApiInitializer.onSessionExpired = () {
    ApiInitializer.clearAuth();
    getIt<WebSocketService>().disconnect();
    if (getIt.isRegistered<ChatNotifier>()) {
      getIt<ChatNotifier>().clearChatViewState();
    }
    if (getIt.isRegistered<User>()) getIt.unregister<User>();
    getIt.registerLazySingleton<User>(
        () => User(id: '', username: '', nickname: ''));
    AppRouter.router.go(AppRouter.loginPath);
  };
  final webSocketService = getIt<WebSocketService>();
  runApp(
    MultiProvider(providers: [
      Provider<WebSocketService>.value(value: webSocketService),
      ChangeNotifierProvider<ChatNotifier>(
        create: (context) {
          final notifier = ChatNotifier(context.read<WebSocketService>());
          getIt.registerSingleton<ChatNotifier>(notifier);
          return notifier;
        },
        lazy:
            false, // Ensures ChatNotifier is created immediately and starts listening
      ),
    ], child: const MyApp()),
  );
  FlutterNativeSplash.remove();
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();

  static void setLocale(BuildContext context, Locale locale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(locale);
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
    // Keep the DI-provided locale in sync (single source of truth).
    getIt.registerSingleton<Locale>(locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      locale: _locale,
      scrollBehavior: MyCustomScrollBehavior(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: OnepieceColors.fancyBlue,
          primary: OnepieceColors.fancyBlue,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        // Use system fonts that are guaranteed to be available instantly —
        // no network-dependent Google Fonts CDN loading.
        fontFamily:
            _locale.languageCode == "en" ? '.AppleSystemUIFont' : 'PingFang SC',
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
