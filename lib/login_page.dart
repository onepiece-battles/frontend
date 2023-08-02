import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_toggle_tab/flutter_toggle_tab.dart';
import 'package:one_piece_battles_flutter/constants/path_constants.dart';
import 'package:one_piece_battles_flutter/main.dart';
import 'package:one_piece_battles_flutter/repository/user_dao.dart';
import 'package:one_piece_battles_flutter/utils/I18n_helper.dart';
import 'package:openapi/api.dart';

const locales = [Locale('en', 'US'), Locale('zh', 'CN')];

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  var _tabTextIndexSelected = 1;
  bool _isHidden = true;
  bool _bottonEnabled = false;
  String verificationMessage = "";
  I18nText? verificationI18n = I18nText();
  UserDao userDao = UserDao();
  TextEditingController userNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: FlutterToggleTab(
                  width: 5,
                  height: 17,
                  borderRadius: 30,
                  selectedBackgroundColors: const [
                    Color.fromARGB(255, 38, 151, 243),
                    Colors.blueAccent
                  ],
                  labels: const ["A", "文"],
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
                  isScroll: false,
                ),
              ),
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
                      _bottonEnabled = true;
                    } else {
                      _bottonEnabled = false;
                    }
                  });
                },
                controller: userNameController,
                autofocus: true,
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)?.userNameLable,
                    hintText: AppLocalizations.of(context)?.userNameHint,
                    prefixIcon: const Icon(Icons.person)),
              ),
            ),
            SizedBox(
              width: 300,
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    if (userNameController.text != "" &&
                        emailController.text != "" &&
                        passwordController.text != "") {
                      _bottonEnabled = true;
                    } else {
                      _bottonEnabled = false;
                    }
                  });
                },
                controller: emailController,
                autofocus: true,
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)?.emailAddress,
                    hintText: AppLocalizations.of(context)?.emailAddress,
                    prefixIcon: const Icon(Icons.email)),
              ),
            ),
            SizedBox(
              width: 300,
              child: TextFormField(
                onChanged: (value) {
                  setState(() {
                    if (userNameController.text != "" &&
                        emailController.text != "" &&
                        passwordController.text != "") {
                      _bottonEnabled = true;
                    } else {
                      _bottonEnabled = false;
                    }
                  });
                },
                controller: passwordController,
                keyboardType: TextInputType.text,
                obscureText: _isHidden,
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)?.passwordLable,
                    hintText: AppLocalizations.of(context)?.passWordHint,
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
                    )),
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
                onPressed: !_bottonEnabled
                    ? null
                    : () {
                        LoginRequest loginRequest = LoginRequest(
                            userName: userNameController.text,
                            email: emailController.text,
                            password: passwordController.text);

                        Future<LoginResponse?> loginResponse =
                            userDao.login(loginRequest);

                        loginResponse.then((value) => {
                              if (value!.verification == null)
                                {Navigator.pushNamed(context, '/')}
                              else
                                {
                                  setState(() {
                                    verificationI18n = value.verification;
                                    Locale myLocale =
                                        Localizations.localeOf(context);
                                    verificationMessage =
                                        I18nHelper.getI18nByLocale(
                                            verificationI18n, myLocale);
                                  })
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
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
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
      ),
    );
  }
}
