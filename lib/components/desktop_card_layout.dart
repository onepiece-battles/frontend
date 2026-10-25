import 'package:flutter/material.dart';

import '../constants/onepiece_colors.dart';

class ResourceBadge extends StatelessWidget {
  const ResourceBadge(this.label, {super.key, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 9, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
        color: OnepieceColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: compact ? 11 : 12, color: OnepieceColors.primaryLabel)),
    );
  }
}

class DesktopFilterPanel extends StatelessWidget {
  final Widget child;

  const DesktopFilterPanel({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return _ControlSurface(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: child,
    );
  }
}

class CompactFilterPanel extends StatelessWidget {
  final Widget child;

  const CompactFilterPanel({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return _ControlSurface(
      padding: const EdgeInsets.all(6),
      child: child,
    );
  }
}

class ListFilterButton extends StatelessWidget {
  final bool active;
  final VoidCallback onPressed;

  const ListFilterButton({
    super.key,
    required this.active,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        splashRadius: 20,
        style: IconButton.styleFrom(
          foregroundColor: active ? Colors.white : OnepieceColors.fancyBlue,
          backgroundColor:
              active ? OnepieceColors.fancyBlue : Colors.transparent,
          side: BorderSide(
            color: active
                ? OnepieceColors.fancyBlue
                : OnepieceColors.fancyBlue.withValues(alpha: 0.35),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        icon: Icon(active ? Icons.filter_alt : Icons.filter_alt_outlined),
      ),
    );
  }
}

class _ControlSurface extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final Widget child;

  const _ControlSurface({
    required this.padding,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: OnepieceColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            prefixIconColor: OnepieceColors.fancyBlue,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}

class DesktopSortChip extends StatelessWidget {
  final String label;
  final bool? ascending;
  final VoidCallback onTap;

  const DesktopSortChip({
    super.key,
    required this.label,
    required this.ascending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = ascending != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: active ? OnepieceColors.surface : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? OnepieceColors.fancyBlue : OnepieceColors.separator,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active
                    ? OnepieceColors.fancyBlue
                    : OnepieceColors.primaryLabel,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              ascending == true
                  ? Icons.arrow_upward
                  : ascending == false
                      ? Icons.arrow_downward
                      : Icons.unfold_more,
              size: 14,
              color: active
                  ? OnepieceColors.fancyBlue
                  : OnepieceColors.secondaryLabel,
            ),
          ],
        ),
      ),
    );
  }
}

class DesktopSpotlightCard extends StatefulWidget {
  final Widget child;

  const DesktopSpotlightCard({super.key, required this.child});

  @override
  State<DesktopSpotlightCard> createState() => _DesktopSpotlightCardState();
}

class _DesktopSpotlightCardState extends State<DesktopSpotlightCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutQuart,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hovered ? 0.05 : 0),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovered
                ? OnepieceColors.secondaryLabel
                : OnepieceColors.separator,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

class DesktopSpotlightGrid<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T item) idOf;
  final Widget Function(BuildContext context, T item) cardBuilder;
  final ScrollController controller;
  final double minCardWidth;
  final int maxColumns;
  final double gap;

  const DesktopSpotlightGrid({
    super.key,
    required this.items,
    required this.idOf,
    required this.cardBuilder,
    required this.controller,
    this.minCardWidth = 340,
    this.maxColumns = 5,
    this.gap = 18,
  });

  @override
  State<DesktopSpotlightGrid<T>> createState() =>
      _DesktopSpotlightGridState<T>();
}

class _DesktopSpotlightGridState<T> extends State<DesktopSpotlightGrid<T>> {
  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: widget.controller,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: widget.controller,
        padding: const EdgeInsets.fromLTRB(8, 12, 12, 24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columnCount = ((constraints.maxWidth + widget.gap) /
                    (widget.minCardWidth + widget.gap))
                .floor()
                .clamp(1, widget.maxColumns);
            final cardWidth =
                (constraints.maxWidth - widget.gap * (columnCount - 1)) /
                    columnCount;

            return Wrap(
              spacing: widget.gap,
              runSpacing: widget.gap,
              children: widget.items.map((item) {
                final id = widget.idOf(item);

                return SizedBox(
                  width: cardWidth,
                  child: DesktopSpotlightCard(
                    key: ValueKey(id),
                    child: widget.cardBuilder(context, item),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
