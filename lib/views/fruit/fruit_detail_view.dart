import '../../components/resource_loading.dart';
import 'package:flutter/material.dart';
import '../../components/resource_detail_layout.dart';
import '../../constants/onepiece_colors.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'fruit_detail_controller.dart';
import 'widgets/fruit_combat_info_section.dart';
import 'widgets/fruit_basic_info_section.dart';
import 'widgets/fruit_characters_section.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:openapi/api.dart';
import '../../l10n/app_localizations.dart';
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
            fruitFullView.creationRecord?.userId,
            fruitFullView.creationRecord?.roleId,
            getIt<User>().id,
            getIt<User>().loginRoleId);
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
        if (characters.isNotEmpty) ...[
          const SizedBox(height: 12),
          FruitCharactersSection(characters: characters, isNarrow: true),
        ],
      ]),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return ResourceDetailPage(
        controller: verticalController,
        header: DetailHero(
            kind: loc.devilFruit,
            title: I18nHelper.getDisplayNameFromI18n(fruitFullView.name),
            avatar: Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                    color: OnepieceColors.surface, shape: BoxShape.circle),
                child: const Icon(Icons.spa_outlined,
                    color: OnepieceColors.fancyBlue, size: 38)),
            metrics: [
              DetailValue(
                  loc.energyConsume, '${fruitFullView.energyConsume ?? '—'}'),
              DetailValue(loc.owner, '${characters.length}')
            ]),
        sections: (context, width) => [
              FruitBasicInfoSection(
                  fruit: fruitFullView,
                  editButtonVisible: _editButtonVisible,
                  controller: _controller,
                  isNarrow: false,
                  sideWidth: 0),
              FruitCombatInfoSection(
                  fruit: fruitFullView,
                  editButtonVisible: _editButtonVisible,
                  controller: _controller,
                  isNarrow: false,
                  sideWidth: 0),
              FruitCharactersSection(characters: characters, isNarrow: false),
            ]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FruitFullView?>(
        future: _fruitFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final fruit = snapshot.data;
            if (fruit == null) {
              return ResourceEmptyState(
                  failed: true,
                  onRetry: () => setState(() {
                        _fruitFuture = _loadData();
                      }));
            }
            _updateData(fruit);
            return LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow =
                    ResponsiveBreakpoints.isMobileFromConstraints(constraints);
                return Stack(
                  children: [
                    if (isNarrow)
                      _buildMobileLayout(context)
                    else
                      Positioned.fill(child: _buildDesktopLayout(context)),
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
                                    style: ElevatedButton.styleFrom(
                                        elevation: 0,
                                        backgroundColor: OnepieceColors.surface,
                                        foregroundColor:
                                            OnepieceColors.fancyBlue),
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
                                    style: ElevatedButton.styleFrom(
                                        elevation: 0,
                                        backgroundColor: OnepieceColors.surface,
                                        foregroundColor:
                                            OnepieceColors.fancyBlue),
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
            return const ResourceLoading();
          }
        });
  }
}
