import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_toggle_tab/flutter_toggle_tab.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/popup/onepiece_alert.dart';
import 'package:one_piece_battles_flutter/repository/user_dao.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:openapi/api.dart';
import 'config/api_initializer.dart';
import 'config/resource_permission_manager.dart';
import 'constants/button_style.dart';
import 'constants/onepiece_colors.dart';
import 'constants/path_constants.dart';
import 'main.dart';

GetIt getIt = GetIt.instance;
const locales = [Locale('zh', 'CN'), Locale('en', 'US')];

class RetrievePassword extends StatefulWidget {
  const RetrievePassword({super.key});

  @override
  State<RetrievePassword> createState() => _RetrievePasswordState();
}

class _RetrievePasswordState extends State<RetrievePassword> {
  var _tabTextIndexSelected =
      I18nHelper.convertToOnepieceLocale(getIt<Locale>()).toString() ==
              (OnepieceLocale.zhCN.toString())
          ? 0
          : 1;
  String verificationMessage = "";
  I18nText? verificationI18n = I18nText();
  bool verificationCodeSent = false;
  bool _verificationCodeButtonEnabled = false;
  bool _buttonEnabled = false;
  bool _isPasswordHidden = true;
  bool _isConfirmedPasswordHidden = true;

  TextEditingController emailController =
      TextEditingController(text: 'zhangyichiwind@163.com');

  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmedPasswordController = TextEditingController();
  TextEditingController verificationCodeController = TextEditingController();
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
                    OnepieceColors.fancyBlue,
                    OnepieceColors.fancyBlue,
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
                      verificationMessage =
                          I18nHelper.getDisplayNameFromI18nByLocale(
                              verificationI18n, locale);
                    });
                  },
                  selectedTextStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                  unSelectedTextStyle: const TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                  unSelectedBackgroundColors: const [
                    Color.fromARGB(255, 182, 180, 180)
                  ],
                  marginSelected: const EdgeInsets.all(3),
                  selectedIndex: _tabTextIndexSelected,
                  // isScroll: true,
                )),
          ),
          const SizedBox(height: 150),
          const Image(
            image: AssetImage(PathConstants.luffyFlag),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: Text(
              AppLocalizations.of(context)!.retrievePassword,
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
          if (!verificationCodeSent) _getSendVerificationCode(context),
          if (verificationCodeSent) _getVerifyVerificationCode(context)
        ],
      ),
    );
  }

  Widget _getSendVerificationCode(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 300,
          child: TextField(
            onChanged: (value) {
              setState(() {
                if (emailController.text != "") {
                  _verificationCodeButtonEnabled = true;
                } else {
                  _verificationCodeButtonEnabled = false;
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
          child: ElevatedButton(
            autofocus: true,
            onPressed: !_verificationCodeButtonEnabled
                ? null
                : () {
                    getIt<UserDao>()
                        .sendRetrievalEmail(PasswordRetrievalRequest(
                            email: emailController.text,
                            locale: I18nHelper.convertToOnepieceLocale(
                                getIt<Locale>())))
                        .then((value) {
                      OnepieceAlert.getBasicAlertDialogFunc(
                          context,
                          AppLocalizations.of(context)!.hint,
                          I18nHelper.getDisplayNameFromI18n(
                              value!.notification!));
                      setState(() {
                        if (value.result!) {
                          verificationCodeSent = true;
                        }
                      });
                    });
                  },
            style: OnepieceButtonStyle.getDefaultStyle(),
            child: Text(
              AppLocalizations.of(context)!.sendEmail,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 17),
            ),
          ),
        ),
      ],
    );
  }

  Widget _getVerifyVerificationCode(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(
          width: 300,
          child: TextFormField(
            onChanged: (value) {
              setState(() {
                if (verificationCodeController.text != "" &&
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
                hintText: AppLocalizations.of(context)?.registerPasswordHint,
                labelText: AppLocalizations.of(context)?.registerPasswordHint,
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordHidden ? Icons.visibility_off : Icons.visibility,
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
                if (verificationCodeController.text != "" &&
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
                hintText: AppLocalizations.of(context)?.registerPasswordHint2,
                labelText: AppLocalizations.of(context)?.registerPasswordHint2,
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
                      _isConfirmedPasswordHidden = !_isConfirmedPasswordHidden;
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
                if (verificationCodeController.text != "" &&
                    passwordController.text != "" &&
                    confirmedPasswordController.text != "") {
                  _buttonEnabled = true;
                } else {
                  _buttonEnabled = false;
                }
              });
            },
            controller: verificationCodeController,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)?.verificationCode,
              labelText: AppLocalizations.of(context)?.verificationCode,
              prefixIcon: Icon(
                Icons.verified,
                color: Theme.of(context).primaryColorDark,
              )
            ),
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        SizedBox(
          width: 300,
          child: ElevatedButton(
            autofocus: true,
            onPressed: !_buttonEnabled
                ? null
                : () {
                    UpdatePasswordRequest request = UpdatePasswordRequest(
                        username: emailController.text,
                        password: passwordController.text,
                        confirmedPassword: confirmedPasswordController.text,
                        verificationCode: verificationCodeController.text);
                    getIt<UserDao>().updatePassword(request).then((value) {
                      OnepieceAlert.getBasicAlertDialogFunc(
                          context,
                          AppLocalizations.of(context)!.hint,
                          I18nHelper.getDisplayNameFromI18n(
                              value!.notification!));
                      if (value.result!) {
                        LoginRequest loginRequest = LoginRequest(
                            email: emailController.text,
                            password: passwordController.text);
                        getIt<UserDao>().login(loginRequest).then((value) {
                          if (value!.verification == null) {
                            _route(value.user!, value.accessToken!, context);
                          } else {
                            setState(() {
                              verificationI18n = value.verification;
                              Locale myLocale = Localizations.localeOf(context);
                              verificationMessage =
                                  I18nHelper.getDisplayNameFromI18nByLocale(
                                      verificationI18n, myLocale);
                            });
                          }
                        });
                      }
                    });
                  },
            style: OnepieceButtonStyle.getDefaultStyle(),
            child: Text(
              AppLocalizations.of(context)!.updatePassword,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 17),
            ),
          ),
        ),
      ],
    );
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
