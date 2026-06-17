import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:one_piece_battles_flutter/l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/repository/user_dao.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:openapi/api.dart';

GetIt getIt = GetIt.instance;

class EmailVerification extends StatefulWidget {
  final String userId;
  final String email;

  const EmailVerification({
    super.key,
    required this.userId,
    required this.email,
  });

  @override
  State<EmailVerification> createState() => _EmailVerificationState();
}

class _EmailVerificationState extends State<EmailVerification> {
  final TextEditingController verificationCode = TextEditingController();
  bool verificationSuccess = false;
  bool isVerifying = false;
  String verificationMessage = "";

  @override
  void dispose() {
    verificationCode.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = verificationCode.text.trim();
    if (code.isEmpty || isVerifying) return;

    setState(() => isVerifying = true);
    try {
      final value = await getIt<UserDao>().verifyEmail(
        VerifyByEmailCodeRequest(
          userId: widget.userId,
          email: widget.email,
          verificationCode: code,
        ),
      );
      if (!mounted) return;
      setState(() {
        verificationSuccess = value?.verifyResult ?? false;
        verificationMessage =
            I18nHelper.getDisplayNameFromI18n(value?.verifyMessage);
      });
    } catch (error) {
      debugPrint("Error verifying email: $error");
      if (!mounted) return;
      setState(() {
        verificationSuccess = false;
        verificationMessage = AppLocalizations.of(context)!.alert;
      });
    } finally {
      if (mounted) {
        setState(() => isVerifying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);
    final isNarrow = size.width < 520;
    final maxWidth = isNarrow ? size.width - 32 : 480.0;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: size.height - 48,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isNarrow ? 16 : 22,
            isNarrow ? 16 : 20,
            isNarrow ? 16 : 22,
            isNarrow ? 14 : 18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                          OnepieceColors.liteFancyBlue.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      verificationSuccess
                          ? Icons.verified_outlined
                          : Icons.mark_email_read_outlined,
                      color: verificationSuccess
                          ? OnepieceColors.fancyGreen
                          : OnepieceColors.fancyBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.emailVerification,
                          style: OnepieceFonts.headerStyle.copyWith(
                            fontSize: isNarrow ? 17 : 19,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: OnepieceFonts.smallContentStyle.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints.tightFor(width: 32, height: 32),
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close,
                        size: 19, color: OnepieceColors.fancyBlue),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: OnepieceColors.liteFancyGreen.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        OnepieceColors.menuHoverColor.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      verificationSuccess
                          ? Icons.check_circle_outline
                          : Icons.outgoing_mail,
                      color: verificationSuccess
                          ? OnepieceColors.fancyGreen
                          : OnepieceColors.fancyBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        verificationSuccess
                            ? verificationMessage
                            : loc.emailSent,
                        style: OnepieceFonts.smallContentStyle.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!verificationSuccess) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: verificationCode,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _verify(),
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.pin_outlined, size: 19),
                    labelText: loc.verificationCode,
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: OnepieceColors.menuHoverColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: OnepieceColors.fancyGreen,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                if (verificationMessage.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    verificationMessage,
                    style: OnepieceFonts.contentStyleAlert,
                  ),
                ],
              ],
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!verificationSuccess)
                    TextButton(
                      onPressed: isVerifying
                          ? null
                          : () => Navigator.pop(context, false),
                      child: Text(loc.back),
                    ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: verificationSuccess
                          ? () => Navigator.pop(context, true)
                          : isVerifying
                              ? null
                              : _verify,
                      icon: isVerifying
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              verificationSuccess
                                  ? Icons.check
                                  : Icons.verified_outlined,
                              size: 16,
                            ),
                      label: Text(
                        verificationSuccess ? loc.confirm : loc.submitForm,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
