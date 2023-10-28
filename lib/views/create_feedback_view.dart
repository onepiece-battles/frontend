import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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

class CreateFeedbackView extends StatefulWidget {
  const CreateFeedbackView({super.key});

  @override
  State<CreateFeedbackView> createState() => _CreateFeedbackViewState();
}

class _CreateFeedbackViewState extends State<CreateFeedbackView> {
  IssueType selectedIssueType = IssueType.BUG_REPORT;
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

    return SizedBox(
      width: 400,
      height: 430,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(3, 3, 3, 25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                  child: SizedBox(
                      height: 40,
                      width: 100,
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          AppLocalizations.of(context)!.issueType,
                          style: OnepieceFonts.contentStyle,
                        ),
                      )),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton2(
                    isExpanded: true,
                    value: selectedIssueType,
                    onChanged: (IssueType? value) {
                      setState(() {
                        selectedIssueType = value!;
                      });
                    },
                    buttonStyleData: ButtonStyleData(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: OnepieceColors.menuBackgroundColor),
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
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(3.0),
            child: TextFormField(
              maxLines: 1,
              controller: headerController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              maxLength: 10,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              onChanged: (value) {
                _calculateButtonCondition();
              },
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.feedbackTitle,
                hintText: AppLocalizations.of(context)!.feedbackTitleHint,
                suffixIcon: IconButton(
                  onPressed: () {
                    headerController.text = '';
                    _calculateButtonCondition();
                  },
                  icon: const Icon(Icons.cancel),
                  splashRadius: 0.1,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(3.0),
            child: TextFormField(
              maxLines: 10,
              controller: descriptionController,
              onChanged: (value) {
                _calculateButtonCondition();
              },
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.feedbackContent,
                hintText: AppLocalizations.of(context)!.feedbackContentHint,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(3, 10, 3, 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 3, 0),
                  child: ElevatedButton(
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
                          onPressed: !_clearButtonEnabled
                              ? null
                              : () {
                                  headerController.text = '';
                                  descriptionController.text = '';
                                  _calculateButtonCondition();
                                },
                          child: Text(AppLocalizations.of(context)!.clearAll)),
                    ),
                    ElevatedButton(
                      onPressed: !_submitButtonEnabled
                          ? null
                          : () {
                              CreateIssueRequest createIssueRequest =
                                  CreateIssueRequest(
                                      issueHeader: headerController.text,
                                      issueDescription:
                                          descriptionController.text,
                                      issueStatus: IssueStatus.CREATED,
                                      issueType: selectedIssueType);
                              getIt<IssueDao>()
                                  .createIssue(createIssueRequest)
                                  .then((value) {
                                OnepieceAlert.getBasicAlertDialogFunc(
                                    context,
                                    AppLocalizations.of(context)!.hint,
                                    I18nHelper.getI18nByLocale2(
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
    );
  }

  void _calculateButtonCondition() {
    if (headerController.text.isNotEmpty &&
        descriptionController.text.isNotEmpty) {
      _submitButtonEnabled = true;
    } else {
      _submitButtonEnabled = false;
    }
    if (headerController.text.isNotEmpty ||
        descriptionController.text.isNotEmpty) {
      _clearButtonEnabled = true;
    } else {
      _clearButtonEnabled = false;
    }
    setState(() {});
  }
}
