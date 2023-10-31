import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:one_piece_battles_flutter/repository/character_dao.dart';
import 'package:openapi/api.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../repository/battle_dao.dart';

GetIt getIt = GetIt.instance;

class CharacterDetail extends StatefulWidget {
  final String characterId;
  const CharacterDetail({super.key, required this.characterId});

  @override
  State<CharacterDetail> createState() => _CharacterDetailState();
}

class _CharacterDetailState extends State<CharacterDetail> {
  CharacterFullView characterFullView = CharacterFullView();
  List<Battle> battles = [];
  @override
  void initState() {
    super.initState();
    //todo(yichi): consider future builder!
    _loadData();
  }

  Future<void> _loadData() async {
    getIt<CharacterDao>()
        .getCharacter(
        GetCharacterFullViewRequest(characterId: widget.characterId))
        .then((value) {
      characterFullView = value!;
      getIt<BattleDao>()
          .batchFindByIds(ListBattleByIdsRequest(
          battleIds: characterFullView.battleIds, userId: getIt<User>().id))
          .then((value) {
        battles = value!.battles;
        setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _getProfileSection(context),
        _getCharacterDataList(context),
      ],
    );
  }

  Widget _getProfileSection(BuildContext context) {
    return Container();
  }

  Column _getCharacterDataList(BuildContext context) {
    return Column(
      children: [
        _getDataRow(AppLocalizations.of(context)!.characterAttack,
            characterFullView.character!.attack, 1000, 1000, 0),
        _getDataRow(AppLocalizations.of(context)!.characterDefense,
            characterFullView.character!.defense, 1000, 1000, 0),
        _getDataRow(AppLocalizations.of(context)!.characterBlood,
            characterFullView.character!.blood, 10000, 10000, 0),
        _getDataRow(AppLocalizations.of(context)!.characterSpeed,
            characterFullView.character!.speed, 200, 200, 0),
        _getDataRow(AppLocalizations.of(context)!.groupGain,
            characterFullView.character!.groupGain, 5, 5, 0),
        _getDataRow(AppLocalizations.of(context)!.characterIntelligence,
            characterFullView.character!.intelligence, 260, 260, 0),
      ],
    );
  }

  Padding _getDataRow(String name, int value, int base, int max, int min) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
            child: SizedBox(
                width: 80,
                child: Column(
                  children: [Text(name), Text(value.toString())],
                )),
          ),
          Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: 400,
                    height: 25,
                    decoration: const BoxDecoration(
                        color: OnepieceColors.menuBackgroundColor,
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                  ),
                  Container(
                    width: 400 * value / base,
                    height: 25,
                    decoration: const BoxDecoration(
                      color: OnepieceColors.themeColor,
                      borderRadius: BorderRadius.all(
                        Radius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(min.toString()),
                  const SizedBox(
                    width: 350,
                  ),
                  Text(max.toString()),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}
