import 'dart:typed_data';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/components/image_lazy_loader.dart';
import 'package:one_piece_battles_flutter/repository/issue_dao.dart';
import 'package:openapi/api.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../app_router.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../utils/base64_helper.dart';
import '../../utils/image_helper.dart';

class IssueDetailView extends StatefulWidget {
  final String issueId;
  const IssueDetailView({super.key, required this.issueId});

  @override
  State<IssueDetailView> createState() => _IssueDetailViewState();
}

class _IssueDetailViewState extends State<IssueDetailView> {
  late IssueFullView issue;
  bool _issueStatusEditable = false;
  IssueStatus? _selectedIssueStatus;
  _loadData() {
    return getIt<IssueDao>()
        .getIssueFullView(GetIssueFullViewRequest(id: widget.issueId));
  }

  _prepareData(IssueFullView issueFullView) {
    issue = issueFullView;
    _selectedIssueStatus = issue.issueStatus!;
  }

  @override
  Widget build(BuildContext context) {
    Map<IssueType, String> issueTypeToDisplayValue = <IssueType, String>{
      IssueType.OTHER: AppLocalizations.of(context)!.otherType,
      IssueType.FEATURE_SUGGESTION:
          AppLocalizations.of(context)!.featureSuggestion,
      IssueType.BUG_REPORT: AppLocalizations.of(context)!.bugReport,
    };
    Map<IssueStatus, String> issueStatusToDisplayValue = <IssueStatus, String>{
      IssueStatus.CREATED: AppLocalizations.of(context)!.statusCreated,
      IssueStatus.IN_PROGRESS: AppLocalizations.of(context)!.statusInProgress,
      IssueStatus.RESOLVED: AppLocalizations.of(context)!.statusResolved,
      IssueStatus.REVOKED: AppLocalizations.of(context)!.statusRevoked,
      IssueStatus.BACKLOGGED: AppLocalizations.of(context)!.statusBackLogged,
    };
    return FutureBuilder(
      future: _loadData(),
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          _prepareData(snapshot.data);
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    AppLocalizations.of(context)!.creator,
                    style: OnepieceFonts.headerStyle,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InkWell(
                    onTap: () {
                      context.goNamed('userDetails',
                          extra: issue.issueCreator!.id,
                          pathParameters: {
                            'name': issue.issueCreator!.nickname
                          });
                    },
                    child: ImageLazyLoader(
                        key: UniqueKey(),
                        uriProvider: () => issue.issueCreator!.imageUri!,
                        width: 100,
                        borderWidth: 3,
                        borderRadios: 100),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 0, 15),
                  child: Text(
                    AppLocalizations.of(context)!.nickname,
                    style: OnepieceFonts.contentStyle,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 0, 15),
                  child: Text(
                    issue.issueCreator!.nickname,
                    style: OnepieceFonts.fancyBlueHintFont,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 0, 15),
                  child: Text(
                    AppLocalizations.of(context)!.email,
                    style: OnepieceFonts.contentStyle,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 0, 15),
                  child: Text(
                    issue.issueCreator!.username,
                    style: OnepieceFonts.fancyBlueHintFont,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 3.0),
                  child: Divider(
                    color: Colors.grey,
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    AppLocalizations.of(context)!.issueDetail,
                    style: OnepieceFonts.headerStyle,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    issueTypeToDisplayValue[issue.issueType]!,
                    style: OnepieceFonts.fancyBlueSmallTitle,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: StatefulBuilder(builder: (context, basicState) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton2(
                              isExpanded: true,
                              value: _selectedIssueStatus,
                              hint: Text(
                                AppLocalizations.of(context)!.groupCategory,
                                style: OnepieceFonts.dropDownItemStyle,
                              ),
                              onChanged: !_issueStatusEditable
                                  ? null
                                  : (value) {
                                      basicState(() {
                                        _selectedIssueStatus =
                                            value! as IssueStatus;
                                      });
                                    },
                              selectedItemBuilder: (context) {
                                return IssueStatus.values.map(
                                  (item) {
                                    return Container(
                                      alignment: AlignmentDirectional.center,
                                      child: Text(
                                        issueStatusToDisplayValue[
                                            _selectedIssueStatus]!,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    );
                                  },
                                ).toList();
                              },
                              buttonStyleData: ButtonStyleData(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  height: 34,
                                  width: 210,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    color: OnepieceColors.menuBackgroundColor,
                                  )),
                              menuItemStyleData: const MenuItemStyleData(
                                height: 35,
                              ),
                              items: IssueStatus.values
                                  .map((IssueStatus issueStatus) {
                                return DropdownMenuItem<IssueStatus>(
                                  value: issueStatus,
                                  child: Text(
                                    issueStatusToDisplayValue[issueStatus]!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        Tooltip(
                          message: _issueStatusEditable
                              ? AppLocalizations.of(context)!.submitForm
                              : AppLocalizations.of(context)!.editHint,
                          child: InkWell(
                            hoverColor: Colors.white,
                            onTap: () {
                              basicState(() {
                                _issueStatusEditable = !_issueStatusEditable;
                                if (!_issueStatusEditable) {
                                  BatchUpdateIssueRequest request =
                                      BatchUpdateIssueRequest(updatedIssues: [
                                    Issue(
                                        id: issue.id,
                                        issueStatus: _selectedIssueStatus)
                                  ]);
                                  getIt<IssueDao>()
                                      .batchUpdateIssue(request)
                                      .then((value) => setState(() {}));
                                }
                              });
                            },
                            child: SizedBox(
                                width: 30,
                                height: 30,
                                child: !_issueStatusEditable
                                    ? ImageHelper.getSvgIconWithColor(
                                        'images/svgs/edit.svg',
                                        150,
                                        150,
                                        OnepieceColors.fancyBlue)
                                    : ImageHelper.getSvgIconWithColor(
                                        'images/svgs/check.svg',
                                        150,
                                        150,
                                        OnepieceColors.fancyBlue)),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    width: 800,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: OnepieceColors.fancyBlue,
                        width: 3, // Width of the border
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            issue.issueHeader!,
                            style: OnepieceFonts.smallHeaderStyle,
                          ),
                          Text(
                            issue.issueDescription!,
                            style: OnepieceFonts.contentStyle,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return Center(
            child: Text(
              AppLocalizations.of(context)!.loading,
              style: OnepieceFonts.loadingFont,
            ),
          );
        }
      },
    );
  }
}
