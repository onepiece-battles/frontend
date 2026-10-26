import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/onepiece_colors.dart';
import '../l10n/app_localizations.dart';

/// Symmetrically aligned pagination controls shared by list views.
class PageFoot extends StatefulWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final String? jumpLabel;

  const PageFoot({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    this.jumpLabel,
  });

  @override
  State<PageFoot> createState() => _PageFootState();
}

class _PageFootState extends State<PageFoot> {
  final _controller = TextEditingController();
  int? _targetPage;

  @override
  void initState() {
    super.initState();
    _controller.text = '${widget.currentPage}';
  }

  @override
  void didUpdateWidget(covariant PageFoot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPage != oldWidget.currentPage ||
        widget.totalPages != oldWidget.totalPages) {
      _controller.text = '${widget.currentPage}';
      _targetPage = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateTarget(String value) {
    final page = int.tryParse(value);
    setState(() {
      _targetPage = page != null &&
              page >= 1 &&
              page <= widget.totalPages &&
              page != widget.currentPage
          ? page
          : null;
    });
  }

  void _jump() {
    if (_targetPage != null) widget.onPageChanged(_targetPage!);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(builder: (context, constraints) {
      final narrow = constraints.maxWidth < 340;
      final actionWidth = narrow ? 36.0 : 72.0;
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: actionWidth),
          const SizedBox(width: 8),
          _arrow(
              Icons.chevron_left_rounded,
              l10n.previousPage,
              widget.currentPage > 1
                  ? () => widget.onPageChanged(widget.currentPage - 1)
                  : null),
          const SizedBox(width: 8),
          Container(
            height: 34,
            width: 100,
            decoration: BoxDecoration(
              color: OnepieceColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 36,
                  child: TextField(
                    controller: _controller,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                        color: OnepieceColors.primaryLabel,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: l10n.pageNumber,
                      hintStyle: const TextStyle(fontSize: 11),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: _updateTarget,
                    onSubmitted: (_) => _jump(),
                  ),
                ),
                Text('/ ${widget.totalPages}',
                    style: const TextStyle(
                        color: OnepieceColors.secondaryLabel, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _arrow(
              Icons.chevron_right_rounded,
              l10n.nextPage,
              widget.currentPage < widget.totalPages
                  ? () => widget.onPageChanged(widget.currentPage + 1)
                  : null),
          const SizedBox(width: 8),
          SizedBox(
            width: actionWidth,
            height: 34,
            child: TextButton(
              onPressed: _targetPage == null ? null : _jump,
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: narrow
                  ? Tooltip(
                      message: l10n.jumpToPageTooltip,
                      child:
                          const Icon(Icons.keyboard_return_rounded, size: 18))
                  : Text(widget.jumpLabel ?? l10n.jumpToPage,
                      style: const TextStyle(fontSize: 12)),
            ),
          ),
        ],
      );
    });
  }

  Widget _arrow(IconData icon, String tooltip, VoidCallback? onPressed) {
    return SizedBox(
      width: 36,
      height: 34,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          foregroundColor: OnepieceColors.fancyBlue,
          disabledForegroundColor: OnepieceColors.secondaryLabel,
          backgroundColor: OnepieceColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
