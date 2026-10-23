import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openapi/api.dart';

import '../../../components/desktop_card_layout.dart';
import '../../../constants/onepiece_colors.dart';
import '../../../constants/onepiece_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/date_helper.dart';

/// The issue list body: a card list on mobile, a spotlight grid on desktop.
/// Each card shows the issue header, its type / status pills and the creator.
class IssueRoster extends StatelessWidget {
  final List<IssueListView> issues;
  final ScrollController controller;
  final bool isNarrow;

  const IssueRoster({
    super.key,
    required this.issues,
    required this.controller,
    required this.isNarrow,
  });

  @override
  Widget build(BuildContext context) =>
      isNarrow ? _buildMobile(context) : _buildDesktop(context);

  Map<IssueType, String> _typeMap(BuildContext context) => {
        IssueType.OTHER: AppLocalizations.of(context)!.otherType,
        IssueType.FEATURE_SUGGESTION:
            AppLocalizations.of(context)!.featureSuggestion,
        IssueType.BUG_REPORT: AppLocalizations.of(context)!.bugReport,
      };

  Map<IssueStatus, String> _statusMap(BuildContext context) => {
        IssueStatus.CREATED: AppLocalizations.of(context)!.statusCreated,
        IssueStatus.IN_PROGRESS:
            AppLocalizations.of(context)!.statusInProgress,
        IssueStatus.RESOLVED: AppLocalizations.of(context)!.statusResolved,
        IssueStatus.REVOKED: AppLocalizations.of(context)!.statusRevoked,
        IssueStatus.BACKLOGGED: AppLocalizations.of(context)!.statusBackLogged,
      };

  // ── Mobile: card-based issue list ────────────────────────────────────

  Widget _buildMobile(BuildContext context) {
    final typeMap = _typeMap(context);
    final statusMap = _statusMap(context);

    if (issues.isEmpty) {
      return Center(
          child: Text(AppLocalizations.of(context)!.empty,
              style: OnepieceFonts.contentStyle));
    }

    return ListView.builder(
      controller: controller,
      itemCount: issues.length,
      itemBuilder: (context, index) {
        final issue = issues[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => context.goNamed('issueDetails',
                extra: issue.id, pathParameters: {'id': issue.id!}),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(issue.issueHeader.toString(),
                        style: OnepieceFonts.headerStyle.copyWith(fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                                color: OnepieceColors.fancyBlue
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(typeMap[issue.issueType] ?? '',
                                style: OnepieceFonts.smallContentStyle.copyWith(
                                    color: OnepieceColors.fancyBlue,
                                    fontSize: 11)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                                color: OnepieceColors.liteFancyGreen
                                    .withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(statusMap[issue.issueStatus] ?? '',
                                style: OnepieceFonts.smallContentStyle
                                    .copyWith(fontSize: 11)),
                          ),
                        ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      Text('${AppLocalizations.of(context)!.creatorEmail}: ',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      Expanded(
                          child: Text(issue.creationRecord!.nickname ?? '',
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)),
                    ]),
                    const SizedBox(height: 2),
                    Text(
                        DateHelper.getFormattedDatetimeFromTimestamp(
                            issue.creationRecord!.actionTimestamp!, context),
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey)),
                  ]),
            ),
          ),
        );
      },
    );
  }

  // ── Desktop: spotlight grid ───────────────────────────────────────────

  Widget _buildDesktop(BuildContext context) {
    if (issues.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.empty,
            style: OnepieceFonts.contentStyle),
      );
    }
    final typeMap = _typeMap(context);
    final statusMap = _statusMap(context);

    return DesktopSpotlightGrid<IssueListView>(
      items: issues,
      idOf: (issue) => issue.id!,
      controller: controller,
      cardBuilder: (context, issue) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.goNamed('issueDetails',
              extra: issue.id, pathParameters: {'id': issue.id!}),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(issue.issueHeader ?? '',
                    style: OnepieceFonts.contentStyleBold.copyWith(
                        color: OnepieceColors.deepFancyBlue, fontSize: 17),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                Row(children: [
                  _issuePill(
                      typeMap[issue.issueType] ?? '', OnepieceColors.fancyBlue),
                  const SizedBox(width: 7),
                  _issuePill(statusMap[issue.issueStatus] ?? '',
                      OnepieceColors.iconGreen),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.person_outline,
                      size: 16, color: Colors.black45),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(issue.creationRecord?.nickname ?? '',
                        style: OnepieceFonts.smallContentStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text(
                    DateHelper.getFormattedDatetimeFromTimestamp(
                        issue.creationRecord!.actionTimestamp!, context),
                    style: OnepieceFonts.superSmallContentStyle,
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _issuePill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: OnepieceFonts.boldFancySmallFont.copyWith(color: color)),
    );
  }
}
