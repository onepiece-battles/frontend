import 'package:flutter/material.dart';

import '../constants/onepiece_colors.dart';
import '../l10n/app_localizations.dart';

class DetailValue extends StatelessWidget {
  const DetailValue(this.label, this.value,
      {super.key, this.valueStyle, this.compact = false});

  final String label;
  final String value;
  final TextStyle? valueStyle;
  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: compact ? 11 : 12,
                  color: OnepieceColors.secondaryLabel)),
          SizedBox(height: compact ? 3 : 7),
          SelectableText(value.isEmpty ? '—' : value,
              style: valueStyle ??
                  TextStyle(
                      fontSize: compact ? 15 : 17,
                      fontWeight: FontWeight.w500,
                      color: OnepieceColors.primaryLabel)),
        ],
      );
}

class DetailFieldGrid extends StatelessWidget {
  const DetailFieldGrid(
      {super.key, required this.fields, this.compact = false});
  final List<Widget> fields;
  final bool compact;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final gap = compact ? 16.0 : 24.0;
        final columns = (constraints.maxWidth / (compact ? 150 : 220))
            .floor()
            .clamp(1, compact ? 4 : 3);
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
            spacing: gap,
            runSpacing: compact ? 14 : 24,
            children: fields
                .map((field) => SizedBox(width: width, child: field))
                .toList());
      });
}

class DetailSection extends StatelessWidget {
  const DetailSection(
      {super.key,
      required this.child,
      this.title,
      this.action,
      this.compact = false});
  final String? title;
  final Widget? action;
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: EdgeInsets.all(compact ? 16 : 24),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(compact ? 16 : 20),
            border: Border.all(
                color: OnepieceColors.separator.withValues(alpha: .7))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (title != null) ...[
            SizedBox(
                width: double.infinity,
                child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      Text(title!,
                          style: TextStyle(
                              fontSize: compact ? 17 : 19,
                              fontWeight: FontWeight.w600,
                              color: OnepieceColors.primaryLabel)),
                      if (action != null) action!,
                    ])),
            SizedBox(height: compact ? 14 : 24),
          ],
          child,
        ]),
      );
}

class DetailEditor extends StatelessWidget {
  const DetailEditor({super.key, required this.child, this.width = 860});
  final Widget child;
  final double width;
  @override
  Widget build(BuildContext context) => DetailSection(
      child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: width, child: child)));
}

class DetailHero extends StatelessWidget {
  const DetailHero(
      {super.key,
      required this.kind,
      required this.title,
      this.avatar,
      this.tags = const [],
      this.metrics = const [],
      this.compact = false});
  final String kind;
  final String title;
  final Widget? avatar;
  final List<Widget> tags;
  final List<Widget> metrics;
  final bool compact;
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 2 : 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            if (avatar != null) ...[
              avatar!,
              SizedBox(width: compact ? 16 : 24)
            ],
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(kind,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: OnepieceColors.secondaryLabel)),
                  SizedBox(height: compact ? 3 : 8),
                  Text(title,
                      style: TextStyle(
                          fontSize: compact ? 27 : 34,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -.7,
                          color: OnepieceColors.primaryLabel)),
                  if (tags.isNotEmpty) ...[
                    SizedBox(height: compact ? 8 : 14),
                    Wrap(spacing: 6, runSpacing: 6, children: tags)
                  ],
                ])),
          ]),
          if (metrics.isNotEmpty) ...[
            SizedBox(height: compact ? 14 : 28),
            DetailFieldGrid(fields: metrics, compact: compact),
          ],
        ]),
      );
}

class ResourceDetailPage extends StatelessWidget {
  const ResourceDetailPage(
      {super.key,
      required this.controller,
      required this.header,
      required this.sections,
      this.compact = false});
  final ScrollController controller;
  final Widget header;
  final List<Widget> Function(BuildContext context, double width) sections;
  final bool compact;
  @override
  Widget build(BuildContext context) => Theme(
      data: Theme.of(context).copyWith(
          cardTheme: const CardThemeData(
              color: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0)),
      child: ColoredBox(
        color: const Color(0xFFF7F7F9),
        child: Scrollbar(
            controller: controller,
            child: SingleChildScrollView(
              controller: controller,
              padding: EdgeInsets.fromLTRB(
                  compact ? 20 : 28, compact ? 20 : 32, compact ? 20 : 28, 96),
              child: Center(
                  child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: compact ? 1120 : 1080),
                child: LayoutBuilder(
                    builder: (context, constraints) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            header,
                            SizedBox(height: compact ? 16 : 28),
                            ...sections(context, constraints.maxWidth).expand(
                                (section) => [
                                      section,
                                      SizedBox(height: compact ? 12 : 20)
                                    ]),
                          ],
                        )),
              )),
            )),
      ));
}

Future<void> showResourceDetails(
    BuildContext context, String title, Widget content) {
  Widget panel(BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .8, maxWidth: 640),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 12, 16),
                  child: Row(children: [
                    Expanded(
                        child: Text(title,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: OnepieceColors.primaryLabel))),
                    IconButton(
                        tooltip: MaterialLocalizations.of(context)
                            .closeButtonTooltip,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, size: 20)),
                  ])),
              const Divider(height: 1, color: OnepieceColors.separator),
              Flexible(
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24), child: content)),
            ]),
      );
  if (MediaQuery.sizeOf(context).width < 600) {
    return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: Colors.white,
        builder: (context) => SafeArea(child: panel(context)));
  }
  return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: panel(context)));
}

class DetailEditButton extends StatelessWidget {
  const DetailEditButton({super.key, required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.edit_outlined, size: 16),
      label: Text(AppLocalizations.of(context)!.editHint));
}
