import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/repository/battle_dao.dart';
import 'package:one_piece_battles_flutter/repository/character_dao.dart';
import 'package:one_piece_battles_flutter/repository/group_dao.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:openapi/api.dart';

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
        characterFilter: CharacterFilter(languageCode: I18nHelper.getLanguageCode()));
    return await getIt<CharacterDao>().listCharacter(listCharacterRequest);
  }

  Future<ListGroupResponse?> listGroups() async {
    ListGroupRequest listGroupRequest = ListGroupRequest(
        pageSize: 10, pageIndex: 1, sortKeys: [], groupFilter: GroupFilter(languageCode: I18nHelper.getLanguageCode()));
    return await getIt<GroupDao>().listGroups(listGroupRequest);
  }

  Future<ListBattleResponse?> listBattles() async {
    ListBattleRequest request = ListBattleRequest(
        pageSize: 10, pageIndex: 1, sortKeys: [], battleFilter: BattleFilter());
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
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot ) {
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
                      const SizedBox(height: 50,),
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
    return Container();
  }

  Widget _getGroupWall(BuildContext context) {
    return Container();
  }

  Widget _getBattleWall(BuildContext context) {
    return Container();
  }
}
