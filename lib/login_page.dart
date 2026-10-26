import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:one_piece_battles_flutter/components/web_socket_service.dart';
import '../../l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:one_piece_battles_flutter/config/api_initializer.dart';
import 'package:one_piece_battles_flutter/app_router.dart';
import 'package:one_piece_battles_flutter/config/resource_permission_manager.dart';
import 'package:one_piece_battles_flutter/constants/path_constants.dart';
import 'package:one_piece_battles_flutter/main.dart';
import 'package:one_piece_battles_flutter/repository/user_dao.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:one_piece_battles_flutter/utils/random_string_generator.dart';
import 'package:openapi/api.dart';
import 'components/icp.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'constants/button_style.dart';
import 'constants/onepiece_colors.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

GetIt getIt = GetIt.instance;
const locales = [Locale('zh', 'CN'), Locale('en', 'US')];

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  var _tabTextIndexSelected =
      I18nHelper.convertToOnepieceLocale(getIt<Locale>()).toString() ==
              (OnepieceLocale.zhCN.toString())
          ? 0
          : 1;
  bool _isHidden = true;
  bool _buttonEnabled = false;
  String verificationMessage = "";
  I18nText? verificationI18n = I18nText();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  Logger logger = Logger('_LoginPageState');
  UserDao userDao = UserDao.empty();

  @override
  void initState() {
    super.initState();
    fetchUserCredentials();
  }

  fetchUserCredentials() async {
    String savedUsername = await getUserCredentials();
    if (!mounted) return;
    setState(() {
      emailController.text = savedUsername;
    });
  }

  @override
  Widget build(BuildContext context) {
    final formWidth = MediaQuery.of(context).size.width > 400
        ? 300.0
        : MediaQuery.of(context).size.width - 60;
    return CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.enter): _submitLogin,
          const SingleActivator(LogicalKeyboardKey.numpadEnter): _submitLogin,
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            bottomNavigationBar: const ICP(),
            backgroundColor: Colors.grey[300],
            body: SafeArea(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(30),
                        child: SizedBox(
                          width: 70,
                          height: 30,
                          child: AnimatedToggleSwitch<bool>.dual(
                            current: _tabTextIndexSelected == 1,
                            first: false,
                            second: true,
                            spacing: 1.0,
                            style: const ToggleStyle(
                              borderColor: Colors.transparent,
                              backgroundColor:
                                  Color.fromARGB(255, 182, 180, 180),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  spreadRadius: 1,
                                  blurRadius: 2,
                                  offset: Offset(0, 1.5),
                                ),
                              ],
                            ),
                            borderWidth: 3.0,
                            height: 35,
                            onChanged: (b) => setState(() {
                              setState(() {
                                _tabTextIndexSelected =
                                    _tabTextIndexSelected == 0 ? 1 : 0;
                                Locale locale;
                                if (_tabTextIndexSelected == 0) {
                                  locale = locales.first;
                                } else {
                                  locale = locales.last;
                                }
                                MyApp.setLocale(context, locale);
                                verificationMessage =
                                    I18nHelper.getDisplayNameFromI18nByLocale(
                                        verificationI18n, locale);
                              });
                            }),
                            styleBuilder: (b) => ToggleStyle(
                                indicatorColor: b
                                    ? OnepieceColors.fancyBlue
                                    : OnepieceColors.fancyBlue),
                            iconBuilder: (value) => value
                                ? const Text(
                                    "En",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  )
                                : const Text(
                                    "文",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                            textBuilder: (value) => value
                                ? const Center(
                                    child: Text(
                                    '文',
                                    style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ))
                                : const Center(
                                    child: Text(
                                    'En',
                                    style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  )),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    kIsWeb
                        ? Image.network(
                            'assets/${PathConstants.luffyFlag}',
                            width: 220,
                            height: 142,
                            fit: BoxFit.contain,
                            webHtmlElementStrategy:
                                WebHtmlElementStrategy.prefer,
                          )
                        : Image.asset(
                            PathConstants.luffyFlag,
                            width: 220,
                            height: 142,
                            fit: BoxFit.contain,
                          ),
                    const SizedBox(
                      height: 50,
                    ),
                    Text(
                      AppLocalizations.of(context)!.welcome,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 90),
                    SizedBox(
                      width: formWidth,
                      child: TextFormField(
                        onChanged: (value) {
                          setState(() {
                            if (emailController.text != "" &&
                                passwordController.text != "") {
                              _buttonEnabled = true;
                            } else {
                              _buttonEnabled = false;
                            }
                          });
                        },
                        controller: emailController,
                        autofocus: true,
                        decoration: InputDecoration(
                            labelText:
                                AppLocalizations.of(context)?.emailAddress,
                            prefixIcon: const Icon(Icons.email)),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    SizedBox(
                      width: formWidth,
                      child: TextFormField(
                        onChanged: (value) {
                          setState(() {
                            if (emailController.text != "" &&
                                passwordController.text != "") {
                              _buttonEnabled = true;
                            } else {
                              _buttonEnabled = false;
                            }
                          });
                        },
                        controller: passwordController,
                        keyboardType: TextInputType.text,
                        obscureText: _isHidden,
                        decoration: InputDecoration(
                          labelText:
                              AppLocalizations.of(context)?.passwordLabel,
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isHidden
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Theme.of(context).primaryColorDark,
                            ),
                            onPressed: () {
                              setState(() {
                                _isHidden = !_isHidden;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    Text(
                      verificationMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 10),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: formWidth,
                      child: ElevatedButton(
                        onPressed: !_buttonEnabled ? null : () => _login(),
                        style: OnepieceButtonStyle.getDefaultStyle(),
                        child: Text(
                          AppLocalizations.of(context)!.signIn,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 17),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    SizedBox(
                      width: formWidth,
                      child: ElevatedButton(
                        onPressed: () => _visitorLogin(),
                        style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                            ),
                            foregroundColor: Colors.white),
                        child: Text(
                          AppLocalizations.of(context)!.loginAsVisitor,
                          style: const TextStyle(
                              color: OnepieceColors.fancyBlue,
                              fontWeight: FontWeight.w600,
                              fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      width: formWidth,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final signUp = Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.noAccount,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  context.go(AppRouter.registerPath);
                                },
                                style: _loginLinkButtonStyle(),
                                child: Text(
                                  AppLocalizations.of(context)!.registerAccount,
                                  style: const TextStyle(
                                    color: OnepieceColors.fancyBlue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          );
                          final forgotPassword = TextButton(
                            onPressed: () {
                              context.go(AppRouter.retrievePassword);
                            },
                            style: _loginLinkButtonStyle(),
                            child: Text(
                              AppLocalizations.of(context)!.forgotPassword,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: OnepieceColors.fancyBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );

                          if (constraints.maxWidth < 260) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                signUp,
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: forgotPassword,
                                ),
                              ],
                            );
                          }

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [signUp, forgotPassword],
                          );
                        },
                      ),
                    ),
                    Container(
                      height: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }

  ButtonStyle _loginLinkButtonStyle() {
    return TextButton.styleFrom(
      minimumSize: Size.zero,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      splashFactory: NoSplash.splashFactory,
    ).copyWith(
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
    );
  }

  void _submitLogin() {
    if (_buttonEnabled) {
      _login();
    }
  }

  Future<void> _login() async {
    // read inputs (safe)
    final email = emailController.text.trim();
    final password = passwordController.text;

    // read context-only values synchronously BEFORE async gap
    final locale = Localizations.localeOf(context);
    final router = GoRouter.of(context);

    final request = LoginRequest(email: email, password: password);

    try {
      final LoginResponse? response = await getIt<UserDao>().login(request);
      if (response == null) return;

      if (response.verification == null) {
        await saveUserCredentials(email, password);

        // Ensure still mounted, then perform navigation using current context synchronously.
        if (!mounted) return;
        ApiInitializer.initAuthInfo(response.accessToken!);
        ResourcePermissionManager.updateUserCache(response.user!);
        router.goNamed('characters');
        context
            .read<WebSocketService>()
            .connect(response.user!.id, response.accessToken!);
        return;
      }
      final verification = response.verification!;
      final message =
          I18nHelper.getDisplayNameFromI18nByLocale(verification, locale);
      if (!mounted) return;
      setState(() {
        verificationI18n = verification;
        verificationMessage = message;
      });
    } catch (e, st) {
      debugPrint('Login failed: $e\n$st');
      if (!mounted) return;
    }
  }

  Future<void> _visitorLogin() async {
    final router = GoRouter.of(context);
    String nickname = RandomStringGenerator.generateRandomUserName(10);
    String username = RandomStringGenerator.generateRandomUserName(10);
    String fullUsername = "$username@163.com";
    String password =
        RandomStringGenerator.generateRandomNumber(10000000, 99999999, false);
    RegisterRequest request = RegisterRequest(
        nickname: nickname,
        username: fullUsername,
        password: password,
        userRole: UserRole.VISITOR,
        confirmedPassword: password,
        locale: I18nHelper.convertToOnepieceLocale(getIt<Locale>()));
    RegisterResponse? response = await userDao.register(request);
    if (response == null) return;
    if (response.registerResult) {
      LoginRequest loginRequest =
          LoginRequest(email: fullUsername, password: password);
      LoginResponse? loginResponse = await getIt<UserDao>().login(loginRequest);
      if (loginResponse == null) return;
      if (!mounted) return;
      if (loginResponse.verification == null) {
        if (!mounted) return;
        ApiInitializer.initAuthInfo(loginResponse.accessToken!);
        ResourcePermissionManager.updateUserCache(loginResponse.user!);
        router.goNamed('characters');
        context
            .read<WebSocketService>()
            .connect(loginResponse.user!.id, loginResponse.accessToken!);
      } else {
        setState(() {
          verificationI18n = loginResponse.verification;
          Locale myLocale = Localizations.localeOf(context);
          verificationMessage = I18nHelper.getDisplayNameFromI18nByLocale(
              verificationI18n, myLocale);
        });
      }
    } else {
      setState(() {
        Locale myLocale = Localizations.localeOf(context);
        verificationMessage = I18nHelper.getDisplayNameFromI18nByLocale(
            response.verification, myLocale);
      });
    }
  }

  static const _storage = FlutterSecureStorage();

  // Only the username is persisted for convenience prefill; the password is
  // never stored so it can't be recovered from disk if the device is compromised.
  Future<void> saveUserCredentials(String username, String password) async {
    await _storage.write(key: 'username', value: username);
  }

  Future<String> getUserCredentials() async {
    return await _storage.read(key: 'username') ?? '';
  }
}
