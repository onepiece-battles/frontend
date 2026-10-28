import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';

import '../repository/character_dao.dart';
import '../repository/fruit_dao.dart';
import '../repository/group_dao.dart';
import 'resource_loading.dart';

/// Resolves older name-only URLs without sending a display name to a UUID API.
/// Current links already contain an ID and do not need this extra lookup.
class ResourceDetailRoute extends StatefulWidget {
  const ResourceDetailRoute(
      {super.key,
      required this.id,
      required this.type,
      required this.name,
      required this.page});

  final String? id;
  final String type;
  final String name;
  final Widget Function(String id) page;

  @override
  State<ResourceDetailRoute> createState() => _ResourceDetailRouteState();
}

class _ResourceDetailRouteState extends State<ResourceDetailRoute> {
  late Future<String?> _id;

  @override
  void initState() {
    super.initState();
    _id = _resolve();
  }

  @override
  void didUpdateWidget(covariant ResourceDetailRoute oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id ||
        oldWidget.name != widget.name ||
        oldWidget.type != widget.type) {
      _id = _resolve();
    }
  }

  Future<String?> _resolve() async {
    if (widget.id != null) return widget.id;
    final matches = <String>{};
    final type = widget.type;
    final name = widget.name;
    void match(String? id, I18nText? label) {
      if (id != null &&
          id.isNotEmpty &&
          [label?.zhCN, label?.enUS].any((value) =>
              value?.trim().toLowerCase() == name.trim().toLowerCase())) {
        matches.add(id);
      }
    }

    for (final language in [LanguageCode.zhCN, LanguageCode.enUS]) {
      switch (type) {
        case 'character':
          final result = await GetIt.I<CharacterDao>().listCharacter(
              ListCharacterRequest(
                  pageIndex: 1,
                  pageSize: 30,
                  sortKeys: [],
                  characterFilter:
                      CharacterFilter(name: name, languageCode: language)));
          for (final value in result?.characters ?? <CharacterListView>[]) {
            match(value.id, value.name);
          }
          break;
        case 'fruit':
          final result = await GetIt.I<FruitDao>().list(ListFruitRequest(
              pageIndex: 1,
              pageSize: 30,
              sortKeys: [],
              fruitFilter: FruitFilter(name: name, languageCode: language)));
          for (final value in result?.fruits ?? <FruitListView>[]) {
            match(value.id, value.name);
          }
          break;
        case 'group':
          final result = await GetIt.I<GroupDao>().listGroups(ListGroupRequest(
              pageIndex: 1,
              pageSize: 30,
              sortKeys: [],
              groupFilter: GroupFilter(name: name, languageCode: language)));
          for (final value in result?.groups ?? <GroupListView>[]) {
            match(value.id, value.name);
          }
          break;
      }
    }
    return matches.length == 1 ? matches.single : null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.id != null) return widget.page(widget.id!);
    return FutureBuilder<String?>(
        future: _id,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const ResourceLoading();
          }
          if (snapshot.hasError) {
            return ResourceEmptyState(
                failed: true,
                onRetry: () => setState(() {
                      _id = _resolve();
                    }));
          }
          final id = snapshot.data;
          return id == null ? const ResourceEmptyState() : widget.page(id);
        });
  }
}
