import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/onepiece_colors.dart';
import '../l10n/app_localizations.dart';

/// Keeps the front and back in the same list slot while rotating the card.
/// The face swaps edge-on, so neither side is ever mirrored to the reader.
class ResourceFlipCard extends StatelessWidget {
  const ResourceFlipCard({
    super.key,
    required this.flipped,
    required this.front,
    required this.back,
  });

  final bool flipped;
  final Widget front;
  final Widget back;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final height = 226.0 + (textScale - 1).clamp(0.0, 1.0) * 120;
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

/// The "dossier" back of a flip card: a titled shell with a flip-back control,
/// a caller-supplied [child] body (stat bars, effect rows, …) and a trailing
/// link into the full detail page. The body is where the detail lives — a
/// readable breakdown, not a bare grid of numbers.
class ResourceFlipDetail extends StatelessWidget {
  const ResourceFlipDetail({
    super.key,
    required this.title,
    required this.onFlipBack,
    required this.onOpen,
    required this.child,
  });

  final String title;
  final VoidCallback onFlipBack;
  final VoidCallback onOpen;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 26,
              child: Row(children: [
                Expanded(
                  child: Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: OnepieceColors.primaryLabel)),
                ),
                IconButton(
                  tooltip: loc.flipCardBack,
                  onPressed: onFlipBack,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints.tightFor(width: 26, height: 26),
                  icon: const Icon(Icons.flip_to_front_outlined,
                      size: 17, color: OnepieceColors.secondaryLabel),
                ),
              ]),
            ),
            Expanded(child: child),
            SizedBox(
              height: 24,
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onOpen,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 24),
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: OnepieceColors.fancyBlue,
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(loc.openResourceDetails,
                        style: const TextStyle(fontSize: 11)),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right, size: 15),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
