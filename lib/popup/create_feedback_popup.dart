import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/constants/button_style.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:one_piece_battles_flutter/popup/onepiece_alert.dart';
import 'package:openapi/api.dart';

import '../repository/issue_dao.dart';
import '../utils/i18n_helper.dart';

GetIt getIt = GetIt.instance;

class CreateFeedbackPopup extends StatefulWidget {
  const CreateFeedbackPopup({super.key});

  @override
  State<CreateFeedbackPopup> createState() => _CreateFeedbackPopupState();
}

class _CreateFeedbackPopupState extends State<CreateFeedbackPopup> {
  IssueType? selectedIssueType;
  TextEditingController headerController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  bool _submitButtonEnabled = false;
  bool _clearButtonEnabled = false;

  @override
  Widget build(BuildContext context) {
    Map<IssueType, String> issueToDisplayNameMap = {
      IssueType.BUG_REPORT: AppLocalizations.of(context)!.bugReport,
      IssueType.FEATURE_SUGGESTION:
          AppLocalizations.of(context)!.featureSuggestion,
      IssueType.OTHER: AppLocalizations.of(context)!.otherType
    };
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: 400,
        height: 470,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 5, 5, 5),
                  child: Text(
                    AppLocalizations.of(context)!.feedback,
                    style: OnepieceFonts.fancyBlueSmallTitle,
                  ),
                ),
                Padding(
                    padding: const EdgeInsets.all(5),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton2<IssueType>(
                        hint: Text(AppLocalizations.of(context)!.issueType),
                        isExpanded: true,
                        value: selectedIssueType,
                        onChanged: (IssueType? value) {
                          setState(() {
                            selectedIssueType = value!;
                            _calculateButtonCondition();
                          });
                        },
                        buttonStyleData: ButtonStyleData(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: OnepieceColors.liteFancyBlue),
                          height: 40,
                          width: 240,
                        ),
                        menuItemStyleData: const MenuItemStyleData(
                          height: 40,
                        ),
                        items: IssueType.values
                            .toList()
                            .map((IssueType issueType) =>
                                DropdownMenuItem<IssueType>(
                                  value: issueType,
                                  child: Text(
                                    issueToDisplayNameMap[issueType]!,
                                    style: OnepieceFonts.dropDownItemStyle,
                                  ),
                                ))
                            .toList(),
                      ),
                    )),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: TextFormField(
                maxLines: 1,
                controller: headerController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                maxLength: 30,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                onChanged: (value) {
                  _calculateButtonCondition();
                },
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(15),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  hintText: AppLocalizations.of(context)!.feedbackTitleHint,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                    borderSide: const BorderSide(
                      color: OnepieceColors.fancyBlue,
                      width: 1.0,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                    borderSide: const BorderSide(
                      color: Colors.red,
                      width: 1.5,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                    borderSide: const BorderSide(
                      color: Colors.red,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                    borderSide: const BorderSide(
                      color: OnepieceColors.fancyBlue,
                      width: 1.5,
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 1.0,
                    ),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      headerController.text = '';
                      _calculateButtonCondition();
                    },
                    icon: Icon(
                      Icons.cancel,
                      color: headerController.text == ''
                          ? OnepieceColors.liteFancyBlue
                          : OnepieceColors.fancyBlue,
                    ),
                    splashRadius: 0.01,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: TextFormField(
                maxLines: 10,
                controller: descriptionController,
                onChanged: (value) {
                  _calculateButtonCondition();
                },
                cursorHeight: 18,
                decoration: InputDecoration(
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  contentPadding: const EdgeInsets.fromLTRB(10, 15, 10, 15),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                    borderSide: const BorderSide(
                      color: OnepieceColors.fancyBlue,
                      width: 1.0,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                    borderSide: const BorderSide(
                      color: Colors.red,
                      width: 1.5,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                    borderSide: const BorderSide(
                      color: Colors.red,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                    borderSide: const BorderSide(
                      color: OnepieceColors.fancyBlue,
                      width: 1.5,
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 1.0,
                    ),
                  ),
                  hintText: AppLocalizations.of(context)!.feedbackContentHint,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(5, 10, 5, 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 3, 0),
                    child: ElevatedButton(
                        style: OnepieceButtonStyle.getDefaultStyle(),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(AppLocalizations.of(context)!.cancelPopUp)),
                  ),
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 3, 0),
                        child: ElevatedButton(
                            style: OnepieceButtonStyle.getDefaultStyle(),
                            onPressed: !_clearButtonEnabled
                                ? null
                                : () {
                                    headerController.text = '';
                                    descriptionController.text = '';
                                    selectedIssueType = null;
                                    _calculateButtonCondition();
                                  },
                            child:
                                Text(AppLocalizations.of(context)!.clearAll)),
                      ),
                      ElevatedButton(
                        style: OnepieceButtonStyle.getDefaultStyle(),
                        onPressed: !_submitButtonEnabled
                            ? null
                            : () {
                                CreateIssueRequest createIssueRequest =
                                    CreateIssueRequest(
                                        issueHeader:
                                            headerController.text.trim(),
                                        issueDescription:
                                            descriptionController.text.trim(),
                                        issueStatus: IssueStatus.CREATED,
                                        issueType: selectedIssueType);
                                getIt<IssueDao>()
                                    .createIssue(createIssueRequest)
                                    .then((value) {
                                  OnepieceAlert.getBasicAlertDialogFunc(
                                      context,
                                      AppLocalizations.of(context)!.hint,
                                      I18nHelper.getDisplayNameFromI18n(
                                          value!.issueCreationResult));
                                });
                                headerController.text = '';
                                descriptionController.text = '';
                                _calculateButtonCondition();
                                Navigator.pop(context);
                              },
                        child: Text(AppLocalizations.of(context)!.submitForm),
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _calculateButtonCondition() {
    if (headerController.text.isNotEmpty &&
        descriptionController.text.isNotEmpty &&
        selectedIssueType != null) {
      _submitButtonEnabled = true;
    } else {
      _submitButtonEnabled = false;
    }
    if (headerController.text.isNotEmpty ||
        descriptionController.text.isNotEmpty ||
        selectedIssueType != null) {
      _clearButtonEnabled = true;
    } else {
      _clearButtonEnabled = false;
    }
    setState(() {});
  }
}
