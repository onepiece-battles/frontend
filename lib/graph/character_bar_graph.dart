import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:one_piece_battles_flutter/graph/character_data.dart';
import '../constants/onepiece_colors.dart';
import '../utils/image_helper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CharacterBarGraph extends StatelessWidget {
  final CharacterData characterData;
  final bool symmetric;

  const CharacterBarGraph(
      {super.key, required this.characterData, required this.symmetric});

  @override
  Widget build(BuildContext context) {
    List<String> touchText = [
      AppLocalizations.of(context)!.characterAttack,
      AppLocalizations.of(context)!.characterDefense,
      AppLocalizations.of(context)!.characterIntelligence,
      AppLocalizations.of(context)!.characterSpeed,
      AppLocalizations.of(context)!.characterBlood,
      AppLocalizations.of(context)!.characterEnergy,
    ];
    List<int> max = [1500, 1400, 300, 300, 18000, 300];
    List<String> svgPath = [
      'images/character_digits_icon/attack.svg',
      'images/character_digits_icon/defense.svg',
      'images/character_digits_icon/intelligence.svg',
      'images/character_digits_icon/speed.svg',
      'images/character_digits_icon/blood.svg',
      'images/character_digits_icon/energy.svg'
    ];

    characterData.initBarData();
    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          show: true,
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return RotatedBox(
                    quarterTurns: -1,
                    child: ImageHelper.getTextFormFieldIcon(
                        svgPath[value.toInt()], true, null),
                  );
                }),
          ),
        ),
        barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
                fitInsideVertically: true,
                tooltipBgColor: OnepieceColors.fancyBlue,
                tooltipPadding: const EdgeInsets.all(5),
                maxContentWidth: 50,
                rotateAngle: 270,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                      "${touchText[groupIndex]} ${(rod.toY * max[groupIndex]).toInt().toString()}",
                      OnepieceFonts.superSmallContentStyleWhite);
                })),
        borderData: FlBorderData(show: false),
        barGroups: characterData.barData
            .map(
              (data) => BarChartGroupData(
                x: data.x,
                barRods: [
                  BarChartRodData(
                    toY: data.y / data.yMax,
                    color: OnepieceColors.fancyBlue,
                    width: 15,
                    borderRadius: BorderRadius.circular(4),
                    backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: 1,
                        color: OnepieceColors.liteFancyBlue),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}
