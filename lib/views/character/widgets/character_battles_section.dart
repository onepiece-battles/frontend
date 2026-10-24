import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openapi/api.dart';

import '../../../components/image_lazy_loader.dart';
import '../../../constants/onepiece_colors.dart';
import '../../../constants/onepiece_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/i18n_helper.dart';

/// The "related battles" section of the character detail screen.
///
/// Renders a compact card list on mobile and a paginated DataTable on desktop.
/// Owns its own pagination state (which previously lived in the character
/// detail god-view) so the parent no longer has to track it.
class CharacterBattlesSection extends StatefulWidget {
  final CharacterFullView character;
  final bool isNarrow;
  final double dividerWidth;
  final double sideWidth;

  const CharacterBattlesSection({
    super.key,
    required this.character,
    required this.isNarrow,
    this.dividerWidth = 860,
    this.sideWidth = 50,
  });

  @override
  State<CharacterBattlesSection> createState() =>
      _CharacterBattlesSectionState();
}

class _CharacterBattlesSectionState extends State<CharacterBattlesSection> {
  int battleStartIndex = 0;
  int battleEndIndex = 0;
  int pageCount = 1;

  List<BattleListView> get battles => widget.character.battles;

  @override
  void initState() {
    super.initState();
    battleEndIndex = battles.length >= 10 ? 10 : battles.length;
  }

  @override
  void didUpdateWidget(covariant CharacterBattlesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.character.id != widget.character.id) {
      battleStartIndex = 0;
      battleEndIndex = battles.length >= 10 ? 10 : battles.length;
      pageCount = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.isNarrow ? _buildMobile(context) : _buildDesktop(context);
  }

  // ── Mobile ─────────────────────────────────────────────────────────

