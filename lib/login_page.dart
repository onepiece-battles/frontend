import 'package:animated_toggle_switch/animated_toggle_switch.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
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
  TextEditingController emailController =
      TextEditingController(text: "onepiecebattles@163.com");
  TextEditingController passwordController = TextEditingController(text: "abc");
  Logger logger = Logger('_LoginPageState');
  UserDao userDao = UserDao.empty();

  @override
  void initState() {
    super.initState();
    fetchUserCredentials();
  }

  fetchUserCredentials() async {
    Map<String, String> userCredentials = await getUserCredentials();
    setState(() {
      emailController.text = userCredentials['username'] ?? "";
      passwordController.text = userCredentials['password'] ?? "";
      if (emailController.text.isNotEmpty &&
          passwordController.text.isNotEmpty) {
        _buttonEnabled = true;
      }
    });
  }

  final FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (KeyEvent keyEvent) {
          if (keyEvent is KeyDownEvent) {
            final logical = (keyEvent.logicalKey);
            if (logical == LogicalKeyboardKey.enter ||
                logical == LogicalKeyboardKey.numpadEnter) {
              if (_buttonEnabled) {
                _login();
              }
            }
          }
        },
        child: Scaffold(
          bottomNavigationBar: const ICP(),
          backgroundColor: Colors.grey[300],
          body: SingleChildScrollView(
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
                          backgroundColor: Color.fromARGB(255, 182, 180, 180),
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
                  height: 160,
                ),
                const Image(
                  image: AssetImage(PathConstants.luffyFlag),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: Text(
                    AppLocalizations.of(context)!.welcome,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: OnepieceColors.fancyBlue),
                  ),
                ),
                const SizedBox(height: 90),
                const SizedBox(
                  height: 20,
                ),
                SizedBox(
                  width: 300,
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
                        labelText: AppLocalizations.of(context)?.emailAddress,
                        prefixIcon: const Icon(Icons.email)),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                SizedBox(
                  width: 300,
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
                      labelText: AppLocalizations.of(context)?.passwordLabel,
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isHidden ? Icons.visibility_off : Icons.visibility,
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
                  width: 300,
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
                  width: 300,
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
                  width: 300,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.noAccount,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () {
                              context.go(AppRouter.registerPath);
                            },
                            style: ButtonStyle(
                              overlayColor:
                                  WidgetStateProperty.resolveWith<Color?>(
                                (Set<WidgetState> states) {
                                  return Colors.transparent; // No splash color
                                },
                              ),
                              padding: WidgetStateProperty.all<EdgeInsets>(
                                  const EdgeInsets.symmetric(horizontal: 2.0)),
                              // OR Use NoSplash.splashFactory to remove splash effect altogether
                              splashFactory: NoSplash.splashFactory,
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.registerAccount,
                              style: const TextStyle(
                                color: OnepieceColors.fancyBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          context.go(AppRouter.retrievePassword);
                        },
                        style: ButtonStyle(
                          overlayColor: WidgetStateProperty.resolveWith<Color?>(
                            (Set<WidgetState> states) {
                              return Colors.transparent; // No splash color
                            },
                          ),
                          padding: WidgetStateProperty.all<EdgeInsets>(
                              const EdgeInsets.symmetric(horizontal: 2.0)),
                          // OR Use NoSplash.splashFactory to remove splash effect altogether
                          splashFactory: NoSplash.splashFactory,
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.forgotPassword,
                          style: const TextStyle(
                            color: OnepieceColors.fancyBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Container(
                  height: 40,
                ),
              ],
            ),
          ),
        ));
  }

  Future<void> _login() async {
    // read inputs (safe)
    final email = emailController.text.trim();
    final password = passwordController.text;

    // read context-only values synchronously BEFORE async gap if they won't change
    final locale = Localizations.localeOf(context);

    final request = LoginRequest(email: email, password: password);

    try {
      final LoginResponse? response = await getIt<UserDao>().login(request);
      if (response == null) return;

      if (response.verification == null) {
        await saveUserCredentials(email, password);

        // Ensure still mounted, then perform navigation using current context synchronously.
        if (!mounted) return;
        _route(response.user!, response.accessToken!, context);
        context.read<WebSocketService>().connect(response.user!.id);
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
      if (loginResponse!.verification == null) {
        if (!mounted) return;
        _route(loginResponse.user!, loginResponse.accessToken!, context);
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

  void _route(User user, String token, BuildContext context) {
    // init apis with tokens
    ApiInitializer.initAuthInfo(token);
    ResourcePermissionManager.updateUserCache(user);
    context.goNamed(
      'characters',
    );
  }

  Future<void> saveUserCredentials(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('password', password);
  }

  Future<Map<String, String>> getUserCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? '';
    final password = prefs.getString('password') ?? '';
    return {'username': username, 'password': password};
  }
}
