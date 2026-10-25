import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:one_piece_battles_flutter/popup/onepiece_alert.dart';
import 'package:openapi/api.dart';

import '../repository/issue_dao.dart';
import '../utils/i18n_helper.dart';

GetIt getIt = GetIt.instance;

class CreateFeedbackPopup extends StatefulWidget {
  final ValueChanged<String>? onIssueCreated;

  const CreateFeedbackPopup({super.key, this.onIssueCreated});

  @override
  State<CreateFeedbackPopup> createState() => _CreateFeedbackPopupState();
}

class _CreateFeedbackPopupState extends State<CreateFeedbackPopup> {
  IssueType? selectedIssueType;
  final TextEditingController headerController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  bool _submitButtonEnabled = false;
  bool _clearButtonEnabled = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    headerController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<IssueType, String> issueToDisplayNameMap = {
      IssueType.BUG_REPORT: AppLocalizations.of(context)!.bugReport,
      IssueType.FEATURE_SUGGESTION:
          AppLocalizations.of(context)!.featureSuggestion,
      IssueType.OTHER: AppLocalizations.of(context)!.otherType
    };
    final mediaSize = MediaQuery.sizeOf(context);
    final dialogWidth = mediaSize.width < 520 ? mediaSize.width - 32 : 480.0;
    final maxDialogHeight = mediaSize.height - 64;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: dialogWidth,
        maxHeight: maxDialogHeight,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: OnepieceColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.feedback_outlined,
                    color: OnepieceColors.fancyBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      AppLocalizations.of(context)!.feedback,
                      style: OnepieceFonts.fancyBlueSmallTitle.copyWith(
                        fontSize: 20,
                        color: OnepieceColors.primaryLabel,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints.tightFor(width: 32, height: 32),
                  onPressed:
                      _isSubmitting ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _fieldLabel(AppLocalizations.of(context)!.issueType),
            const SizedBox(height: 6),
            _issueTypeDropdown(context, issueToDisplayNameMap),
            const SizedBox(height: 14),
            _fieldLabel(AppLocalizations.of(context)!.feedbackTitle),
            const SizedBox(height: 6),
            TextFormField(
              enabled: !_isSubmitting,
              maxLines: 1,
              controller: headerController,
              style: OnepieceFonts.smallContentStyle.copyWith(fontSize: 14),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              maxLength: 30,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              onChanged: (value) {
                _calculateButtonCondition();
              },
              decoration: _inputDecoration(
                context,
                hintText: AppLocalizations.of(context)!.feedbackTitleHint,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                constraints: const BoxConstraints(maxHeight: 54),
              ),
            ),
            const SizedBox(height: 8),
            _fieldLabel(AppLocalizations.of(context)!.feedbackContent),
            const SizedBox(height: 6),
            TextFormField(
              enabled: !_isSubmitting,
              minLines: 9,
              maxLines: 12,
              controller: descriptionController,
              onChanged: (value) {
                _calculateButtonCondition();
              },
              cursorHeight: 18,
              decoration: _inputDecoration(
                context,
                hintText: AppLocalizations.of(context)!.feedbackContentHint,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  child: Text(AppLocalizations.of(context)!.cancelPopUp),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: !_clearButtonEnabled || _isSubmitting
                      ? null
                      : () {
                          headerController.text = '';
                          descriptionController.text = '';
                          selectedIssueType = null;
                          _calculateButtonCondition();
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: OnepieceColors.fancyBlue,
                    side: const BorderSide(color: OnepieceColors.fancyBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context)!.clearAll),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: !_submitButtonEnabled || _isSubmitting
                      ? null
                      : _submitIssue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OnepieceColors.fancyBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(AppLocalizations.of(context)!.submitForm),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: OnepieceFonts.smallContentFancyBlueStyle.copyWith(
        fontWeight: FontWeight.w600,
        color: OnepieceColors.primaryLabel,
      ),
    );
  }

  Widget _issueTypeDropdown(
    BuildContext context,
    Map<IssueType, String> issueToDisplayNameMap,
  ) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<IssueType>(
        hint: Text(
          AppLocalizations.of(context)!.issueType,
          style: OnepieceFonts.smallContentStyle,
        ),
        isExpanded: true,
        value: selectedIssueType,
        onChanged: _isSubmitting
            ? null
            : (IssueType? value) {
                selectedIssueType = value;
                _calculateButtonCondition();
              },
        buttonStyleData: ButtonStyleData(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: OnepieceColors.separator),
            color: Colors.transparent,
          ),
          height: 36,
          width: double.infinity,
        ),
        iconStyleData: const IconStyleData(
          iconEnabledColor: OnepieceColors.fancyBlue,
        ),
        dropdownStyleData: DropdownStyleData(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
        ),
        menuItemStyleData: const MenuItemStyleData(height: 40),
        items: IssueType.values
            .map((IssueType issueType) => DropdownMenuItem<IssueType>(
                  value: issueType,
                  child: Text(
                    issueToDisplayNameMap[issueType]!,
                    style: OnepieceFonts.dropDownItemStyle,
                  ),
                ))
            .toList(),
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hintText,
    Widget? suffixIcon,
    BoxConstraints? constraints,
    EdgeInsetsGeometry contentPadding =
        const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
  }) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: contentPadding,
      constraints: constraints,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      hintText: hintText,
      hintStyle: OnepieceFonts.smallContentStyle.copyWith(
        color: Colors.black38,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(
          color: OnepieceColors.separator,
          width: 1.0,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(
          color: OnepieceColors.fancyBlue,
          width: 1.5,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(
          color: OnepieceColors.separator,
          width: 1.0,
        ),
      ),
      suffixIcon: suffixIcon,
    );
  }

  Future<void> _submitIssue() async {
    final alertHint = AppLocalizations.of(context)!.hint;
    final showAlert = OnepieceAlert.createAlertShower(context);
    setState(() => _isSubmitting = true);

    try {
      final createIssueRequest = CreateIssueRequest(
        issueHeader: headerController.text.trim(),
        issueDescription: descriptionController.text.trim(),
        issueStatus: IssueStatus.CREATED,
        issueType: selectedIssueType,
      );
      final value = await getIt<IssueDao>().createIssue(createIssueRequest);
      if (!mounted) return;
      Navigator.pop(context);
      widget.onIssueCreated?.call(
        I18nHelper.getDisplayNameFromI18n(value!.issueCreationResult),
      );
    } catch (_) {
      if (!mounted) return;
      showAlert(alertHint, AppLocalizations.of(context)!.battleStatusFailed);
      setState(() => _isSubmitting = false);
    }
  }

  void _calculateButtonCondition() {
    _submitButtonEnabled = headerController.text.trim().isNotEmpty &&
        descriptionController.text.trim().isNotEmpty &&
        selectedIssueType != null;
    _clearButtonEnabled = headerController.text.isNotEmpty ||
        descriptionController.text.isNotEmpty ||
        selectedIssueType != null;
    if (mounted) {
      setState(() {});
    }
  }
}
