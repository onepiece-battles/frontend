import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openapi/api.dart';

import '../../../components/desktop_card_layout.dart';
import '../../../components/image_lazy_loader.dart';
import '../../../constants/onepiece_colors.dart';
import '../../../constants/onepiece_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/i18n_helper.dart';
import '../../../utils/image_helper.dart';

/// The battle list body: a card list on mobile, a spotlight grid on desktop.
/// Each card shows the starter-vs-receiver match-up, the winner (or a "?" when
/// unresolved), the battle status and the creator.
class BattleRoster extends StatelessWidget {
  final List<BattleListView> battles;
  final ScrollController controller;
  final bool isNarrow;

  const BattleRoster({
    super.key,
    required this.battles,
    required this.controller,
    required this.isNarrow,
  });

  @override
  Widget build(BuildContext context) =>
      isNarrow ? _buildMobile(context) : _buildDesktop(context);

  Map<BattleStatus, String> _statusMap(BuildContext context) => {
        BattleStatus.CREATED: AppLocalizations.of(context)!.battleStatusCreated,
        BattleStatus.IN_PROGRESS:
            AppLocalizations.of(context)!.battleStatusStarted,
        BattleStatus.FINISHED:
            AppLocalizations.of(context)!.battleStatusFinished,
        BattleStatus.FAILED: AppLocalizations.of(context)!.battleStatusFailed,
      };

  // ── Mobile: card-based battle list ────────────────────────────────────

  Widget _buildMobile(BuildContext context) {
    if (battles.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.empty,
            style: OnepieceFonts.contentStyle),
      );
    }

    final statusMap = _statusMap(context);

    return ListView.builder(
      controller: controller,
      itemCount: battles.length,
      itemBuilder: (context, index) {
        final battle = battles[index];
        final exec = battle.battleExecution;
        final isEven = index.isEven;

        return Card(
          color: isEven ? OnepieceColors.liteFancyGreen : Colors.white,
          margin: const EdgeInsets.only(bottom: 4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => context.goNamed('battleDetails',
                extra: battle.id, pathParameters: {'id': battle.id}),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  // Starter vs Receiver row
                  Row(
                    children: [
                      // Starter
                      Expanded(
                        child: _buildBattleCharCard(
                          imageUri: battle.starter!.imageUri!,
                          name: I18nHelper.getDisplayNameFromI18n(
                              battle.starter!.name),
                          score: exec?.starterScoreBefore?.toString() ?? '?',
                        ),
                      ),
                      // VS
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          children: [
                            Text(AppLocalizations.of(context)!.versus,
                                style: OnepieceFonts.boldFancySmallFont
                                    .copyWith(
                                        color: OnepieceColors.fancyBlue,
                                        fontSize: 14)),
                            const SizedBox(height: 4),
                            // Winner indicator
                            if (exec?.winnerId != null)
                              ImageLazyLoader(
                                uriProvider: () =>
                                    exec!.winnerId == battle.starterId
                                        ? battle.starter!.imageUri!
                                        : battle.receiver!.imageUri!,
                                width: 30,
                                borderWidth: 2,
                                lazy: true,
                                borderRadios: 30,
                              )
                            else
                              Container(
                                width: 30,
                                height: 30,
                                decoration: const BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(4)),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.fill,
                                  child: ImageHelper.getSvgIconWithColor(
                                      'images/svgs/question.svg',
                                      100,
                                      100,
                                      OnepieceColors.liteFancyBlue),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Receiver
                      Expanded(
                        child: _buildBattleCharCard(
                          imageUri: battle.receiver!.imageUri!,
                          name: I18nHelper.getDisplayNameFromI18n(
                              battle.receiver!.name),
                          score: exec?.receiverScoreBefore?.toString() ?? '?',
                          alignRight: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Status + Creator row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              OnepieceColors.fancyBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusMap[exec?.battleStatus] ?? '',
                          style: OnepieceFonts.smallContentStyle.copyWith(
                              color: OnepieceColors.fancyBlue, fontSize: 12),
                        ),
                      ),
                      Flexible(
                          child: Text(
                        battle.creationRecord?.nickname ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: OnepieceFonts.smallContentStyle
                            .copyWith(fontSize: 12),
                      )),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBattleCharCard({
    required String imageUri,
    required String name,
    required String score,
    bool alignRight = false,
  }) {
    final children = [
      ImageLazyLoader(
        uriProvider: () => imageUri,
        width: 32,
        borderWidth: 2,
        lazy: true,
        borderRadios: 32,
      ),
      const SizedBox(width: 8),
      Flexible(
          child: Column(
        crossAxisAlignment:
            alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(name,
              style: OnepieceFonts.contentStyle.copyWith(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(score, style: OnepieceFonts.boldFancySmallFont),
        ],
      )),
    ];
    return Row(
      mainAxisAlignment:
          alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: alignRight ? children.reversed.toList() : children,
    );
  }

  // ── Desktop: spotlight grid ───────────────────────────────────────────

  Widget _buildDesktop(BuildContext context) {
    if (battles.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.empty,
            style: OnepieceFonts.contentStyle),
      );
    }
    final statusMap = _statusMap(context);

    return DesktopSpotlightGrid<BattleListView>(
      items: battles,
      idOf: (battle) => battle.id,
      controller: controller,
      minCardWidth: 280,
      maxColumns: 6,
      gap: 10,
      cardBuilder: (context, battle) {
        final execution = battle.battleExecution;
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => context.goNamed('battleDetails',
                extra: battle.id, pathParameters: {'id': battle.id}),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(children: [
                Row(children: [
                  Expanded(
                    child: _buildBattleCharCard(
                      imageUri: battle.starter!.imageUri!,
                      name: I18nHelper.getDisplayNameFromI18n(
                          battle.starter!.name),
                      score: execution?.starterScoreBefore?.toString() ?? '?',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(AppLocalizations.of(context)!.versus,
                        style: OnepieceFonts.contentStyleBoldFancyBlue),
                  ),
                  Expanded(
                    child: _buildBattleCharCard(
                      imageUri: battle.receiver!.imageUri!,
                      name: I18nHelper.getDisplayNameFromI18n(
                          battle.receiver!.name),
                      score: execution?.receiverScoreBefore?.toString() ?? '?',
                      alignRight: true,
                    ),
                  ),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: OnepieceColors.fancyBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(statusMap[execution?.battleStatus] ?? '',
                        style: OnepieceFonts.boldFancySmallFont),
                  ),
                  const Spacer(),
                  const Icon(Icons.person_outline,
                      size: 15, color: Colors.black45),
                  const SizedBox(width: 4),
                  Flexible(
                      child: Text(battle.creationRecord?.nickname ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: OnepieceFonts.smallContentStyle)),
                ]),
              ]),
            ),
          ),
        );
      },
    );
  }
}
