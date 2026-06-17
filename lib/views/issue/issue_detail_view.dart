import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/components/image_lazy_loader.dart';
import 'package:one_piece_battles_flutter/repository/issue_dao.dart';
import 'package:openapi/api.dart';

import '../../app_router.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/image_helper.dart';
import '../../utils/responsive_breakpoints.dart';

class IssueDetailView extends StatefulWidget {
  final String issueId;

  const IssueDetailView({super.key, required this.issueId});

  @override
  State<IssueDetailView> createState() => _IssueDetailViewState();
}

class _IssueDetailViewState extends State<IssueDetailView> {
  late Future<IssueFullView?> _issueFuture;
  late IssueFullView issue;
  bool _issueStatusEditable = false;
  IssueStatus? _selectedIssueStatus;

  @override
  void initState() {
    super.initState();
    _issueFuture = _loadData();
  }

  @override
  void didUpdateWidget(covariant IssueDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.issueId != widget.issueId) {
      _issueStatusEditable = false;
      _issueFuture = _loadData();
    }
  }

  Future<IssueFullView?> _loadData() {
    return getIt<IssueDao>()
        .getIssueFullView(GetIssueFullViewRequest(id: widget.issueId));
  }

  void _prepareData(IssueFullView issueFullView) {
    issue = issueFullView;
    _selectedIssueStatus ??= issue.issueStatus!;
  }

  Map<IssueType, String> _issueTypeMap(BuildContext context) {
    return <IssueType, String>{
      IssueType.OTHER: AppLocalizations.of(context)!.otherType,
      IssueType.FEATURE_SUGGESTION:
          AppLocalizations.of(context)!.featureSuggestion,
      IssueType.BUG_REPORT: AppLocalizations.of(context)!.bugReport,
    };
  }

  Map<IssueStatus, String> _issueStatusMap(BuildContext context) {
    return <IssueStatus, String>{
      IssueStatus.CREATED: AppLocalizations.of(context)!.statusCreated,
      IssueStatus.IN_PROGRESS: AppLocalizations.of(context)!.statusInProgress,
      IssueStatus.RESOLVED: AppLocalizations.of(context)!.statusResolved,
      IssueStatus.REVOKED: AppLocalizations.of(context)!.statusRevoked,
      IssueStatus.BACKLOGGED: AppLocalizations.of(context)!.statusBackLogged,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<IssueFullView?>(
      future: _issueFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Center(
            child: Text(
              AppLocalizations.of(context)!.loading,
              style: OnepieceFonts.loadingFont,
            ),
          );
        }

        final issueData = snapshot.data;
        if (issueData == null) {
          return Center(
            child: Text(
              AppLocalizations.of(context)!.loading,
              style: OnepieceFonts.loadingFont,
            ),
          );
        }

        _prepareData(issueData);
        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow =
                ResponsiveBreakpoints.isMobileFromConstraints(constraints);
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                isNarrow ? 12 : 24,
                isNarrow ? 12 : 24,
                isNarrow ? 12 : 24,
                80,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeaderCard(context, isNarrow: isNarrow),
                      const SizedBox(height: 14),
                      if (isNarrow) ...[
                        _buildCreatorCard(context),
                        const SizedBox(height: 14),
                        _buildMetaCard(context),
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 4,
                              child: _buildCreatorCard(context),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 5,
                              child: _buildMetaCard(context),
                            ),
                          ],
                        ),
                      const SizedBox(height: 14),
                      _buildIssueBodyCard(context),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeaderCard(BuildContext context, {required bool isNarrow}) {
    return Card(
      elevation: 5,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isNarrow ? 16 : 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: OnepieceColors.fancyBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.feedback_outlined,
                color: OnepieceColors.fancyBlue,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.issueDetail,
                    style: OnepieceFonts.headerStyle,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    issue.issueHeader ?? '',
                    maxLines: isNarrow ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: OnepieceFonts.smallHeaderStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatorCard(BuildContext context) {
    final creator = issue.issueCreator!;
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            context,
            icon: Icons.person_outline,
            title: AppLocalizations.of(context)!.creator,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(44),
                hoverColor: OnepieceColors.liteFancyBlue,
                onTap: () {
                  context.goNamed(
                    'userDetails',
                    extra: creator.id,
                    pathParameters: {'name': creator.nickname},
                  );
                },
                child: ImageLazyLoader(
                  key: ValueKey(creator.imageUri),
                  uriProvider: () => creator.imageUri ?? '',
                  width: 84,
                  borderWidth: 3,
                  borderRadios: 84,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _labelValue(
                      AppLocalizations.of(context)!.nickname,
                      creator.nickname,
                    ),
                    const SizedBox(height: 12),
                    _labelValue(
                      AppLocalizations.of(context)!.email,
                      creator.username,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaCard(BuildContext context) {
    final issueTypeToDisplayValue = _issueTypeMap(context);
    final issueStatusToDisplayValue = _issueStatusMap(context);
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            context,
            icon: Icons.tune_outlined,
            title: AppLocalizations.of(context)!.issueDetail,
          ),
          const SizedBox(height: 16),
          _labelValue(
            AppLocalizations.of(context)!.issueType,
            issueTypeToDisplayValue[issue.issueType]!,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.status,
            style: OnepieceFonts.contentStyle,
          ),
          const SizedBox(height: 8),
          StatefulBuilder(builder: (context, basicState) {
            return Row(
              children: [
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton2<IssueStatus>(
                      isExpanded: true,
                      value: _selectedIssueStatus,
                      hint: Text(
                        AppLocalizations.of(context)!.status,
                        style: OnepieceFonts.dropDownItemStyle,
                      ),
                      onChanged: !_issueStatusEditable
                          ? null
                          : (value) {
                              basicState(() {
                                _selectedIssueStatus = value;
                              });
                            },
                      selectedItemBuilder: (context) {
                        return IssueStatus.values.map(
                          (item) {
                            return Container(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                issueStatusToDisplayValue[
                                    _selectedIssueStatus]!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 15),
                              ),
                            );
                          },
                        ).toList();
                      },
                      buttonStyleData: ButtonStyleData(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: OnepieceColors.menuBackgroundColor,
                          border: Border.all(
                            color: _issueStatusEditable
                                ? OnepieceColors.fancyGreen
                                : OnepieceColors.menuHoverColor,
                            width: _issueStatusEditable ? 1.8 : 1,
                          ),
                        ),
                      ),
                      menuItemStyleData: const MenuItemStyleData(height: 38),
                      items: IssueStatus.values.map((IssueStatus issueStatus) {
                        return DropdownMenuItem<IssueStatus>(
                          value: issueStatus,
                          child: Text(
                            issueStatusToDisplayValue[issueStatus]!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Tooltip(
                  message: _issueStatusEditable
                      ? AppLocalizations.of(context)!.submitForm
                      : AppLocalizations.of(context)!.editHint,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    hoverColor:
                        OnepieceColors.liteFancyBlue.withValues(alpha: 0.6),
                    splashColor: Colors.transparent,
                    onTap: () => _toggleStatusEditing(basicState),
                    child: Container(
                      width: 40,
                      height: 40,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: OnepieceColors.fancyBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: !_issueStatusEditable
                          ? ImageHelper.getSvgIconWithColor(
                              'images/svgs/edit.svg',
                              150,
                              150,
                              OnepieceColors.fancyBlue,
                            )
                          : ImageHelper.getSvgIconWithColor(
                              'images/svgs/check.svg',
                              150,
                              150,
                              OnepieceColors.fancyBlue,
                            ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  void _toggleStatusEditing(StateSetter basicState) {
    basicState(() {
      _issueStatusEditable = !_issueStatusEditable;
    });
    if (_issueStatusEditable) return;

    final request = BatchUpdateIssueRequest(
      updatedIssues: [
        Issue(id: issue.id, issueStatus: _selectedIssueStatus),
      ],
    );
    getIt<IssueDao>().batchUpdateIssue(request).then((value) {
      if (!mounted) return;
      setState(() {
        _issueFuture = _loadData();
        _selectedIssueStatus = null;
      });
    });
  }

  Widget _buildIssueBodyCard(BuildContext context) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            context,
            icon: Icons.article_outlined,
            title: issue.issueHeader ?? '',
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: OnepieceColors.liteFancyBlue.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: OnepieceColors.fancyBlue.withValues(alpha: 0.16),
              ),
            ),
            child: Text(
              issue.issueDescription ?? '',
              style: OnepieceFonts.contentStyle.copyWith(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: OnepieceColors.menuHoverColor.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: child,
      ),
    );
  }

  Widget _sectionTitle(
    BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: OnepieceColors.fancyBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: OnepieceColors.fancyBlue),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: OnepieceFonts.smallHeaderStyle,
          ),
        ),
      ],
    );
  }

  Widget _labelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: OnepieceFonts.contentStyle),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: OnepieceFonts.fancyBlueHintFont,
        ),
      ],
    );
  }
}
