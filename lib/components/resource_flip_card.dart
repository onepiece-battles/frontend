import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/onepiece_colors.dart';

/// Keeps the front and back in the same list slot while rotating the card.
/// The face swaps edge-on, so neither side is ever mirrored to the reader.
class ResourceFlipCard extends StatelessWidget {
  const ResourceFlipCard({
    super.key,
    required this.flipped,
    required this.front,
    required this.back,
    this.baseHeight = 225,
  });

  final bool flipped;
  final Widget front;
  final Widget back;
  final double baseHeight;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final height = baseHeight + (textScale - 1).clamp(0.0, 1.0) * 130;
    return SizedBox(
      height: height,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: flipped ? 1 : 0),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
        builder: (context, progress, _) {
          final showingBack = progress >= 0.5;
          final angle =
              showingBack ? math.pi * (progress - 1) : math.pi * progress;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: showingBack ? back : front,
          );
        },
      ),
    );
  }
}

/// One label→value pair for the compact number grid on a card's detailed side.
class ResourceNumber {
  const ResourceNumber(this.label, this.value);

  final String label;
  final String value;
}

/// A tight label→value grid for the flipped (detailed) side of a card. Lays
/// [items] out across [columns] columns; labels ellipsize and values use
/// tabular figures, so the grid stays aligned in both Chinese and English.
class ResourceNumberGrid extends StatelessWidget {
  const ResourceNumberGrid({
    super.key,
    required this.items,
    this.columns = 2,
    this.rowGap = 3,
    this.columnGap = 14,
    this.fontSize = 11,
  });

  final List<ResourceNumber> items;
  final int columns;
  final double rowGap;
  final double columnGap;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += columns) {
      final cells = <Widget>[];
      for (var c = 0; c < columns; c++) {
        if (c > 0) cells.add(SizedBox(width: columnGap));
        final index = i + c;
        cells.add(Expanded(
          child: index < items.length
              ? _cell(items[index])
              : const SizedBox.shrink(),
        ));
      }
      if (rows.isNotEmpty) rows.add(SizedBox(height: rowGap));
      rows.add(Row(children: cells));
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  Widget _cell(ResourceNumber item) {
    return Row(children: [
      Expanded(
        child: Text(item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: fontSize, color: OnepieceColors.secondaryLabel)),
      ),
      const SizedBox(width: 6),
      Text(item.value,
          maxLines: 1,
          style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: OnepieceColors.primaryLabel)),
    ]);
  }
}

/// One labelled stat bar: a value shown both as a filled track (relative
/// magnitude across the stat's own range) and as its exact number.
class ResourceStatBar {
  const ResourceStatBar(this.label, this.value, this.fraction);

  final String label;
  final String value;

  /// 0‥1 fill, already normalised by the caller against the stat's range.
  final double fraction;
}

class ResourceStatBars extends StatelessWidget {
  const ResourceStatBars({
    super.key,
    required this.bars,
    this.labelWidth = 62,
    this.gap = 7,
  });

  final List<ResourceStatBar> bars;
  final double labelWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < bars.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          _row(bars[i]),
        ],
      ],
    );
  }

  Widget _row(ResourceStatBar bar) {
    return Row(children: [
      SizedBox(
        width: labelWidth,
        child: Text(bar.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 12, color: OnepieceColors.secondaryLabel)),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Stack(children: [
            Container(height: 6, color: OnepieceColors.surface),
            FractionallySizedBox(
              widthFactor: bar.fraction.clamp(0.0, 1.0),
              child: Container(height: 6, color: OnepieceColors.fancyBlue),
            ),
          ]),
        ),
      ),
      const SizedBox(width: 10),
      SizedBox(
        width: 40,
        child: Text(bar.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
                color: OnepieceColors.primaryLabel)),
      ),
    ]);
  }
}

/// A small label + value pill used for the secondary stats that don't warrant
/// a bar (crew gain, fruit limit, energy, …).
class ResourceMetaChip {
  const ResourceMetaChip(this.label, this.value);

  final String label;
  final String value;
}

class ResourceMetaChips extends StatelessWidget {
  const ResourceMetaChips({super.key, required this.chips});

  final List<ResourceMetaChip> chips;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final chip in chips)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: OnepieceColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: RichText(
              text: TextSpan(children: [
                TextSpan(
                    text: '${chip.label}  ',
                    style: const TextStyle(
                        fontSize: 11, color: OnepieceColors.secondaryLabel)),
                TextSpan(
                    text: chip.value,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: OnepieceColors.primaryLabel)),
              ]),
            ),
          ),
      ],
    );
  }
}

/// One effect row for a devil fruit: an icon, the stat it strengthens, and the
/// formatted multiplier/offset it applies.
class ResourceEffect {
  const ResourceEffect(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;
}

class ResourceEffectList extends StatelessWidget {
  const ResourceEffectList({super.key, required this.effects, this.gap = 6});

  final List<ResourceEffect> effects;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < effects.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          _row(effects[i]),
        ],
      ],
    );
  }

  Widget _row(ResourceEffect effect) {
    return Row(children: [
      Icon(effect.icon, size: 16, color: OnepieceColors.secondaryLabel),
      const SizedBox(width: 8),
      Expanded(
        child: Text(effect.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 13, color: OnepieceColors.secondaryLabel)),
      ),
      const SizedBox(width: 8),
      Text(effect.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
              color: OnepieceColors.primaryLabel)),
    ]);
  }
}

/// Maps a raw stat [value] to a 0‥1 bar fill across its own [min]‥[max] range.
double statFraction(num value, num min, num max) {
  if (max <= min) return 0;
  return ((value - min) / (max - min)).clamp(0.0, 1.0).toDouble();
}
