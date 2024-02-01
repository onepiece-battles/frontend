import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/repository/battle_dao.dart';
import 'package:one_piece_battles_flutter/repository/character_dao.dart';
import 'package:one_piece_battles_flutter/repository/group_dao.dart';
import 'package:one_piece_battles_flutter/utils/base64_helper.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:openapi/api.dart';

import 'constants/onepiece_colors.dart';
import 'constants/onepiece_fonts.dart';

GetIt getIt = GetIt.instance;

class UserHome extends StatefulWidget {
  final String userId;
  const UserHome({super.key, required this.userId});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  List<CharacterListView> characters = [];
  List<GroupListView> groups = [];
  List<BattleListView> battles = [];
  Future<ListCharacterResponse?> listCharacters() async {
    ListCharacterRequest listCharacterRequest = ListCharacterRequest(
        pageSize: 30,
        pageIndex: 1,
        sortKeys: [],
        characterFilter:
            CharacterFilter(languageCode: I18nHelper.getLanguageCode(), userId: widget.userId));
    return await getIt<CharacterDao>().listCharacter(listCharacterRequest);
  }

  Future<ListGroupResponse?> listGroups() async {
    ListGroupRequest listGroupRequest = ListGroupRequest(
        pageSize: 10,
        pageIndex: 1,
        sortKeys: [],
        groupFilter: GroupFilter(languageCode: I18nHelper.getLanguageCode(), userId: widget.userId));
    return await getIt<GroupDao>().listGroups(listGroupRequest);
  }

  Future<ListBattleResponse?> listBattles() async {
    ListBattleRequest request = ListBattleRequest(
        pageSize: 10, pageIndex: 1, sortKeys: [], battleFilter: BattleFilter(userId: widget.userId));
    return await getIt<BattleDao>().listBattles(request);
  }

  _updateData(List<dynamic> widgets) {
    characters = (widgets[0] as ListCharacterResponse).characters;
    groups = (widgets[1] as ListGroupResponse).groups;
    battles = (widgets[2] as ListBattleResponse).battles;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Future.wait([listCharacters(), listGroups(), listBattles()]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            _updateData(snapshot.data!);
            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 50,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Text(
                          AppLocalizations.of(context)!.myCharacters,
                          style: OnepieceFonts.contentStyleBoldFancyBlue,
                        ),
                      ),
                      _getCharacterWall(context),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Text(
                          AppLocalizations.of(context)!.myGroups,
                          style: OnepieceFonts.contentStyleBoldFancyBlue,
                        ),
                      ),
                      _getGroupWall(context),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Text(
                          AppLocalizations.of(context)!.myBattles,
                          style: OnepieceFonts.contentStyleBoldFancyBlue,
                        ),
                      ),
                      _getBattleWall(context)
                    ],
                  )),
            );
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

  Widget _getCharacterWall(BuildContext context) {
    return SizedBox(
      width: characters.length<=8? characters.length * 70: 560,
      height: characters.length<=8? 80: 60 * (characters.length/8+1),
      child: GridView.builder(
        itemCount: characters.length,
        gridDelegate:  SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: characters.length<=8? characters.length: 8,
          mainAxisSpacing: 5,
          crossAxisSpacing: 5,
        ),
        // shrinkWrap: true,
        itemBuilder: (BuildContext context, int index) =>
        Card(child:  Container(
          // width: 50,
          // height: 50,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(2.0)),
            border: Border.all(
                color: OnepieceColors.fancyBlue,
                width: 2,
                style: BorderStyle.solid),
          ),
          child: Image(
            fit: BoxFit.cover,
            image:
            Image.memory(Base64Helper.decode(characters[index].profileImage!)).image,
          ),
        )),

      ),
    );
  }

  Widget _getGroupWall(BuildContext context) {
    return SizedBox(
      width: groups.length<=8? groups.length * 70: 560,
      height: groups.length<=8? 80: 60 * (groups.length/8+1),
      child: GridView.builder(
        itemCount: groups.length,
        gridDelegate:  SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: groups.length<=8? groups.length: 8,
          mainAxisSpacing: 5,
          crossAxisSpacing: 5,
        ),
        // shrinkWrap: true,
        itemBuilder: (BuildContext context, int index) =>
            Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(2.0)),
                border: Border.all(
                    color: OnepieceColors.fancyBlue,
                    width: 2,
                    style: BorderStyle.solid),
              ),
              child: Image(
                fit: BoxFit.cover,
                image:
                Image.memory(Base64Helper.decode(groups[index].profileImage!)).image,
              ),
            ),

      ),
    );
  }

  Widget _getBattleWall(BuildContext context) {
    return SizedBox(
      width: 800,
      child: ListView.builder(
          shrinkWrap: true,
          itemCount: battles.length,
          itemBuilder: (context, index){
            var battle = battles[index];
            return Material(
              type: MaterialType.transparency,
              child: Container(
                padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(5))),
                child: ListTile(
                  minLeadingWidth: 10,
                  contentPadding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  onTap: () {
                    setState(
                          () {
                            context.goNamed('battleDetails',
                                extra: battle.id,
                                pathParameters: {'id': battle.id});
                      },
                    );
                  },
                  hoverColor: OnepieceColors.liteFancyBlue,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(3, 3, 6, 3),
                            child: Container(
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
                                    Base64Helper.decode(battle.starterImage!)),
                              ),
                            ),
                          ),
                          const Text(
                            "vs",
                            style: OnepieceFonts.contentStyleBoldFancyBlue,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(3, 3, 6, 3),
                            child: Container(
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
                                    Base64Helper.decode(battle.receiverImage!)),
                              ),
                            ),
                          ),

                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(battle.battleStatus!.toString()),
                          Text(battle.battleReportStage!.toString())
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
      }),
    );
  }
}
