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
    final height = 204.0 + (textScale - 1).clamp(0.0, 1.0) * 100;
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

class ResourceFlipDetail extends StatelessWidget {
  const ResourceFlipDetail({
    super.key,
    required this.title,
    required this.fields,
    required this.onFlipBack,
    required this.onOpen,
  });

  final String title;
  final List<ResourceFlipField> fields;
  final VoidCallback onFlipBack;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 30,
              child: Row(children: [
                Expanded(
                  child: Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: OnepieceColors.primaryLabel)),
                ),
                IconButton(
                  tooltip: loc.flipCardBack,
                  onPressed: onFlipBack,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints.tightFor(width: 30, height: 30),
                  icon: const Icon(Icons.flip_to_front_outlined,
                      size: 18, color: OnepieceColors.secondaryLabel),
                ),
              ]),
            ),
            const SizedBox(height: 5),
            Expanded(child: _ResourceFlipFieldGrid(fields: fields)),
            const SizedBox(height: 3),
            SizedBox(
              height: 27,
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onOpen,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 27),
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                  label: Text(loc.openResourceDetails),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward_ios, size: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResourceFlipField {
  const ResourceFlipField(this.label, this.value);

  final String label;
  final String value;
}

class _ResourceFlipFieldGrid extends StatelessWidget {
  const _ResourceFlipFieldGrid({required this.fields});

  final List<ResourceFlipField> fields;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const gap = 6.0;
      final cellWidth = (constraints.maxWidth - 12 - gap) / 2;
      return DecoratedBox(
        decoration: BoxDecoration(
          color: OnepieceColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Wrap(
            spacing: gap,
            runSpacing: 3,
            children: [
              for (final field in fields)
                SizedBox(
                  width: cellWidth,
                  child: Tooltip(
                    message: '${field.label}: ${field.value}',
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(field.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 10,
                                height: 1.05,
                                color: OnepieceColors.secondaryLabel)),
                        const SizedBox(height: 1),
                        Text(field.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13,
                                height: 1.05,
                                fontWeight: FontWeight.w600,
                                fontFeatures: [FontFeature.tabularFigures()],
                                color: OnepieceColors.primaryLabel)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}