  Widget _buildMobile(BuildContext context) {
    final statusMap = {
      BattleStatus.CREATED: AppLocalizations.of(context)!.battleStatusCreated,
      BattleStatus.IN_PROGRESS:
          AppLocalizations.of(context)!.battleStatusStarted,
      BattleStatus.FINISHED: AppLocalizations.of(context)!.battleStatusFinished,
      BattleStatus.FAILED: AppLocalizations.of(context)!.battleStatusFailed
    };
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppLocalizations.of(context)!.relatedBattles,
                style: OnepieceFonts.headerStyle.copyWith(fontSize: 16)),
            const SizedBox(height: 10),
            if (battles.isEmpty)
              Text(AppLocalizations.of(context)!.empty,
                  style: OnepieceFonts.contentStyle)
            else ...[
              ...battles.take(10).map((b) {
                final ex = b.battleExecution;
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => context.goNamed('battleDetails',
                        extra: b.id, pathParameters: {'id': b.id}),
                    child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(children: [
                          _battleCharMini(
                              context, b.starter!, ex?.starterScoreBefore),
                          const SizedBox(width: 6),
                          Column(children: [
                            Text('VS',
                                style: OnepieceFonts.boldFancySmallFont
                                    .copyWith(
                                        color: OnepieceColors.fancyBlue,
                                        fontSize: 12)),
                            ex?.winnerId != null
                                ? ImageLazyLoader(
                                    key: ValueKey('w${b.id}'),
                                    uriProvider: () =>
                                        ex!.winnerId == b.starterId
                                            ? b.starter!.imageUri!
                                            : b.receiver!.imageUri!,
                                    width: 24,
                                    borderWidth: 1.5,
                                    borderRadios: 24)
                                : Icon(Icons.help_outline,
                                    size: 24, color: Colors.grey[400]),
                          ]),
                          const SizedBox(width: 6),
                          _battleCharMini(
                              context, b.receiver!, ex?.receiverScoreBefore),
                          const Spacer(),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: OnepieceColors.fancyBlue
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: Text(
                                        statusMap[ex?.battleStatus] ?? '',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: OnepieceColors.fancyBlue))),
                                if (ex?.winnerId != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                      getScoreText(
                                          widget.character.id == ex!.winnerId
                                              ? ex.winnerScoreChange!
                                              : ex.loserScoreChange!),
                                      style: OnepieceFonts.boldFancyBlueHintFont
                                          .copyWith(fontSize: 12))
                                ],
                              ]),
                        ])),
                  ),
                );
              }),
              if (battles.length > 10)
                Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Center(
                        child: Text(
                            '${battles.length} ${AppLocalizations.of(context)!.relatedBattles}',
                            style: OnepieceFonts.smallContentStyle))),
            ],
          ])),
    );
  }

  Widget _battleCharMini(BuildContext context, Character char, int? score) {
    return Expanded(
        child: Column(children: [
      ImageLazyLoader(
          key: ValueKey(char.imageUri),
          uriProvider: () => char.imageUri!,
          width: 32,
          borderWidth: 1.5,
          borderRadios: 32),
      const SizedBox(height: 2),
      Text(I18nHelper.getDisplayNameFromI18n(char.name),
          style: const TextStyle(fontSize: 10),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      Text(score?.toString() ?? '?',
          style: OnepieceFonts.boldFancySmallFont.copyWith(fontSize: 11)),
    ]));
  }

  // ── Desktop ────────────────────────────────────────────────────────

  Widget _buildDesktop(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(widget.sideWidth, 8, widget.sideWidth, 8),
      child: SizedBox(
        width: widget.dividerWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.relatedBattles,
                  style: OnepieceFonts.headerStyle,
                ),
                if (battles.length > 10) _getPageController(context)
              ],
            ),
            const SizedBox(height: 20),
            _getBattlesTable(context),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _getBattlesTable(BuildContext context) {
    return DataTable(
      showCheckboxColumn: false,
      showBottomBorder: true,
      headingRowHeight: 50,
      border: const TableBorder(
          top: BorderSide(color: OnepieceColors.themeColor),
          bottom: BorderSide(color: OnepieceColors.themeColor)),
      columns: _createColumns(context),
      rows: _createRows(context),
      columnSpacing: 8,
    );
  }

  Widget _getPageController(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 80.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 40,
            height: 30,
            child: Center(
              child: IconButton(
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                color: Colors.transparent,
                highlightColor: Colors.transparent,
                onPressed: battleStartIndex == 0
                    ? null
                    : () {
                        setState(() {
                          pageCount--;
                          battleStartIndex = battleStartIndex - 10;
                          if (battleEndIndex % 10 != 0) {
                            battleEndIndex =
                                battleEndIndex - battleEndIndex % 10;
                          } else {
                            battleEndIndex = battleEndIndex - 10;
                          }
                          if (battleStartIndex < 0) {
                            battleStartIndex = 0;
                          }
                        });
                      },
                icon: Icon(
                  Icons.keyboard_arrow_left_sharp,
                  size: 20,
                  color: battleStartIndex == 0
                      ? Colors.transparent
                      : OnepieceColors.fancyBlue,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 20,
            height: 30,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: Text(
                  pageCount.toString(),
                  style: const TextStyle(
                      color: OnepieceColors.fancyBlue, fontSize: 15),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 40,
            height: 30,
            child: Center(
              child: IconButton(
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                color: Colors.transparent,
                highlightColor: Colors.transparent,
                onPressed: battleEndIndex == battles.length
                    ? null
                    : () {
                        setState(() {
                          pageCount++;
                          battleStartIndex = battleStartIndex + 10;
                          battleEndIndex = battleEndIndex + 10;
                          if (battleEndIndex > battles.length) {
                            battleEndIndex = battles.length;
                          }
                        });
                      },
                icon: Icon(
                  Icons.keyboard_arrow_right_sharp,
                  size: 20,
                  color: battleEndIndex == battles.length
                      ? Colors.transparent
                      : OnepieceColors.fancyBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DataColumn> _createColumns(BuildContext context) {
    var headerStyle = OnepieceFonts.tableHeaderStyle;
    return [
      const DataColumn(
        label: Text(""),
      ),
      DataColumn(
        label: SizedBox(
            width: 150,
            child: Text(
              AppLocalizations.of(context)!.initiator,
              style: headerStyle,
            )),
      ),
      DataColumn(
        label: SizedBox(
            width: 150,
            child: Text(AppLocalizations.of(context)!.receiver,
                style: headerStyle)),
      ),
      DataColumn(
        label: SizedBox(
            width: 150,
            child:
                Text(AppLocalizations.of(context)!.winner, style: headerStyle)),
      ),
      DataColumn(
        label: SizedBox(
            width: 80,
            child:
                Text(AppLocalizations.of(context)!.status, style: headerStyle)),
      ),
      DataColumn(
        label: SizedBox(
            width: 150,
            child: Text(AppLocalizations.of(context)!.combatScoreChange,
                style: headerStyle)),
      ),
    ];
  }

  List<DataRow> _createRows(BuildContext context) {
    Map<BattleStatus, String> battleStatusToDisplayName = {
      BattleStatus.CREATED: AppLocalizations.of(context)!.battleStatusCreated,
      BattleStatus.IN_PROGRESS:
          AppLocalizations.of(context)!.battleStatusStarted,
      BattleStatus.FINISHED: AppLocalizations.of(context)!.battleStatusFinished,
      BattleStatus.FAILED: AppLocalizations.of(context)!.battleStatusFailed,
    };
    return battles
        .getRange(battleStartIndex, battleEndIndex)
        .toList()
        .asMap()
        .entries
        .map((entry) => DataRow(
                onSelectChanged: (value) {
                  context.goNamed('battleDetails',
                      extra: entry.value.id,
                      pathParameters: {'id': entry.value.id});
                },
                cells: [
                  _getDataCell("${entry.key + 1}", false),
                  DataCell(
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                          child: ImageLazyLoader(
                              uriProvider: () => entry.value.starter!.imageUri!,
                              width: 40,
                              borderWidth: 1.5,
                              borderRadios: 40),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                              child: Text(I18nHelper.getDisplayNameFromI18n(
                                  entry.value.starter!.name)),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 5.0),
                              child: Text(
                                  entry.value.battleExecution!
                                      .starterScoreBefore!
                                      .toString(),
                                  style: OnepieceFonts.boldFancySmallFont),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                          child: ImageLazyLoader(
                              uriProvider: () =>
                                  entry.value.receiver!.imageUri!,
                              width: 40,
                              borderWidth: 1.5,
                              borderRadios: 40),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                              child: Text(I18nHelper.getDisplayNameFromI18n(
                                  entry.value.receiver!.name)),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 5.0),
                              child: Text(
                                  entry.value.battleExecution!
                                      .receiverScoreBefore!
                                      .toString(),
                                  style: OnepieceFonts.boldFancySmallFont),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Padding(
                      padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                      child: ImageLazyLoader(
                          uriProvider: () =>
                              entry.value.battleExecution!.winnerId ==
                                      entry.value.starterId
                                  ? entry.value.starter!.imageUri!
                                  : entry.value.receiver!.imageUri!,
                          width: 40,
                          borderWidth: 1.5,
                          borderRadios: 40),
                    ),
                  ),
                  _getDataCell(
                      battleStatusToDisplayName[
                          entry.value.battleExecution!.battleStatus]!,
                      false),
                  DataCell(
                    Row(
                      children: [
                        entry.value.battleExecution!.winnerId != null
                            ? Text(
                                style: OnepieceFonts.boldFancyBlueHintFont,
                                widget.character.id ==
                                        entry.value.battleExecution!.winnerId
                                    ? getScoreText(entry.value.battleExecution!
                                        .winnerScoreChange!)
                                    : getScoreText(entry.value.battleExecution!
                                        .loserScoreChange!))
                            : const Text(""),
                        const SizedBox(
                          width: 10,
                        ),
                        entry.value.battleExecution!.winnerId != null
                            ? Text(
                                style: OnepieceFonts.superSmallContentStyle,
                                widget.character.id == entry.value.starterId
                                    ? "(${entry.value.battleExecution!.starterScoreBefore!} -> ${entry.value.battleExecution!.starterScoreAfter!})"
                                    : "(${entry.value.battleExecution!.receiverScoreBefore!} ->${entry.value.battleExecution!.receiverScoreAfter!})")
                            : const Text(""),
                      ],
                    ),
                  ),
                ]))
        .toList();
  }

  String getScoreText(int scoreChange) {
    return scoreChange >= 0 ? "+ $scoreChange" : "- ${(0 - scoreChange)}";
  }

  DataCell _getDataCell(String value, bool heightLight) {
    return DataCell(heightLight
        ? Text(
            value,
            style: OnepieceFonts.tableHeightStyle,
          )
        : Text(value));
  }
}
