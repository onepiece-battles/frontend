import 'package:flutter/material.dart';
import '../../components/resource_detail_layout.dart';
import '../../components/image_lazy_loader.dart';
import '../../constants/onepiece_colors.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:openapi/api.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/i18n_helper.dart';
import '../../utils/permission_check.dart';
import '../../utils/responsive_breakpoints.dart';
import 'character_detail_controller.dart';
import 'widgets/character_battles_section.dart';
import 'widgets/character_groups_section.dart';
import 'widgets/character_fruits_section.dart';
import 'widgets/character_combat_info_section.dart';
import 'widgets/character_basic_info_section.dart';

GetIt getIt = GetIt.instance;

class CharacterDetail extends StatefulWidget {
  final String characterId;

  const CharacterDetail({super.key, required this.characterId});

  @override
  State<CharacterDetail> createState() => _CharacterDetailState();
}

class _CharacterDetailState extends State<CharacterDetail> {
  final CharacterDetailController _controller = CharacterDetailController();
  ScrollController verticalController = ScrollController();

  @override
  void dispose() {
    verticalController.dispose();
    _controller.dispose();
    super.dispose();
  }

  double dividerWidth = 860;
  double sideWidth = 50;

  // initial date
  late Future<CharacterFullView?> _characterFuture;
  String? _preparedCharacterId;
  late CharacterFullView character;
  List<BattleListView> battles = [];
  List<FruitListView> fruits = [];
  List<GroupForCharacterView> groups = [];

  bool _editButtonVisible = false;

  @override
  void initState() {
    super.initState();
    _characterFuture = _loadData();
  }

  @override
  void didUpdateWidget(covariant CharacterDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.characterId != widget.characterId) {
      _preparedCharacterId = null;
      _characterFuture = _loadData();
    }
  }

  Future<CharacterFullView?> _loadData() {
    return _controller.getCharacter(
        GetCharacterFullViewRequest(characterId: widget.characterId));
  }

  void _refreshCharacterData() {
    _preparedCharacterId = null;
    _characterFuture = _loadData();
  }

  bool _updateData(CharacterFullView characterFullView) {
    if (_preparedCharacterId == characterFullView.id) return false;
    _preparedCharacterId = characterFullView.id;
    character = characterFullView;
    battles = characterFullView.battles;
    fruits = characterFullView.fruits;
    groups = characterFullView.groups;
    _editButtonVisible = (PermissionCheck.checkPermission(
                getIt<User>().loginRoleResourcesPermissionMap,
                ResourceType.CHARACTER,
                Permission.UPDATE) &&
            PermissionCheck.isMyResource(
                character.creationRecord!.userId!,
                character.creationRecord!.roleId!,
                getIt<User>().id,
                getIt<User>().loginRoleId!)) ||
        getIt<User>().loginRole == UserRole.NIKA;
    // nika role has the edit permission for all resources
    if (getIt<User>().loginRole == UserRole.NIKA) {
      _editButtonVisible = true;
    }
    return true;
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        controller: verticalController,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CharacterBasicInfoSection(
              character: character,
              editButtonVisible: _editButtonVisible,
              controller: _controller,
              isNarrow: true),
          const SizedBox(height: 12),
          CharacterCombatInfoSection(
              character: character,
              editButtonVisible: _editButtonVisible,
              controller: _controller,
              isNarrow: true),
          const SizedBox(height: 12),
          CharacterFruitsSection(
              character: character,
              editButtonVisible: _editButtonVisible,
              controller: _controller,
              onFruitEaten: () {
                setState(() {
                  _refreshCharacterData();
                });
              },
              isNarrow: true),
          if (fruits.isNotEmpty) const SizedBox(height: 12),
          CharacterGroupsSection(groups: groups, isNarrow: true),
          const SizedBox(height: 12),
          CharacterBattlesSection(character: character, isNarrow: true),
        ]),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return ResourceDetailPage(
        controller: verticalController,
        header: DetailHero(
            kind: loc.character,
            title: I18nHelper.getDisplayNameFromI18n(character.name),
            avatar: ImageLazyLoader(
                uriProvider: () => character.imageUri ?? '',
                width: 88,
                borderWidth: 0,
                borderRadios: 88,
                fullImage: true),
            metrics: [
              DetailValue(loc.combatPower, '${character.score}',
                  valueStyle: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: OnepieceColors.primaryLabel)),
              DetailValue(loc.bounty, '${character.bounty ?? '—'}',
                  valueStyle: OnepieceFonts.bountyStyle.copyWith(fontSize: 26)),
              DetailValue(loc.devilFruit,
                  '${fruits.length} / ${character.maximumFruitCount}'),
            ]),
        sections: (context, width) => [
              CharacterBasicInfoSection(
                  character: character,
                  editButtonVisible: _editButtonVisible,
                  controller: _controller,
                  isNarrow: false,
                  sideWidth: 0),
              CharacterCombatInfoSection(
                  character: character,
                  editButtonVisible: _editButtonVisible,
                  controller: _controller,
                  isNarrow: false,
                  sideWidth: 0),
              DetailSection(
                  child: CharacterFruitsSection(
                      character: character,
                      editButtonVisible: _editButtonVisible,
                      controller: _controller,
                      onFruitEaten: () => setState(_refreshCharacterData),
                      isNarrow: true)),
              DetailSection(
                  child:
                      CharacterGroupsSection(groups: groups, isNarrow: true)),
              DetailSection(
                  child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                          width: width - 48 < 860 ? 860 : width - 48,
                          child: CharacterBattlesSection(
                              character: character,
                              isNarrow: false,
                              sideWidth: 0,
                              dividerWidth:
                                  width - 48 < 860 ? 860 : width - 48)))),
            ]);
  }

  List<Widget> _stackChildren(BuildContext context, bool isNarrow) {
    final content = Positioned.fill(
        child: isNarrow
            ? _buildMobileLayout(context)
            : _buildDesktopLayout(context));
    return [
      content,
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
                  message: character.previousCharacter == null
                      ? ""
                      : I18nHelper.getDisplayNameFromI18n(
                          character.previousCharacter!.name),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: OnepieceColors.surface,
                        foregroundColor: OnepieceColors.fancyBlue),
                    onPressed: character.previousCharacter == null
                        ? null
                        : () => context.goNamed('characterDetails',
                                extra: character.previousCharacter!.id,
                                pathParameters: {
                                  'name': I18nHelper.getDisplayNameFromI18n(
                                      character.previousCharacter!.name)
                                }),
                    child: const Icon(Icons.arrow_back),
                  ),
                ),
                Tooltip(
                  message: character.nextCharacter == null
                      ? ""
                      : I18nHelper.getDisplayNameFromI18n(
                          character.nextCharacter!.name),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: OnepieceColors.surface,
                        foregroundColor: OnepieceColors.fancyBlue),
                    onPressed: character.nextCharacter == null
                        ? null
                        : () => context.goNamed('characterDetails',
                                extra: character.nextCharacter!.id,
                                pathParameters: {
                                  'name': I18nHelper.getDisplayNameFromI18n(
                                      character.nextCharacter!.name)
                                }),
                    child: const Icon(Icons.arrow_forward),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _characterFuture,
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.data == null) {
              return const SizedBox.shrink();
            }
            _updateData(snapshot.data);
            return LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow =
                    ResponsiveBreakpoints.isMobileFromConstraints(constraints);
                dividerWidth = isNarrow ? constraints.maxWidth - 30 : 860;
                sideWidth = isNarrow ? 8.0 : 50;
                return Stack(
                  children: _stackChildren(context, isNarrow),
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
}
