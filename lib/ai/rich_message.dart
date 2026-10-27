import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../constants/onepiece_colors.dart';

/// Renders the assistant's lightweight Markdown into formatted text with
/// **bold**, bullet lists, headings and — most importantly — inline tappable
/// links of the form `[Name](onepiece://TYPE/ID)` that jump into the app.
///
/// This is a small purpose-built renderer (no extra dependency) that handles
/// exactly the subset the assistant is prompted to emit.
class RichMessage extends StatefulWidget {
  const RichMessage({
    super.key,
    required this.data,
    required this.onResource,
    this.textStyle,
  });

  final String data;
  final TextStyle? textStyle;

  /// Called with (type, id, name) when an `onepiece://` link is tapped.
  final void Function(String type, String id, String name) onResource;

  @override
  State<RichMessage> createState() => _RichMessageState();
}

class _RichMessageState extends State<RichMessage> {
  final List<TapGestureRecognizer> _recognizers = [];
  late List<Widget> _blocks;

  TextStyle get _base =>
      widget.textStyle ??
      const TextStyle(
          fontSize: 14, height: 1.4, color: OnepieceColors.primaryLabel);

  @override
  void initState() {
    super.initState();
    _parse();
  }

  @override
  void didUpdateWidget(covariant RichMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data || oldWidget.textStyle != widget.textStyle) {
      _parse();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  void _parse() {
    _disposeRecognizers();
    final lines = widget.data.replaceAll('\r\n', '\n').split('\n');
    final blocks = <Widget>[];
    for (final line in lines) {
      final trimmed = line.trimRight();
      if (trimmed.trim().isEmpty) {
        blocks.add(const SizedBox(height: 7));
        continue;
      }
      if (trimmed.startsWith('### ') ||
          trimmed.startsWith('## ') ||
          trimmed.startsWith('# ')) {
        final text = trimmed.replaceFirst(RegExp(r'^#{1,3}\s+'), '');
        blocks.add(Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 2),
          child: Text.rich(
            TextSpan(children: _inlineSpans(text)),
            style: _base.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ));
        continue;
      }
      final bullet = RegExp(r'^\s*[-*]\s+');
      if (bullet.hasMatch(trimmed)) {
        final text = trimmed.replaceFirst(bullet, '');
        blocks.add(Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('•  ', style: _base),
              Expanded(
                child: Text.rich(
                    TextSpan(children: _inlineSpans(text)), style: _base),
              ),
            ],
          ),
        ));
        continue;
      }
      blocks.add(Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text.rich(TextSpan(children: _inlineSpans(trimmed)), style: _base),
      ));
    }
    _blocks = blocks;
  }

  // Matches **bold**, [label](target), or a bare onepiece:// URL (safety net so
  // a raw link never renders as text); everything else is plain text.
  static final RegExp _inline = RegExp(
      r'\*\*(.+?)\*\*|\[([^\]]+)\]\(([^)]+)\)|(onepiece://[A-Za-z_]+/[^\s)\]]+)');

  // Any onepiece URL that escaped tokenizing is stripped from plain text, so a
  // raw link can never be shown as literal text.
  static final RegExp _rawUrl =
      RegExp(r'\(?onepiece://[A-Za-z_]+/[^\s)\]]+\)?');

  List<InlineSpan> _inlineSpans(String text) {
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _inline.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: _scrub(text.substring(last, m.start))));
      }
      if (m.group(1) != null) {
        spans.add(TextSpan(
            text: m.group(1), style: const TextStyle(fontWeight: FontWeight.w700)));
      } else if (m.group(2) != null) {
        spans.add(_linkSpan(m.group(2)!, m.group(3) ?? ''));
      } else {
        final url = m.group(4)!; // bare onepiece://type/id
        final type = url.substring('onepiece://'.length).split('/').first;
        spans.add(_linkSpan(type, url));
      }
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: _scrub(text.substring(last))));
    }
    return spans;
  }

  String _scrub(String s) => s.replaceAll(_rawUrl, '');

  InlineSpan _linkSpan(String label, String target) {
    if (target.startsWith('onepiece://')) {
      final rest = target.substring('onepiece://'.length);
      final slash = rest.indexOf('/');
      if (slash > 0) {
        final type = rest.substring(0, slash).toLowerCase();
        final id = rest.substring(slash + 1);
        // Never show a raw URL / empty label as the visible text.
        final display =
            (label.contains('://') || label.trim().isEmpty) ? type : label;
        final recognizer = TapGestureRecognizer()
          ..onTap = () => widget.onResource(type, id, display);
        _recognizers.add(recognizer);
        return TextSpan(
          text: display,
          recognizer: recognizer,
          style: const TextStyle(
              color: OnepieceColors.fancyBlue, fontWeight: FontWeight.w600),
        );
      }
    }
    // Non-resource link: show the label (scrubbed of any raw URL), styled inert.
    return TextSpan(
        text: _scrub(label), style: const TextStyle(color: OnepieceColors.fancyBlue));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: _blocks,
    );
  }
}
