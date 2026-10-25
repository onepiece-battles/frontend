import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openapi/api.dart';

import '../../../constants/onepiece_colors.dart';
import '../../../constants/onepiece_fonts.dart';
import '../../../constants/onepiece_tag.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/i18n_helper.dart';
import '../character_detail_controller.dart';

/// The "devil fruit" section of the character detail screen: the fruits the
/// character has eaten, plus (when the character can eat more and the viewer
/// can edit) a search box to find and eat a new fruit.
///
/// Owns its own fruit-search state (query / results / selection) — previously
/// scattered across the god-view — and delegates the search/eat calls to
/// [CharacterDetailController]. Eating a fruit notifies the parent via
/// [onFruitEaten] so it can reload the character.
class CharacterFruitsSection extends StatefulWidget {
  final CharacterFullView character;
  final bool editButtonVisible;
  final CharacterDetailController controller;
  final VoidCallback onFruitEaten;
  final bool isNarrow;
  final double dividerWidth;
  final double sideWidth;

  const CharacterFruitsSection({
    super.key,
    required this.character,
    required this.editButtonVisible,
    required this.controller,
    required this.onFruitEaten,
    required this.isNarrow,
    this.dividerWidth = 860,
    this.sideWidth = 50,
  });

  @override
  State<CharacterFruitsSection> createState() => _CharacterFruitsSectionState();
}

class _CharacterFruitsSectionState extends State<CharacterFruitsSection> {
  final TextEditingController fruitNameController = TextEditingController();
  final FruitFilter fruitFilter = FruitFilter();
  List<FruitListView> searchingFruitList = [];
  String? selectedFruitId;

  List<FruitListView> get fruits => widget.character.fruits;

  bool get _canEatMore =>
      widget.character.maximumFruitCount > fruits.length &&
      widget.editButtonVisible;

  @override
  void dispose() {
    fruitNameController.dispose();
    super.dispose();
  }

  Map<FruitType, String> _fruitTypeMap(BuildContext context) => {
        FruitType.logia: AppLocalizations.of(context)!.logiaFruit,
        FruitType.zoan: AppLocalizations.of(context)!.zoanFruit,
        FruitType.ancientZoan: AppLocalizations.of(context)!.ancientZoanFruit,
        FruitType.mythicalZoan: AppLocalizations.of(context)!.mythicalZoanFruit,
        FruitType.artificialZoan:
            AppLocalizations.of(context)!.artificialZoanFruit,
        FruitType.paramecia: AppLocalizations.of(context)!.parameciaFruit,
      };

  void _onSearchChanged(String value) {
    selectedFruitId = null;
    setState(() {});
    if (value.isEmpty) {
      searchingFruitList = [];
      setState(() {});
      return;
    }
    fruitFilter.name = value;
    fruitFilter.languageCode = I18nHelper.getLanguageCode();
    widget.controller
        .listFruit(ListFruitRequest(
            pageSize: 5, pageIndex: 1, sortKeys: [], fruitFilter: fruitFilter))
        .then((r) {
      if (mounted) {
        setState(() => searchingFruitList = r!.fruits);
      }
    });
  }

  void _eatFruit() {
    final request = EatFruitRequest(
        characterId: widget.character.id, fruitId: selectedFruitId!);
    widget.controller.eatFruit(request).then((value) {
      if (!mounted) return;
      widget.onFruitEaten();
    });
  }

  @override
  Widget build(BuildContext context) =>
      widget.isNarrow ? _buildMobile(context) : _buildDesktop(context);

  // ── Mobile ─────────────────────────────────────────────────────────

