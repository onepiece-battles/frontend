import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:openapi/api.dart';

class CreateFeedbackView extends StatefulWidget {
  const CreateFeedbackView({super.key});

  @override
  State<CreateFeedbackView> createState() => _CreateFeedbackViewState();
}

class _CreateFeedbackViewState extends State<CreateFeedbackView> {
  IssueType selectedIssueType = IssueType.BUG_REPORT;
  TextEditingController headerController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      height: 400,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(3,3,3,10),
            child: Row(
              children: [
                const Text(
                  "issue type",
                  style: OnepieceFonts.dropDownItemStyle,
                ),
                DropdownButton2(
                  isExpanded: true,
                  value: selectedIssueType,
                  onChanged: (IssueType? value) {
                    setState(() {
                      selectedIssueType = value!;
                    });
                  },
                  buttonStyleData: const ButtonStyleData(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    height: 40,
                    width: 240,
                  ),
                  menuItemStyleData: const MenuItemStyleData(
                    height: 40,
                  ),
                  items: IssueType.values
                      .toList()
                      .map((IssueType issueType) => DropdownMenuItem<IssueType>(
                            value: issueType,
                            child: Text(
                              issueType.toString(),
                              style: OnepieceFonts.dropDownItemStyle,
                            ),
                          ))
                      .toList(),
                ),
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
              decoration: InputDecoration(
                labelText: "title",
                hintText: "please type in title",
                suffixIcon: IconButton(
                  onPressed: () {
                    headerController.text = '';
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
              decoration: const InputDecoration(
                labelText: "content",
                hintText: "please describe this issue",
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(3, 10,3,3),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 3, 0),
                  child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(AppLocalizations.of(context)!.cancelPopUp)),
                ),
                ElevatedButton(
                    onPressed: () {},
                    child: Text(AppLocalizations.of(context)!.submitForm))
              ],
            ),
          )
        ],
      ),
    );
  }
}
