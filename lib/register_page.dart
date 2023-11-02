import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_toggle_tab/flutter_toggle_tab.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/config/app_router.dart';
import 'package:one_piece_battles_flutter/repository/user_dao.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:openapi/api.dart';
import 'config/api_initializer.dart';
import 'config/resource_permission_manager.dart';
import 'constants/path_constants.dart';
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
  var _tabTextIndexSelected =  I18nHelper.convertToOnepieceLocale(getIt<Locale>()).toString() ==
      (OnepieceLocale.zhCN.toString())
      ? 0
      : 1;
  I18nText? verificationI18n = I18nText();
  UserDao userDao = UserDao.empty();
  bool _isPasswordHidden = true;
  bool _isConfirmedPasswordHidden = true;
  bool _buttonEnabled = false;
  String verificationMessage = "";
  TextEditingController userNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmedPasswordController = TextEditingController();
  TextEditingController organizationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
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
                      locale = localesMap.values.first;
                    } else {
                      locale = localesMap.values.last;
                    }
                    MyApp.setLocale(context, locale);
                    verificationMessage =
                        I18nHelper.getI18nByLocale(verificationI18n, locale);
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
                selectedIndex: _tabTextIndexSelected,
                marginSelected: const EdgeInsets.all(3),
                isScroll: false,
              ),
            ),
          ),
          const SizedBox(
            height: 50,
          ),
          const Image(
            image: AssetImage(PathConstants.loginLuffyImage),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.signUpHeadLine,
            style: const TextStyle(
                color: Colors.blue, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 90),
          SizedBox(
            width: 300,
            child: TextField(
              onChanged: (value) {
                setState(() {
                  if (userNameController.text != "" &&
                      emailController.text != "" &&
                      passwordController.text != "" &&
                      confirmedPasswordController.text != "" &&
                      organizationController.text != "") {
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
                hintText: AppLocalizations.of(context)?.userNameHint,
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
                  if (userNameController.text != "" &&
                      emailController.text != "" &&
                      passwordController.text != "" &&
                      confirmedPasswordController.text != "" &&
                      organizationController.text != "") {
                    _buttonEnabled = true;
                  } else {
                    _buttonEnabled = false;
                  }
                });
              },
              autofocus: true,
              controller: emailController,
              decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)?.emailAddress,
                  hintText: AppLocalizations.of(context)?.emailAddress,
                  prefixIcon: const Icon(Icons.email)),
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
                      passwordController.text != "" &&
                      confirmedPasswordController.text != "" &&
                      organizationController.text != "") {
                    _buttonEnabled = true;
                  } else {
                    _buttonEnabled = false;
                  }
                });
              },
              autofocus: true,
              controller: organizationController,
              decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)?.organization,
                  hintText: AppLocalizations.of(context)?.organization,
                  prefixIcon: const Icon(Icons.group)),
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
                      passwordController.text != "" &&
                      confirmedPasswordController.text != "" &&
                      organizationController.text != "") {
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
                  hintText: AppLocalizations.of(context)?.registerPasswordHint,
                  labelText: AppLocalizations.of(context)?.registerPasswordHint,
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
                  if (userNameController.text != "" &&
                      emailController.text != "" &&
                      passwordController.text != "" &&
                      confirmedPasswordController.text != "" &&
                      organizationController.text != "") {
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
                  hintText: AppLocalizations.of(context)?.registerPasswordHint2,
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
              onPressed: !_buttonEnabled
                  ? null
                  : () {
                      RegisterRequest request = RegisterRequest(
                          userName: userNameController.text,
                          email: emailController.text,
                          organization: organizationController.text,
                          password: passwordController.text,
                          confirmedPassword: confirmedPasswordController.text,
                      locale: I18nHelper.convertToOnepieceLocale(getIt<Locale>()));
                      Future<RegisterResponse?> response =
                          userDao.register(request);
                      response.then((value) => {
                            if (value!.registerResult)
                              {handleRegisterSuccess(context)}
                            else
                              {
                                setState(() {
                                  Locale myLocale =
                                      Localizations.localeOf(context);
                                  verificationMessage =
                                      I18nHelper.getI18nByLocale(
                                          value.verification, myLocale);
                                })
                              }
                          });
                    },
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
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              TextButton(
                onPressed: () {
                  context.go(AppRouter.loginPath);
                },
                child: Text(
                  AppLocalizations.of(context)!.backToLoginPage,
                  style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic),
                ),
              )
            ],
          ),
          const SizedBox(height: 30),
        ],
      )),
    );
  }

  void handleRegisterSuccess(BuildContext context) {
    LoginRequest loginRequest = LoginRequest(
        userName: userNameController.text,
        email: emailController.text,
        password: passwordController.text);
    Future<LoginResponse?> loginResponse = userDao.login(loginRequest);
    loginResponse.then((value) {
      ApiInitializer.initAuthInfo(value!.accessToken!);
      ResourcePermissionManager.setResourceOrder(value.user!);
      context.go(AppRouter.homePath);
    });
  }
}
