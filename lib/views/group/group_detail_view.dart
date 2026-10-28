import '../../components/resource_loading.dart';
import 'package:flutter/material.dart';
import '../../components/resource_detail_layout.dart';
import '../../components/image_lazy_loader.dart';
import '../../constants/onepiece_colors.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:openapi/api.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/responsive_breakpoints.dart';
import '../../utils/permission_check.dart';
import 'group_detail_controller.dart';
import 'widgets/group_basic_info_section.dart';
import 'widgets/group_members_panel.dart';

GetIt getIt = GetIt.instance;

class GroupDetailView extends StatefulWidget {
  final String groupId;

  const GroupDetailView({super.key, required this.groupId});

  @override
  State<GroupDetailView> createState() => _GroupDetailViewState();
}

class _GroupDetailViewState extends State<GroupDetailView> {
  ScrollController scrollController = ScrollController();
  final ScrollController _pageScrollController = ScrollController();
  late Future<GroupFullView?> _groupFuture;
  String? _preparedGroupId;
  late GroupFullView groupFullView;
  bool _editButtonVisible = false;
  final GroupDetailController _controller = GroupDetailController();

  @override
  void initState() {
    super.initState();
    _groupFuture = _loadData();
  }

  @override
  void didUpdateWidget(covariant GroupDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) {
      _preparedGroupId = null;
      _groupFuture = _loadData();
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    _pageScrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<GroupFullView?> _loadData() {
    return _controller.getGroupFullView(GetGroupRequest(id: widget.groupId));
  }

  void _prepareData(GroupFullView group) {
    if (_preparedGroupId == group.id) return;
    _preparedGroupId = group.id;
    groupFullView = group;
    _editButtonVisible = PermissionCheck.checkPermission(
            getIt<User>().loginRoleResourcesPermissionMap,
            ResourceType.GROUP,
            Permission.UPDATE) &&
        PermissionCheck.isMyResource(
            groupFullView.creationRecord?.userId,
            groupFullView.creationRecord?.roleId,
            getIt<User>().id,
            getIt<User>().loginRoleId);
    // nika role has the edit permission for all resources
    if (getIt<User>().loginRole == UserRole.NIKA) {
      _editButtonVisible = true;
    }
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      controller: _pageScrollController,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GroupBasicInfoSection(
          group: groupFullView,
          editButtonVisible: _editButtonVisible,
          controller: _controller,
          isNarrow: true,
        ),
        const SizedBox(height: 12),
        // Members
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GroupMembersPanel(
            groupFullView: groupFullView,
            controller: _controller,
            pageScrollController: _pageScrollController,
            editButtonVisible: _editButtonVisible,
          ),
        ),
      ]),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return ResourceDetailPage(
        controller: _pageScrollController,
        header: DetailHero(
            kind: loc.group,
            title: I18nHelper.getDisplayNameFromI18n(groupFullView.name),
            avatar: ImageLazyLoader(
                uriProvider: () => groupFullView.imageUri ?? '',
                width: 88,
                borderWidth: 0,
                borderRadios: 88,
                fullImage: true),
            metrics: [
              DetailValue(
                  loc.groupMember, '${groupFullView.characters.length}'),
              DetailValue(loc.group, '${groupFullView.subGroups.length}')
            ]),
        sections: (context, width) => [
              GroupBasicInfoSection(
                  group: groupFullView,
                  editButtonVisible: _editButtonVisible,
                  controller: _controller,
                  isNarrow: false),
              GroupMembersPanel(
                  groupFullView: groupFullView,
                  controller: _controller,
                  pageScrollController: _pageScrollController,
                  editButtonVisible: _editButtonVisible),
            ]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _groupFuture,
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data == null) {
            return ResourceEmptyState(
                failed: true,
                onRetry: () => setState(() {
                      _groupFuture = _loadData();
                    }));
          }
          _prepareData(snapshot.data);
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
                              message: groupFullView.previousGroup == null
                                  ? ""
                                  : I18nHelper.getDisplayNameFromI18n(
                                      groupFullView.previousGroup!.name),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    backgroundColor: OnepieceColors.surface,
                                    foregroundColor: OnepieceColors.fancyBlue),
                                onPressed: groupFullView.previousGroup == null
                                    ? null
                                    : () {
                                        context.goNamed('groupDetails',
                                            extra:
                                                groupFullView.previousGroup!.id,
                                            pathParameters: {
                                              'name': I18nHelper
                                                  .getDisplayNameFromI18n(
                                                      groupFullView
                                                          .previousGroup!.name)
                                            });
                                      },
                                child: const Icon(Icons.arrow_back),
                              ),
                            ),
                            Tooltip(
                              message: groupFullView.nextGroup == null
                                  ? ""
                                  : I18nHelper.getDisplayNameFromI18n(
                                      groupFullView.nextGroup!.name),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    backgroundColor: OnepieceColors.surface,
                                    foregroundColor: OnepieceColors.fancyBlue),
                                onPressed: groupFullView.nextGroup == null
                                    ? null
                                    : () {
                                        context.goNamed('groupDetails',
                                            extra: groupFullView.nextGroup!.id,
                                            pathParameters: {
                                              'name': I18nHelper
                                                  .getDisplayNameFromI18n(
                                                      groupFullView
                                                          .nextGroup!.name)
                                            });
                                      },
                                child: const Icon(Icons.arrow_forward),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              );
            },
          );
        } else {
          return const ResourceLoading();
        }
      },
    );
  }
}
