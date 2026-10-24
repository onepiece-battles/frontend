import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'fruit_detail_controller.dart';
import 'widgets/fruit_combat_info_section.dart';
import 'widgets/fruit_basic_info_section.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:openapi/api.dart';
import '../../components/image_lazy_loader.dart';
import '../../constants/onepiece_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../constants/onepiece_tag.dart';
import '../../utils/image_helper.dart';
import '../../utils/nested_scroll_helper.dart';
import '../../utils/permission_check.dart';
import '../../utils/responsive_breakpoints.dart';

GetIt getIt = GetIt.instance;

class FruitDetailView extends StatefulWidget {
  final String fruitId;

  const FruitDetailView({super.key, required this.fruitId});

  @override
  State<FruitDetailView> createState() => _FruitDetailViewState();
}

class _FruitDetailViewState extends State<FruitDetailView> {
  late FruitFullView fruitFullView;
  late Future<FruitFullView?> _fruitFuture;
  String? _hydratedFruitId;
  List<CharacterInFruitView> characters = [];
  final FruitDetailController _controller = FruitDetailController();
  final ScrollController horizontalController = ScrollController();
  final ScrollController verticalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fruitFuture = _loadData();
  }

  @override
  void didUpdateWidget(covariant FruitDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fruitId != widget.fruitId) {
      _hydratedFruitId = null;
      _fruitFuture = _loadData();
    }
  }

  @override
  void dispose() {
    horizontalController.dispose();
    verticalController.dispose();
    _controller.dispose();
    super.dispose();
  }

  bool _editButtonVisible = false;

  Future<FruitFullView?> _loadData() {
    return _controller.get(GetFruitRequest(fruitId: widget.fruitId));
  }

  // will be executed every time page refreshes
  void _updateData(FruitFullView fruitFullView) {
    if (_hydratedFruitId == fruitFullView.id) {
      this.fruitFullView = fruitFullView;
      characters = fruitFullView.characters;
      return;
    }
    _hydratedFruitId = fruitFullView.id;
    // 1. update data
    this.fruitFullView = fruitFullView;
    characters = fruitFullView.characters;

    // update visibility info
    _editButtonVisible = PermissionCheck.checkPermission(
            getIt<User>().loginRoleResourcesPermissionMap,
            ResourceType.FRUIT,
            Permission.UPDATE) &&
        PermissionCheck.isMyResource(
            fruitFullView.creationRecord!.userId!,
            fruitFullView.creationRecord!.roleId!,
            getIt<User>().id,
            getIt<User>().loginRoleId!);
    // nika role has the edit permission for all resources
    if (getIt<User>().loginRole == UserRole.NIKA) {
      _editButtonVisible = true;
    }
  }

  // ── Mobile card layout ────────────────────────────────────────────

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      controller: verticalController,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FruitBasicInfoSection(
          fruit: fruitFullView,
          editButtonVisible: _editButtonVisible,
          controller: _controller,
          isNarrow: true,
        ),
        const SizedBox(height: 12),
        FruitCombatInfoSection(
          fruit: fruitFullView,
          editButtonVisible: _editButtonVisible,
          controller: _controller,
          isNarrow: true,
        ),
        // Characters
        if (characters.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.character,
                        style:
                            OnepieceFonts.headerStyle.copyWith(fontSize: 16)),
                    const SizedBox(height: 10),
                    ...characters.map((c) => Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => context.goNamed('characterDetails',
                                extra: c.id,
                                pathParameters: {
                                  'name':
                                      I18nHelper.getDisplayNameFromI18n(c.name)
                                }),
                            child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                child: Row(children: [
                                  ImageLazyLoader(
                                      key: ValueKey(c.imageUri),
                                      uriProvider: () => c.imageUri!,
                                      width: 36,
                                      borderWidth: 1.5,
                                      borderRadios: 36),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: Text(
                                          I18nHelper.getDisplayNameFromI18n(
                                              c.name),
                                          style: OnepieceFonts.contentStyle)),
                                ])),
                          ),
                        )),
                  ])),
        ],
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FruitFullView?>(
        future: _fruitFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final fruit = snapshot.data;
            if (fruit == null) {
              return Center(
                child: Text(
                  AppLocalizations.of(context)!.loading,
                  style: OnepieceFonts.loadingFont,
                ),
              );
            }
            _updateData(fruit);
            return LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow =
                    ResponsiveBreakpoints.isMobileFromConstraints(constraints);
                final divW = isNarrow ? constraints.maxWidth - 30 : 800.0;
                final sideW = isNarrow ? 8.0 : 50.0;
                return Stack(
                  children: [
                    if (isNarrow)
                      _buildMobileLayout(context)
                    else
                      SingleChildScrollView(
                        controller: verticalController,
                        scrollDirection: Axis.vertical,
                        child: Center(
                          child: NestedHorizontalScrollView(
                            controller: horizontalController,
                            verticalParentController: verticalController,
                            child: SizedBox(
                              width: divW,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FruitBasicInfoSection(
                                    fruit: fruitFullView,
                                    editButtonVisible: _editButtonVisible,
                                    controller: _controller,
                                    isNarrow: false,
                                    sideWidth: sideW,
                                  ),
                                  const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 8),
                                      child: Divider(
                                          color: Colors.grey, thickness: 1)),
                                  FruitCombatInfoSection(
                                    fruit: fruitFullView,
                                    editButtonVisible: _editButtonVisible,
                                    controller: _controller,
                                    isNarrow: false,
                                    sideWidth: sideW,
                                  ),
                                  const SizedBox(
                                      height: 30,
                                      child: Divider(
                                          color: Colors.grey, thickness: 1)),
                                  Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: sideW),
                                      child: _getCharacterList(context)),
                                  const SizedBox(height: 60),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Tooltip(
                                  message: fruitFullView.previousFruit == null
                                      ? ""
                                      : I18nHelper.getDisplayNameFromI18n(
                                          fruitFullView.previousFruit!.name),
                                  child: ElevatedButton(
                                    onPressed:
                                        fruitFullView.previousFruit == null
                                            ? null
                                            : () {
                                                context.goNamed('fruitDetails',
                                                    extra: fruitFullView
                                                        .previousFruit!.id,
                                                    pathParameters: {
                                                      'name': I18nHelper
                                                          .getDisplayNameFromI18n(
                                                              fruitFullView
                                                                  .previousFruit!
                                                                  .name)
                                                    });
                                              },
                                    child: const Icon(Icons.arrow_back),
                                  ),
                                ),
                                Tooltip(
                                  message: fruitFullView.nextFruit == null
                                      ? ""
                                      : I18nHelper.getDisplayNameFromI18n(
                                          fruitFullView.nextFruit!.name),
                                  child: ElevatedButton(
                                    onPressed: fruitFullView.nextFruit == null
                                        ? null
                                        : () {
                                            context.goNamed('fruitDetails',
                                                extra:
                                                    fruitFullView.nextFruit!.id,
                                                pathParameters: {
                                                  'name': I18nHelper
                                                      .getDisplayNameFromI18n(
                                                          fruitFullView
                                                              .nextFruit!.name)
                                                });
                                          },
                                    child: const Icon(Icons.arrow_forward),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                  ],
                );
              },
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

  Widget _getCharacterList(BuildContext context) {
    Map<bool, String> wakeUpToDisplayValue = {
      true: AppLocalizations.of(context)!.wakeUp,
      false: AppLocalizations.of(context)!.sleep
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.owner,
          style: OnepieceFonts.headerStyle,
        ),
        if (characters.isEmpty)
          Text(
            AppLocalizations.of(context)!.currentlyNone,
            style: OnepieceFonts.fancyBlueHintFont,
          ),
        const SizedBox(
          height: 30,
        ),
        SizedBox(
          width: 600,
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
                  child: ExpansionTile(
                    childrenPadding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                    expandedAlignment: Alignment.centerLeft,
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                              child: InkWell(
                                hoverColor: Colors.transparent,
                                splashColor: Colors.transparent,
                                onTap: () {
                                  context.goNamed('characterDetails',
                                      extra: character.id,
                                      pathParameters: {
                                        'name':
                                            I18nHelper.getDisplayNameFromI18n(
                                                character.name)
                                      });
                                },
                                child: ImageLazyLoader(
                                    key: UniqueKey(),
                                    uriProvider: () => character.imageUri!,
                                    width: 40,
                                    borderWidth: 1.5,
                                    borderRadios: 40),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Text(I18nHelper.getDisplayNameFromI18n(
                                character.name)),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: OnepieceTag.getWakeUpTag(
                            character.wakeUp!,
                            wakeUpToDisplayValue[character.wakeUp!]!,
                          ),
                        ),
                      ],
                    ),
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              ImageHelper.getTextFormFieldIcon(
                                  'images/character_digits_icon/attack.svg',
                                  true,
                                  21),
                              const SizedBox(
                                width: 10,
                              ),
                              SizedBox(
                                  width: 80,
                                  child: Text(
                                    "${character.baseAttack}",
                                    style: OnepieceFonts.boldFancyBlueHintFont,
                                  )),
                              const Padding(
                                padding: EdgeInsets.only(right: 50.0),
                                child: Icon(Icons.arrow_right_alt_outlined),
                              ),
                              SizedBox(
                                  width: 80,
                                  child: Text(
                                    "${character.attack}",
                                    style: OnepieceFonts.boldFancyBlueHintFont,
                                  ))
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              ImageHelper.getTextFormFieldIcon(
                                  'images/character_digits_icon/defense.svg',
                                  true,
                                  22),
                              const SizedBox(
                                width: 10,
                              ),
                              SizedBox(
                                  width: 80,
                                  child: Text(
                                    "${character.baseDefense}",
                                    style: OnepieceFonts.boldFancyBlueHintFont,
                                  )),
                              const Padding(
                                padding: EdgeInsets.only(right: 50.0),
                                child: Icon(Icons.arrow_right_alt_outlined),
                              ),
                              SizedBox(
                                  width: 80,
                                  child: Text(
                                    "${character.defense}",
                                    style: OnepieceFonts.boldFancyBlueHintFont,
                                  ))
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              ImageHelper.getTextFormFieldIcon(
                                  'images/character_digits_icon/intelligence.svg',
                                  true,
                                  22),
                              const SizedBox(
                                width: 10,
                              ),
                              SizedBox(
                                  width: 80,
                                  child: Text(
                                    "${character.baseIntelligence}",
                                    style: OnepieceFonts.boldFancyBlueHintFont,
                                  )),
                              const Padding(
                                padding: EdgeInsets.only(right: 50.0),
                                child: Icon(Icons.arrow_right_alt_outlined),
                              ),
                              SizedBox(
                                  width: 80,
                                  child: Text(
                                    "${character.intelligence}",
                                    style: OnepieceFonts.boldFancyBlueHintFont,
                                  ))
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              ImageHelper.getTextFormFieldIcon(
                                  'images/character_digits_icon/speed.svg',
                                  true,
                                  22),
                              const SizedBox(
                                width: 10,
                              ),
                              SizedBox(
                                  width: 80,
                                  child: Text(
                                    "${character.baseSpeed}",
                                    style: OnepieceFonts.boldFancyBlueHintFont,
                                  )),
                              const Padding(
                                padding: EdgeInsets.only(right: 50.0),
                                child: Icon(Icons.arrow_right_alt_outlined),
                              ),
                              SizedBox(
                                  width: 80,
                                  child: Text(
                                    "${character.speed}",
                                    style: OnepieceFonts.boldFancyBlueHintFont,
                                  ))
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              ImageHelper.getTextFormFieldIcon(
                                  'images/character_digits_icon/blood.svg',
                                  true,
                                  22),
                              const SizedBox(
                                width: 10,
                              ),
                              SizedBox(
                                  width: 80,
                                  child: Text(
                                    "${character.baseBlood}",
                                    style: OnepieceFonts.boldFancyBlueHintFont,
                                  )),
                              const Padding(
                                padding: EdgeInsets.only(right: 50.0),
                                child: Icon(Icons.arrow_right_alt_outlined),
                              ),
                              SizedBox(
                                  width: 80,
                                  child: Text(
                                    "${character.blood}",
                                    style: OnepieceFonts.boldFancyBlueHintFont,
                                  ))
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              ImageHelper.getTextFormFieldIcon(
                                  'images/character_digits_icon/group_gain.svg',
                                  true,
                                  20),
                              const SizedBox(
                                width: 10,
                              ),
                              SizedBox(
                                  width: 80,
                                  child: Text(
                                    "${character.baseGroupGain}",
                                    style: OnepieceFonts.boldFancyBlueHintFont,
                                  )),
                              const Padding(
                                padding: EdgeInsets.only(right: 50.0),
                                child: Icon(Icons.arrow_right_alt_outlined),
                              ),
                              SizedBox(
                                  width: 80,
                                  child: Text(
                                    "${character.groupGain}",
                                    style: OnepieceFonts.boldFancyBlueHintFont,
                                  ))
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
