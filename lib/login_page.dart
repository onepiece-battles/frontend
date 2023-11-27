import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_toggle_tab/flutter_toggle_tab.dart';
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
import 'package:openapi/api.dart';

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
  bool _buttonEnabled = true;
  String verificationMessage = "";
  I18nText? verificationI18n = I18nText();
  TextEditingController userNameController = TextEditingController(text: 'Monkey John');
  TextEditingController emailController =
      TextEditingController(text: 'abc@gmail.com');
  TextEditingController passwordController = TextEditingController(text: 'abc');
  Logger logger = Logger('_LoginPageState');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Padding(
                padding: const EdgeInsets.all(30),
                child: FlutterToggleTab(
                  width: 4,
                  height: 30,
                  borderRadius: 20,
                  selectedBackgroundColors: const [
                    Color.fromARGB(255, 38, 151, 243),
                    Colors.blueAccent
                  ],
                  labels: const ["文", "EN"],
                  selectedLabelIndex: (index) {
                    setState(() {
                      _tabTextIndexSelected = index;
                      Locale locale;
                      if (index == 0) {
                        locale = locales.first;
                      } else {
                        locale = locales.last;
                      }
                      MyApp.setLocale(context, locale);
                      verificationMessage = I18nHelper.getI18nByLocale(
                          verificationI18n, locale);
                    });
                  },
                  selectedTextStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                  unSelectedTextStyle: const TextStyle(
                      color: Colors.black87,
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                  unSelectedBackgroundColors: const [
                    Color.fromARGB(255, 182, 180, 180)
                  ],
                  marginSelected: const EdgeInsets.all(3),
                  selectedIndex: _tabTextIndexSelected,
                  // isScroll: true,
                )),
          ),
          const SizedBox(height: 50),
          const Image(
            image: AssetImage(PathConstants.loginLuffyImage),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: Text(
              AppLocalizations.of(context)!.welcome,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.blue),
            ),
          ),
          const SizedBox(height: 90),
          SizedBox(
            width: 300,
            child: TextField(
              onChanged: (value) {
                setState(() {
                  if (userNameController.text != "" &&
                      emailController.text != "" &&
                      passwordController.text != "") {
                    _buttonEnabled = true;
                  } else {
                    _buttonEnabled = false;
                  }
                });
              },
              controller: userNameController,
              autofocus: true,
              decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)?.userNameLabel,
                  prefixIcon: const Icon(Icons.person)),
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
                  if (userNameController.text != "" &&
                      emailController.text != "" &&
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
                  if (userNameController.text != "" &&
                      emailController.text != "" &&
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
              onPressed: !_buttonEnabled
                  ? null
                  : () {
                      LoginRequest loginRequest = LoginRequest(
                          userName: userNameController.text,
                          email: emailController.text,
                          password: passwordController.text);
                      Future<LoginResponse?> loginResponse =
                          getIt<UserDao>().login(loginRequest);
                      loginResponse.then((value) {
                        if (value!.verification == null) {
                          _route(value.user!, value.accessToken!, context);
                        } else {
                          setState(() {
                            verificationI18n = value.verification;
                            Locale myLocale = Localizations.localeOf(context);
                            verificationMessage = I18nHelper.getI18nByLocale(
                                verificationI18n, myLocale);
                          });
                        }
                      });
                    },
              child: Text(
                AppLocalizations.of(context)!.signIn,
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
                AppLocalizations.of(context)!.noAccount,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  context.go(AppRouter.registerPath);
                },
                child: Text(
                  AppLocalizations.of(context)!.registerAccount,
                  style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  void _route(User user, String token, BuildContext context) {
    // init apis with tokens
    ApiInitializer.initAuthInfo(token);
    ResourcePermissionManager.updateUserCache(user);
    context.go(AppRouter.homePath);
  }
}
