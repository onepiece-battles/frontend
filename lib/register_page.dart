import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/app_router.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:one_piece_battles_flutter/repository/user_dao.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:openapi/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'components/icp.dart';
import 'config/api_initializer.dart';
import 'config/resource_permission_manager.dart';
import 'constants/button_style.dart';
import 'constants/path_constants.dart';
import 'home_page.dart';
import 'main.dart';

GetIt getIt = GetIt.instance;
const Map<String, Locale> localesMap = {
  'zh_CN': Locale('zh', 'CN'),
  'en_US': Locale('en', 'US')
};

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  var _tabTextIndexSelected =
      I18nHelper.convertToOnepieceLocale(getIt<Locale>()).toString() ==
              (OnepieceLocale.zhCN.toString())
          ? 0
          : 1;
  I18nText? verificationI18n = I18nText();
  UserDao userDao = UserDao.empty();
  bool _isPasswordHidden = true;
  bool _isConfirmedPasswordHidden = true;
  bool _buttonEnabled = false;
  String verificationMessage = "";
  TextEditingController nicknameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmedPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const ICP(),
      backgroundColor: Colors.grey[300],
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SafeArea(
          child: Column(
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
                height: 50,
              ),
              const Image(
                image: AssetImage(PathConstants.luffyFlag),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.signUpHeadLine,
                style: const TextStyle(
                    color: OnepieceColors.fancyBlue,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 90),
              SizedBox(
                width: 300,
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      if (nicknameController.text != "" &&
                          usernameController.text != "" &&
                          passwordController.text != "" &&
                          confirmedPasswordController.text != "") {
                        _buttonEnabled = true;
                      } else {
                        _buttonEnabled = false;
                      }
                    });
                  },
                  controller: nicknameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)?.nickname,
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: 300,
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      if (nicknameController.text != "" &&
                          usernameController.text != "" &&
                          passwordController.text != "" &&
                          confirmedPasswordController.text != "") {
                        _buttonEnabled = true;
                      } else {
                        _buttonEnabled = false;
                      }
                    });
                  },
                  autofocus: true,
                  controller: usernameController,
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
                      if (nicknameController.text != "" &&
                          usernameController.text != "" &&
                          passwordController.text != "" &&
                          confirmedPasswordController.text != "") {
                        _buttonEnabled = true;
                      } else {
                        _buttonEnabled = false;
                      }
                    });
                  },
                  controller: passwordController,
                  keyboardType: TextInputType.text,
                  obscureText: _isPasswordHidden,
                  decoration: InputDecoration(
                      labelText:
                          AppLocalizations.of(context)?.registerPasswordHint,
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordHidden
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Theme.of(context).primaryColorDark,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordHidden = !_isPasswordHidden;
                          });
                        },
                      )),
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
                      if (nicknameController.text != "" &&
                          usernameController.text != "" &&
                          passwordController.text != "" &&
                          confirmedPasswordController.text != "") {
                        _buttonEnabled = true;
                      } else {
                        _buttonEnabled = false;
                      }
                    });
                  },
                  controller: confirmedPasswordController,
                  keyboardType: TextInputType.text,
                  obscureText: _isConfirmedPasswordHidden,
                  decoration: InputDecoration(
                      labelText:
                          AppLocalizations.of(context)?.registerPasswordHint2,
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmedPasswordHidden
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Theme.of(context).primaryColorDark,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmedPasswordHidden =
                                !_isConfirmedPasswordHidden;
                          });
                        },
                      )),
                ),
              ),
              Text(
                verificationMessage,
                style: const TextStyle(color: Colors.red, fontSize: 10),
              ),
              const SizedBox(
                height: 10,
              ),
              SizedBox(
                width: 300,
                child: ElevatedButton(
                  autofocus: true,
                  style: OnepieceButtonStyle.getDefaultStyle(),
                  onPressed: !_buttonEnabled ? null : () => _register(context),
                  child: Text(
                    AppLocalizations.of(context)!.signUp,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 17),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)!.accountCheck,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  TextButton(
                    onPressed: () {
                      context.go(AppRouter.loginPath);
                    },
                    style: ButtonStyle(
                      overlayColor: MaterialStateProperty.resolveWith<Color?>(
                        (Set<MaterialState> states) {
                          return Colors.transparent; // No splash color
                        },
                      ),
                      padding: MaterialStateProperty.all<EdgeInsets>(
                          const EdgeInsets.symmetric(horizontal: 2.0)),
                      // OR Use NoSplash.splashFactory to remove splash effect altogether
                      splashFactory: NoSplash.splashFactory,
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.backToLoginPage,
                      style: const TextStyle(
                          color: OnepieceColors.fancyBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _register(BuildContext context) {
    RegisterRequest request = RegisterRequest(
        nickname: nicknameController.text,
        username: usernameController.text,
        password: passwordController.text,
        confirmedPassword: confirmedPasswordController.text,
        locale: I18nHelper.convertToOnepieceLocale(getIt<Locale>()));
    Future<RegisterResponse?> response = userDao.register(request);
    response.then((value) => {
          if (value!.registerResult)
            {handleRegisterSuccess(context)}
          else
            {
              setState(() {
                Locale myLocale = Localizations.localeOf(context);
                verificationMessage = I18nHelper.getDisplayNameFromI18nByLocale(
                    value.verification, myLocale);
              })
            }
        });
  }

  void handleRegisterSuccess(BuildContext context) {
    LoginRequest loginRequest = LoginRequest(
        email: usernameController.text, password: passwordController.text);
    Future<LoginResponse?> loginResponse = userDao.login(loginRequest);
    loginResponse.then((value) {
      ApiInitializer.initAuthInfo(value!.accessToken!);
      ResourcePermissionManager.updateUserCache(value.user!);
      saveUserCredentials(usernameController.text, passwordController.text);
      context.goNamed('userHome',
          extra: getIt<User>().id,
          pathParameters: {'name': getIt<User>().nickname});
    });
  }

  Future<void> saveUserCredentials(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('password', password);
  }
}
