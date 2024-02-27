import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_toggle_tab/flutter_toggle_tab.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/app_router.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:openapi/api.dart';

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

  TextEditingController emailController =
      TextEditingController(text: 'zhangyichiwind@163.com');
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
    return Column();
  }

  Widget _getVerifyVerificationCode(BuildContext context) {
    return Column();
  }
}
