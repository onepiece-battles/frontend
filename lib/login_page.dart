import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
import 'components/icp.dart';
import 'constants/button_style.dart';
import 'constants/onepiece_colors.dart';

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
  TextEditingController emailController =
      TextEditingController(text: "onepiecebattles@163.com");
  TextEditingController passwordController = TextEditingController(text: "abc");
  Logger logger = Logger('_LoginPageState');

  @override
  Widget build(BuildContext context) {
    //todo(yichi): add keyboard listener
    return Scaffold(
      bottomNavigationBar: const ICP(),
      backgroundColor: Colors.grey[300],
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            const SizedBox(height: 150),
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
                onPressed: !_buttonEnabled ? null : () => _login(context),
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
                              MaterialStateProperty.resolveWith<Color?>(
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
    );
  }

  void _login(BuildContext context) {
    LoginRequest loginRequest = LoginRequest(
        email: emailController.text, password: passwordController.text);
    Future<LoginResponse?> loginResponse = getIt<UserDao>().login(loginRequest);
    loginResponse.then((value) {
      if (value!.verification == null) {
        _route(value.user!, value.accessToken!, context);
      } else {
        setState(() {
          verificationI18n = value.verification;
          Locale myLocale = Localizations.localeOf(context);
          verificationMessage = I18nHelper.getDisplayNameFromI18nByLocale(
              verificationI18n, myLocale);
        });
      }
    });
  }

  void _route(User user, String token, BuildContext context) {
    // init apis with tokens
    ApiInitializer.initAuthInfo(token);
    ResourcePermissionManager.updateUserCache(user);
    context.goNamed('userHome',
        extra: getIt<User>().id,
        pathParameters: {'name': getIt<User>().nickname});
  }
}
