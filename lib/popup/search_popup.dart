import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/components/image_lazy_loader.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_tag.dart';
import 'package:one_piece_battles_flutter/repository/group_dao.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:openapi/api.dart';
import '../../l10n/app_localizations.dart';
import '../constants/onepiece_colors.dart';
import '../repository/character_dao.dart';
import '../repository/fruit_dao.dart';

GetIt getIt = GetIt.instance;
Timer? _timer;

class SearchPopup extends StatefulWidget {
  const SearchPopup({super.key});

  @override
  State<SearchPopup> createState() => _SearchPopupState();
}

class _SearchPopupState extends State<SearchPopup> {
  final TextEditingController searchBarController = TextEditingController();
  List<CharacterListView> characters =
      <CharacterListView>[].toList(growable: true);
  CharacterFilter characterFilter = CharacterFilter();
  List<FruitListView> fruits = <FruitListView>[].toList(growable: true);
  FruitFilter fruitFilter = FruitFilter();
  List<Battle> battle = [];
  GroupFilter groupFilter = GroupFilter();
  List<GroupListView> groups = [];
  bool _isSearching = false;
  int _searchVersion = 0;

  Future<void> _search(String name) async {
    final int version = ++_searchVersion;
    characterFilter.languageCode = I18nHelper.getLanguageCode();
    fruitFilter.languageCode = I18nHelper.getLanguageCode();
    groupFilter.languageCode = I18nHelper.getLanguageCode();
    if (name.isEmpty) {
      setState(() {
        characters = [];
        fruits = [];
        groups = [];
        _isSearching = false;
      });
      return;
    }
    setState(() {
      _isSearching = true;
    });
    characterFilter.name = name;
    fruitFilter.name = name;
    final listCharacterRequest = ListCharacterRequest(
        pageSize: 10,
        pageIndex: 1,
        sortKeys: [],
        characterFilter: characterFilter);

    final request = ListFruitRequest(
        pageSize: 6, pageIndex: 1, sortKeys: [], fruitFilter: fruitFilter);

    groupFilter.name = name;
    final listGroupRequest = ListGroupRequest(
        pageSize: 6, pageIndex: 1, sortKeys: [], groupFilter: groupFilter);

    final responses = await Future.wait<dynamic>([
      getIt<CharacterDao>().listCharacter(listCharacterRequest),
      getIt<FruitDao>().list(request),
      getIt<GroupDao>().listGroups(listGroupRequest),
    ]);

    if (!mounted || version != _searchVersion) return;
    final characterResponse = responses[0] as ListCharacterResponse?;
    final fruitResponse = responses[1] as ListFruitResponse?;
    final groupResponse = responses[2] as ListGroupResponse?;
    setState(() {
      characters = characterResponse?.characters ?? [];
      fruits = fruitResponse?.fruits ?? [];
      groups = groupResponse?.groups ?? [];
      _isSearching = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    searchBarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxWidth = media.size.width < 860 ? media.size.width - 24 : 820.0;
    final maxHeight = media.size.height * 0.82;

    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth.clamp(320.0, 820.0),
          maxHeight: maxHeight.clamp(360.0, 760.0),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: OnepieceColors.liteFancyBlue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _getSearchBar(context),
                const SizedBox(height: 16),
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (characters.isNotEmpty)
                  _buildResultSection(
                    title: AppLocalizations.of(context)!.character,
                    child: _getCharacterList(context),
                  ),
                if (fruits.isNotEmpty)
                  _buildResultSection(
                    title: AppLocalizations.of(context)!.devilFruit,
                    child: _getFruitList(context),
                  ),
                if (groups.isNotEmpty)
                  _buildResultSection(
                    title: AppLocalizations.of(context)!.group,
                    child: _getGroupList(context),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultSection({
    required String title,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: OnepieceFonts.selectedTableHeaderStyle),
          const SizedBox(height: 6),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.35)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _getSearchBar(BuildContext context) {
    return TextFormField(
      autofocus: true,
      cursorColor: Colors.white,
      controller: searchBarController,
      decoration: InputDecoration(
        floatingLabelBehavior: FloatingLabelBehavior.never,
        labelStyle: OnepieceFonts.whiteHintFont,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7.0),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.82),
            width: 1.2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7.0),
          borderSide: const BorderSide(
            color: Colors.white,
            width: 1.8,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7.0),
          borderSide: const BorderSide(
            color: Colors.white,
            width: 2.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7.0),
          borderSide: const BorderSide(
            color: Colors.white,
            width: 2.2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7.0),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.6),
            width: 1.2,
          ),
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: Colors.white,
        ),
        labelText: AppLocalizations.of(context)!.searchResourceDetail,
      ),
      onChanged: (value) {
        if (_timer?.isActive ?? false) _timer?.cancel();
        _timer = Timer(const Duration(milliseconds: 450), () {
          _search(value.trim());
        });
      },
    );
  }

  Widget _getCharacterList(BuildContext context) {
    Map<Haki, String> hakiEnumValueToDisplayValue = {
      Haki.busoshoku: AppLocalizations.of(context)!.busoshoku,
      Haki.haoshoku: AppLocalizations.of(context)!.haoshoku,
      Haki.kenbunshoku: AppLocalizations.of(context)!.kenbunshoku,
    };
    return ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 300.0, // Set your maximum height here
        ),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: characters.length,
          itemBuilder: (context, index) {
            var character = characters[index];
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
                    Navigator.pop(context);
                    context.goNamed('characterDetails',
                        extra: character.id,
                        pathParameters: {
                          'name':
                              I18nHelper.getDisplayNameFromI18n(character.name)
                        });
                  },
                  hoverColor:
                      OnepieceColors.liteFancyGreen.withValues(alpha: 0.34),
                  title: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(3, 3, 6, 3),
                              child: ImageLazyLoader(
                                  key: ValueKey(character.imageUri),
                                  uriProvider: () => character.imageUri ?? '',
                                  width: 50,
                                  borderWidth: 2,
                                  borderRadios: 10),
                            ),
                            Expanded(
                              child: Text(
                                I18nHelper.getDisplayNameFromI18n(
                                    character.name),
                                style: OnepieceFonts.smallContentStyleWhite,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (character.hakis.isNotEmpty)
                        Flexible(
                          child: Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 5,
                            runSpacing: 4,
                            children: character.hakis
                                .map((e) => OnepieceTag.getHakiTag(
                                    e, hakiEnumValueToDisplayValue[e]!))
                                .toList(),
                          ),
                        )
                    ],
                  ),
                ),
              ),
            );
          },
        ));
  }

  Widget _getFruitList(BuildContext context) {
    Map<FruitType, String> fruitTypeToDisplayValue = {
      FruitType.logia: AppLocalizations.of(context)!.logiaFruit,
      FruitType.zoan: AppLocalizations.of(context)!.zoanFruit,
      FruitType.ancientZoan: AppLocalizations.of(context)!.ancientZoanFruit,
      FruitType.mythicalZoan: AppLocalizations.of(context)!.mythicalZoanFruit,
      FruitType.artificialZoan:
          AppLocalizations.of(context)!.artificialZoanFruit,
      FruitType.paramecia: AppLocalizations.of(context)!.parameciaFruit,
    };
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 300.0, // Set your maximum height here
      ),
      child: ListView.builder(
          shrinkWrap: true,
          itemCount: fruits.length,
          itemBuilder: (context, index) {
            var fruit = fruits[index];
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
                    Navigator.pop(context);
                    context.goNamed('fruitDetails',
                        extra: fruit.id,
                        pathParameters: {
                          'name': I18nHelper.getDisplayNameFromI18n(fruit.name!)
                        });
                  },
                  hoverColor:
                      OnepieceColors.liteFancyGreen.withValues(alpha: 0.34),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          I18nHelper.getDisplayNameFromI18n(fruit.name!),
                          style: OnepieceFonts.smallContentStyleWhite,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: OnepieceTag.getFruitTag(fruit.fruitType!,
                                fruitTypeToDisplayValue[fruit.fruitType]!),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          }),
    );
  }

  Widget _getGroupList(BuildContext context) {
    Map<GroupCategory, String> groupCategoryToDisplayValue =
        <GroupCategory, String>{
      GroupCategory.marine: AppLocalizations.of(context)!.marine,
      GroupCategory.pirate: AppLocalizations.of(context)!.pirate,
      GroupCategory.group: AppLocalizations.of(context)!.group,
      GroupCategory.other: AppLocalizations.of(context)!.otherType,
      GroupCategory.underWorld: AppLocalizations.of(context)!.underworld,
      GroupCategory.government: AppLocalizations.of(context)!.worldGovernment,
      GroupCategory.revolutionArmy:
          AppLocalizations.of(context)!.revolutionaryArmy,
    };
    return ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 300.0, // Set your maximum height here
        ),
        child: ListView.builder(
            shrinkWrap: true,
            itemCount: groups.length,
            itemBuilder: (context, index) {
              var group = groups[index];
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
                      Navigator.pop(context);
                      context.goNamed('groupDetails',
                          extra: group.id,
                          pathParameters: {
                            'name':
                                I18nHelper.getDisplayNameFromI18n(group.name)
                          });
                    },
                    hoverColor:
                        OnepieceColors.liteFancyGreen.withValues(alpha: 0.34),
                    title: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(3, 6, 3, 3),
                                child: ImageLazyLoader(
                                    key: ValueKey(group.imageUri),
                                    uriProvider: () => group.imageUri ?? '',
                                    width: 50,
                                    borderWidth: 2,
                                    borderRadios: 10),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  I18nHelper.getDisplayNameFromI18n(group.name),
                                  style: OnepieceFonts.smallContentStyleWhite,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: OnepieceTag.getGroupTag(
                                  group.groupCategory!,
                                  groupCategoryToDisplayValue[
                                      group.groupCategory]!),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            }));
  }
}
