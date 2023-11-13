import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';
import '../constants/onepiece_fonts.dart';
import '../repository/fruit_dao.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'create_battle_view.dart';

GetIt getIt = GetIt.instance;

class FruitView extends StatefulWidget {
  const FruitView({super.key});

  @override
  State<FruitView> createState() => _FruitViewState();
}

class _FruitViewState extends State<FruitView> {
  List<Fruit> currentFruitList = [];
  FruitFilter fruitFilter = FruitFilter();
  List<FruitType> selectedFruitTypes = [];
  List<FruitSortableField> sortKeys = [];

  TextEditingController pageNumberController = TextEditingController(text: "1");

  // sorting icon map
  Map<SortOrder?, String> sortOrderToPath = const {
    null: 'images/svgs/sort-solid.svg',
    SortOrder.ASC: 'images/svgs/sort-up-solid.svg',
    SortOrder.DESC: 'images/svgs/sort-down-solid.svg'
  };
  int selectedPageIndex = 1;
  int pageNum = 1;
  int pageSize = 10;
  int totalSize = 0;
  bool preButtonEnabled = false;
  bool nextButtonEnabled = false;
  bool confirmButtonEnabled = false;
  @override
  void initState() {
    super.initState();
    _search();
  }

  void _search() {
    ListFruitRequest request = ListFruitRequest(
        pageSize: pageSize,
        pageIndex: selectedPageIndex,
        sortKeys: sortKeys,
        fruitFilter: fruitFilter);
    Future<ListFruitResponse?> response =
    getIt<FruitDao>().list(request);
    response.then((value) => {
      setState(() {
        currentFruitList = value!.fruits;
        totalSize = value.totalSize!;
        pageNum = (totalSize / 10).ceil();
        pageNumberController.text = selectedPageIndex.toString();
        if (selectedPageIndex <= 1) {
          preButtonEnabled = false;
        } else {
          preButtonEnabled = true;
        }
        if (selectedPageIndex >= pageNum) {
          nextButtonEnabled = false;
        } else {
          nextButtonEnabled = true;
        }
      })
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _getHeaderText(context),
        _getControlRow(context),
        _getFruitsTable(context),
    ],);
  }


  Widget _getHeaderText(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      child: Text(
        AppLocalizations.of(context)!.battle,
        style: OnepieceFonts.headerStyle,
      ),
    );
  }

  Widget _getControlRow(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0,0,6,6),
            child: SizedBox(
              height: 33,
              child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: ((context) {
                        return const CreateBattleView();
                      }),
                    );
                  },
                  child: Text(AppLocalizations.of(context)!.createBattle)),
            ),
          ),
          // battle type filter
          _getBattleTypeFilter(context),
          // battle status filter
          _getBattleStatusFilter(context)
        ],
      ),
    );
  }
}
