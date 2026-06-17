import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/popup/onepiece_alert.dart';
import 'package:one_piece_battles_flutter/repository/email_dao.dart';
import 'package:one_piece_battles_flutter/repository/user_dao.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:openapi/api.dart';
import 'components/icp.dart';
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

  final TextEditingController emailController = TextEditingController(text: '');

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmedPasswordController =
      TextEditingController();
  final TextEditingController verificationCodeController =
      TextEditingController();

  double _formWidth(BuildContext context) =>
      MediaQuery.of(context).size.width > 400
          ? 340.0
          : MediaQuery.of(context).size.width - 60;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmedPasswordController.dispose();
    verificationCodeController.dispose();
    super.dispose();
  }

  void _updateSendEnabled() {
    setState(() {
      _verificationCodeButtonEnabled = emailController.text.trim().isNotEmpty;
    });
  }

  void _updateResetEnabled() {
    setState(() {
      _buttonEnabled = verificationCodeController.text.trim().isNotEmpty &&
          passwordController.text.trim().isNotEmpty &&
          confirmedPasswordController.text.trim().isNotEmpty;
    });
  }

  void _submitPrimaryAction() {
    if (!verificationCodeSent && _verificationCodeButtonEnabled) {
      _sendVerificationCode();
      return;
    }
    if (verificationCodeSent && _buttonEnabled) {
      _updatePassword();
    }
  }

  Future<void> _sendVerificationCode() async {
    final alertHint = AppLocalizations.of(context)!.hint;
    final showAlert = OnepieceAlert.createAlertShower(context);
    final value = await getIt<EmailDao>().sendRetrievalEmail(
      PasswordRetrievalRequest(
        email: emailController.text.trim(),
        locale: I18nHelper.convertToOnepieceLocale(getIt<Locale>()),
      ),
    );
    if (!mounted || value == null) return;
    showAlert(
        alertHint, I18nHelper.getDisplayNameFromI18n(value.notification!));
    setState(() {
      if (value.result!) {
        verificationCodeSent = true;
      }
    });
  }

  Future<void> _updatePassword() async {
    final alertHint = AppLocalizations.of(context)!.hint;
    final showAlert = OnepieceAlert.createAlertShower(context);
    final router = GoRouter.of(context);
    final preCapturedLocale = Localizations.localeOf(context);
    try {
      final value = await getIt<UserDao>().updatePassword(
        UpdatePasswordRequest(
          username: emailController.text.trim(),
          password: passwordController.text.trim(),
          confirmedPassword: confirmedPasswordController.text.trim(),
          verificationCode: verificationCodeController.text.trim(),
        ),
      );
      if (value == null || !mounted) return;
      showAlert(
          alertHint, I18nHelper.getDisplayNameFromI18n(value.notification!));
      if (value.result! && mounted) {
        final loginValue = await getIt<UserDao>().login(
          LoginRequest(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          ),
        );
        if (loginValue == null || !mounted) return;
        if (loginValue.verification == null) {
          ApiInitializer.initAuthInfo(loginValue.accessToken!);
          ResourcePermissionManager.updateUserCache(loginValue.user!);
          router.goNamed(
            'userHome',
            extra: loginValue.user!.id,
            pathParameters: {'name': loginValue.user!.nickname},
          );
        } else {
          if (!mounted) return;
          setState(() {
            verificationI18n = loginValue.verification;
            verificationMessage = I18nHelper.getDisplayNameFromI18nByLocale(
                verificationI18n, preCapturedLocale);
          });
        }
      }
    } catch (e) {
      // Error is surfaced by backend notifications when available.
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): _submitPrimaryAction,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          bottomNavigationBar: const ICP(),
          backgroundColor: const Color(0xffeef1f5),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight - 40),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.topRight,
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
                              onChanged: (b) {
                                setState(() {
                                  _tabTextIndexSelected =
                                      _tabTextIndexSelected == 0 ? 1 : 0;
                                  final locale = _tabTextIndexSelected == 0
                                      ? locales.first
                                      : locales.last;
                                  MyApp.setLocale(context, locale);
                                  verificationMessage =
                                      I18nHelper.getDisplayNameFromI18nByLocale(
                                          verificationI18n, locale);
                                });
                              },
                              styleBuilder: (b) => const ToggleStyle(
                                  indicatorColor: OnepieceColors.fancyBlue),
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
                        const Spacer(),
                        Card(
                          elevation: 8,
                          shadowColor: Colors.black.withValues(alpha: 0.12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 400),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Image(
                                    image: AssetImage(PathConstants.luffyFlag),
                                    height: 92,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    AppLocalizations.of(context)!
                                        .retrievePassword,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                        color: OnepieceColors.fancyBlue),
                                  ),
                                  const SizedBox(height: 28),
                                  if (!verificationCodeSent)
                                    _getSendVerificationCode(context),
                                  if (verificationCodeSent)
                                    _getVerifyVerificationCode(context),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _getSendVerificationCode(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: _formWidth(context),
          child: TextField(
            onChanged: (value) => _updateSendEnabled(),
            autofocus: true,
            controller: emailController,
            decoration: InputDecoration(
                labelText: AppLocalizations.of(context)?.emailAddress,
                prefixIcon: const Icon(Icons.email)),
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        SizedBox(
          width: _formWidth(context),
          child: ElevatedButton(
            autofocus: true,
            onPressed:
                !_verificationCodeButtonEnabled ? null : _sendVerificationCode,
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
          width: _formWidth(context),
          child: TextFormField(
            onChanged: (value) => _updateResetEnabled(),
            controller: passwordController,
            keyboardType: TextInputType.text,
            obscureText: _isPasswordHidden,
            decoration: InputDecoration(
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
          width: _formWidth(context),
          child: TextFormField(
            onChanged: (value) => _updateResetEnabled(),
            controller: confirmedPasswordController,
            keyboardType: TextInputType.text,
            obscureText: _isConfirmedPasswordHidden,
            decoration: InputDecoration(
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
          width: _formWidth(context),
          child: TextFormField(
            onChanged: (value) => _updateResetEnabled(),
            controller: verificationCodeController,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
                labelText: AppLocalizations.of(context)?.verificationCode,
                prefixIcon: Icon(
                  Icons.verified,
                  color: Theme.of(context).primaryColorDark,
                )),
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        SizedBox(
          width: _formWidth(context),
          child: ElevatedButton(
            autofocus: true,
            onPressed: !_buttonEnabled ? null : _updatePassword,
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
}