  Widget _buildMobile(BuildContext context) {
    final fruitMap = _fruitTypeMap(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppLocalizations.of(context)!.devilFruit,
                style: OnepieceFonts.headerStyle.copyWith(fontSize: 16)),
            const SizedBox(height: 10),
            if (fruits.isNotEmpty)
              ...fruits.map((f) => Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => context.goNamed('fruitDetails',
                          extra: f.id,
                          pathParameters: {
                            'name': I18nHelper.getDisplayNameFromI18n(f.name!)
                          }),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        child: Row(children: [
                          Expanded(
                              child: Text(
                                  I18nHelper.getDisplayNameFromI18n(f.name!),
                                  style: OnepieceFonts.contentStyle)),
                          OnepieceTag.getFruitTag(
                              f.fruitType!, fruitMap[f.fruitType]!),
                        ]),
                      ),
                    ),
                  )),
            if (_canEatMore) ...[
              const SizedBox(height: 8),
              SizedBox(
                  height: 35,
                  child: TextFormField(
                    controller: fruitNameController,
                    decoration: InputDecoration(
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10),
                      disabledBorder: const OutlineInputBorder(
                          borderSide:
                              BorderSide(color: OnepieceColors.menuHoverColor)),
                      enabledBorder: const OutlineInputBorder(
                          borderSide:
                              BorderSide(color: OnepieceColors.menuHoverColor)),
                      focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                              color: OnepieceColors.fancyGreen, width: 2.2)),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      labelText: AppLocalizations.of(context)!.search,
                    ),
                    onChanged: _onSearchChanged,
                  )),
              if (searchingFruitList.isNotEmpty)
                Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: const BoxDecoration(
                        color: OnepieceColors.surface,
                        borderRadius: BorderRadius.all(Radius.circular(8))),
                    child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: searchingFruitList.length,
                        itemBuilder: (_, i) => _buildFruitSearchResultCard(
                            context: context,
                            fruit: searchingFruitList[i],
                            fruitMap: fruitMap))),
            ],
          ])),
    );
  }

  Widget _buildFruitSearchResultCard({
    required BuildContext context,
    required FruitListView fruit,
    required Map<FruitType, String> fruitMap,
  }) {
    final isSelected = selectedFruitId == fruit.id;
    final alreadyEaten = fruits.map((e) => e.id).contains(fruit.id);
    return Card(
      elevation: isSelected ? 2 : 0,
      margin: const EdgeInsets.fromLTRB(6, 6, 6, 2),
      color: isSelected
          ? OnepieceColors.liteFancyBlue.withValues(alpha: 0.65)
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected
              ? OnepieceColors.fancyBlue.withValues(alpha: 0.35)
              : OnepieceColors.menuHoverColor.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            hoverColor: OnepieceColors.liteFancyBlue,
            onTap: () {
              setState(() {
                selectedFruitId = isSelected ? null : fruit.id;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      I18nHelper.getDisplayNameFromI18n(fruit.name!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: isSelected
                          ? OnepieceFonts.contentStyleBold
                          : OnepieceFonts.contentStyle,
                    ),
                  ),
                  OnepieceTag.getFruitTag(
                      fruit.fruitType!, fruitMap[fruit.fruitType!]!),
                ],
              ),
            ),
          ),
          if (isSelected && !alreadyEaten)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: ElevatedButton(
                onPressed: () {
                  _eatFruit();
                  fruitNameController.text = '';
                  selectedFruitId = null;
                  searchingFruitList = [];
                  setState(() {});
                },
                child: Text(AppLocalizations.of(context)!.eat),
              ),
            ),
        ],
      ),
    );
  }

  // ── Desktop ────────────────────────────────────────────────────────

  Widget _buildDesktop(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSearchBar(context),
        if (fruits.isNotEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(widget.sideWidth, 8, 8, 8),
            child: _buildFruitList(context),
          ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final fruitMap = _fruitTypeMap(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.sideWidth),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                width: 160,
                child: Text(
                  AppLocalizations.of(context)!.devilFruit,
                  style: OnepieceFonts.headerStyle
                      .copyWith(fontSize: 19, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        if (_canEatMore)
          Padding(
            padding: EdgeInsets.fromLTRB(widget.sideWidth, 8, 8, 0),
            child: SizedBox(
              width: 200,
              height: 35,
              child: TextFormField(
                controller: fruitNameController,
                decoration: InputDecoration(
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  disabledBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: OnepieceColors.menuHoverColor)),
                  enabledBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: OnepieceColors.menuHoverColor)),
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                          color: OnepieceColors.fancyGreen, width: 2.2)),
                  prefixIcon: const Icon(Icons.search),
                  labelText: AppLocalizations.of(context)!.search,
                ),
                onChanged: _onSearchChanged,
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(widget.sideWidth, 8, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: widget.dividerWidth - widget.sideWidth - 16,
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: const BoxDecoration(
                    color: OnepieceColors.surface,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: searchingFruitList.length,
                    itemBuilder: (context, index) {
                      return _buildFruitSearchResultCard(
                          context: context,
                          fruit: searchingFruitList[index],
                          fruitMap: fruitMap);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFruitList(BuildContext context) {
    final fruitMap = _fruitTypeMap(context);
    return Container(
      width: widget.dividerWidth - widget.sideWidth - 16,
      decoration: const BoxDecoration(
        color: OnepieceColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: fruits.length,
        itemBuilder: (context, index) {
          var fruit = fruits[index];
          return Card(
            elevation: 0,
            margin: const EdgeInsets.fromLTRB(8, 6, 8, 2),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: OnepieceColors.menuHoverColor.withValues(alpha: 0.45),
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              hoverColor: OnepieceColors.liteFancyBlue,
              onTap: () {
                context.goNamed('fruitDetails',
                    extra: fruit.id,
                    pathParameters: {
                      'name': I18nHelper.getDisplayNameFromI18n(fruit.name!)
                    });
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        I18nHelper.getDisplayNameFromI18n(fruit.name!),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: OnepieceFonts.contentStyle,
                      ),
                    ),
                    OnepieceTag.getFruitTag(
                      fruit.fruitType!,
                      fruitMap[fruit.fruitType!]!,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
