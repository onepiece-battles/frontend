import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/constants/button_style.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:one_piece_battles_flutter/repository/user_dao.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:openapi/api.dart';
import 'package:go_router/go_router.dart';
import '../constants/onepiece_fonts.dart';

GetIt getIt = GetIt.instance;

class EmailVerification extends StatefulWidget {
  final String userId;
  final String email;

  const EmailVerification({Key? key, required this.userId, required this.email})
      : super(key: key);

  @override
  State<EmailVerification> createState() => _EmailVerificationState();
}

class _EmailVerificationState extends State<EmailVerification> {
  TextEditingController verificationCode = TextEditingController();
  bool verificationCodeSent = false;
  bool verificationSuccess = false;
  String verificationMessage = "";

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 600,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 50, 0, 20),
            child: Text(
              AppLocalizations.of(context)!.emailVerification,
              style: OnepieceFonts.headerStyle,
            ),
          ),
          if (!verificationSuccess)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 120,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    AppLocalizations.of(context)!.emailSent,
                    style: OnepieceFonts.contentStylePass,
                  ),
                )
              ],
            ),
          if (!verificationSuccess)
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 30, 30, 0),
              child: SizedBox(
                width: 500,
                child: TextFormField(
                  controller: verificationCode,
                  onChanged: (value) {},
                  decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.verificationCode,
                      contentPadding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        borderSide: BorderSide(
                            color: OnepieceColors.fancyBlue, width: 2.0),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        borderSide: BorderSide(
                            color: OnepieceColors.fancyBlue, width: 2.0),
                      ),
                      disabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        borderSide: BorderSide(
                            color: OnepieceColors.fancyBlue, width: 2.0),
                      )),
                ),
              ),
            ),
          if (!verificationSuccess)
            Padding(
              padding: const EdgeInsets.only(bottom: 2.0),
              child: Text(
                verificationMessage,
                style: OnepieceFonts.contentStyleAlert,
              ),
            ),
          if (!verificationSuccess)
            Padding(
              padding: const EdgeInsets.only(bottom: 30.0),
              child: SizedBox(
                  width: 500,
                  child: ElevatedButton(
                    onPressed: () {
                      getIt<UserDao>()
                          .verifyEmail(VerifyByEmailCodeRequest(
                              userId: widget.userId,
                              email: widget.email,
                              verificationCode: verificationCode.text.trim()))
                          .then((value) => {
                                setState(() {
                                  verificationCodeSent = true;
                                  verificationSuccess = value!.verifyResult!;
                                  verificationMessage =
                                      I18nHelper.getDisplayNameFromI18n(
                                          value.verifyMessage);
                                })
                              });
                    },
                    style: OnepieceButtonStyle.getDefaultStyle(),
                    child: Text(AppLocalizations.of(context)!.submitForm),
                  )),
            ),
          if (verificationSuccess)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 120,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    verificationMessage,
                    style: OnepieceFonts.contentStylePass,
                  ),
                )
              ],
            ),
          if (verificationSuccess)
            const Divider(
              height: 10,
              thickness: 1,
            ),
          if (verificationSuccess)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                  child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.pushReplacementNamed('userProfile',
                            extra: getIt<User>().id,
                            pathParameters: {'name': getIt<User>().nickname});
                      },
                      style: OnepieceButtonStyle.getDefaultStyle(),
                      child: Text(AppLocalizations.of(context)!.confirm)),
                )
              ],
            )
        ],
      ),
    );
  }
}
