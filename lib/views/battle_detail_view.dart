import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:one_piece_battles_flutter/repository/battle_dao.dart';
import 'package:one_piece_battles_flutter/repository/file_dao.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:openapi/api.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../constants/button_style.dart';
import '../constants/onepiece_fonts.dart';
import '../utils/base64_helper.dart';

GetIt getIt = GetIt.instance;

class BattleDetailView extends StatefulWidget {
  final String battleId;
  const BattleDetailView({super.key, required this.battleId});

  @override
  State<BattleDetailView> createState() => _BattleDetailViewState();
}

class _BattleDetailViewState extends State<BattleDetailView> {
  late BattleFullView battle;
  late Character starter;
  late Character receiver;
  late BattleStatus battleStatus;

  _loadData() {
    return getIt<BattleDao>()
        .getBattleFullView(GetBattleFullViewRequest(battleId: widget.battleId));
  }

  void _updateData(BattleFullView battleFullView) {
    battle = battleFullView;
    battleStatus = battle.status;
    starter = battleFullView.starter!;
    receiver = battleFullView.receiver!;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _loadData(),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            _updateData(snapshot.data);
            return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [_getTopBar(context), _getProgressLine(context)],
                  ),
                ));
          } else {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.loading,
                style: OnepieceFonts.loadingFont,
              ),
            );
          }
        });
  }

  _getTopBar(BuildContext context) {
    return StatefulBuilder(builder: (context, topBarState) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            height: 35,
            child: ElevatedButton(
              style: OnepieceButtonStyle.getDefaultStyle(),
              onPressed: battleStatus != BattleStatus.CREATED
                  ? null
                  : () {
                      StartBattleRequest request =
                          StartBattleRequest(battleId: battle.id);
                      getIt<BattleDao>().startBattle(request);
                    },
              child: Text(
                AppLocalizations.of(context)!.startBattle,
                style: OnepieceFonts.contentStyleBoldWhite,
              ),
            ),
          ),
          if (battleStatus == BattleStatus.FINISHED)
            IconButton(
              onPressed: () {
                DownloadFileRequest request =
                    DownloadFileRequest(id: battle.id);
                getIt<FileDao>().downloadFile(request);
              },
              splashRadius: 1,
              tooltip: AppLocalizations.of(context)!.downloadReport,
              hoverColor: OnepieceColors.liteFancyBlue,
              disabledColor: Colors.grey,
              icon: const Icon(
                Icons.file_copy_sharp,
                color: OnepieceColors.fancyBlue,
                size: 30,
              ),
            )
        ],
      );
    });
  }

  _getProgressLine(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [
            SizedBox(
              width: 120,
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.all(Radius.circular(2.0)),
                      border: Border.all(
                          color: Colors.grey,
                          width: 2,
                          style: BorderStyle.solid),
                    ),
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: Image.memory(
                          Base64Helper.decode(starter.profileImage!)),
                    ),
                  ),
                  Text(
                    I18nHelper.getDisplayNameFromI18n(starter.name),
                    style: OnepieceFonts.fancyBlueHintFont,
                  )
                ],
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            SizedBox(
              width: 120,
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.all(Radius.circular(2.0)),
                      border: Border.all(
                          color: Colors.grey,
                          width: 2,
                          style: BorderStyle.solid),
                    ),
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: Image.memory(
                          Base64Helper.decode(receiver.profileImage!)),
                    ),
                  ),
                  Text(
                    I18nHelper.getDisplayNameFromI18n(receiver.name),
                    style: OnepieceFonts.fancyBlueHintFont,
                  )
                ],
              ),
            ),
          ],
        ),
        _getRightProgress(),
      ],
    );
  }

  _getRightProgress() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.horizontal_rule,
          color: OnepieceColors.fancyGreen,
        ),
        Icon(
          Icons.horizontal_rule,
          color: OnepieceColors.fancyGreen,
        ),
        Icon(
          Icons.horizontal_rule,
          color: OnepieceColors.fancyGreen,
        ),
        Icon(
          Icons.chevron_right_outlined,
          color: OnepieceColors.fancyGreen,
        ),
        Icon(
          Icons.chevron_right_outlined,
          color: OnepieceColors.fancyGreen,
        ),
        Icon(
          Icons.chevron_right_outlined,
          color: OnepieceColors.fancyGreen,
        ),
        Icon(
          Icons.horizontal_rule,
          color: OnepieceColors.fancyGreen,
        ),
        Icon(
          Icons.horizontal_rule,
          color: OnepieceColors.fancyGreen,
        ),
        Icon(
          Icons.horizontal_rule,
          color: OnepieceColors.fancyGreen,
        ),
      ],
    );
  }
}
