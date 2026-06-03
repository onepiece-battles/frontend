import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/onepiece_colors.dart';

/// A compact pagination footer for data tables.
///
/// Layout:
/// ```
///   [<]   [__] / 42   [Go]   [>]
/// ```
class PageFoot extends StatefulWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  /// Label for the jump button (e.g. "Go" / "跳转").
  final String jumpLabel;

  const PageFoot({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    this.jumpLabel = 'Go',
  });

  @override
  State<PageFoot> createState() => _PageFootState();
}

class _PageFootState extends State<PageFoot> {
  final TextEditingController _pageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _jumpEnabled = false;

  // ── Shared constants for input + total alignment ──────────────────
  static const double _rowHeight = 30;
  static const _inputTextStyle = TextStyle(
    fontSize: 14,
    color: Colors.black87,
    fontWeight: FontWeight.w500,
  );
  static const _totalTextStyle = TextStyle(
    fontSize: 14,
    color: Colors.black54,
    fontWeight: FontWeight.w500,
  );

  @override
  void initState() {
    super.initState();
    _pageController.text = '${widget.currentPage}';
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() => setState(() {});

  @override
  void didUpdateWidget(covariant PageFoot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPage != oldWidget.currentPage) {
      _pageController.text = '${widget.currentPage}';
      _jumpEnabled = false;
    }
  }

  void _onInputChanged(String value) {
    final page = int.tryParse(value.trim());
    setState(() {
      _jumpEnabled = page != null &&
          page >= 1 &&
          page <= widget.totalPages &&
          page != widget.currentPage;
    });
  }

  void _jump() {
    final page = int.tryParse(_pageController.text.trim());
    if (page != null && _jumpEnabled) {
      widget.onPageChanged(page);
    }
  }

  void _goPrevious() {
    if (widget.currentPage > 1) {
      widget.onPageChanged(widget.currentPage - 1);
    }
  }

  void _goNext() {
    if (widget.currentPage < widget.totalPages) {
      widget.onPageChanged(widget.currentPage + 1);
    }
  }

  // ── Shared button colors ──────────────────────────────────────

  Color _bg(bool enabled) =>
      enabled ? OnepieceColors.fancyBlue : Colors.grey[200]!;

  Color _fg(bool enabled) =>
      enabled ? Colors.white : OnepieceColors.fancyBlue.withValues(alpha: 0.5);

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final canGoBack = widget.currentPage > 1;
    final canGoForward = widget.currentPage < widget.totalPages;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _iconBtn(
          enabled: canGoBack,
          onTap: canGoBack ? _goPrevious : null,
          icon: Icons.arrow_back_rounded,
          tooltip: 'Previous page',
        ),
        const SizedBox(width: 8),
        _buildPageInput(),
        const SizedBox(width: 2),
        _buildTotalCount(),
        const SizedBox(width: 8),
        _textBtn(
          enabled: _jumpEnabled,
          onTap: _jumpEnabled ? _jump : null,
          label: widget.jumpLabel,
          tooltip: 'Jump to page',
        ),
        const SizedBox(width: 8),
        _iconBtn(
          enabled: canGoForward,
          onTap: canGoForward ? _goNext : null,
          icon: Icons.arrow_forward_rounded,
          tooltip: 'Next page',
        ),
      ],
    );
  }

  // ── Child widgets ──────────────────────────────────────────────

  Widget _buildPageInput() {
    return Container(
      width: _rowHeight,
      height: _rowHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: _focusNode.hasFocus
              ? OnepieceColors.fancyBlue
              : Colors.transparent,
          width: _focusNode.hasFocus ? 1.5 : 1.0,
        ),
      ),
      child: TextFormField(
        controller: _pageController,
        focusNode: _focusNode,
        style: _inputTextStyle,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.only(top: 7, bottom: 0),
          isDense: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        onChanged: _onInputChanged,
        onFieldSubmitted: (_) => _jump(),
      ),
    );
  }

  Widget _buildTotalCount() {
    return Container(
      height: _rowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: OnepieceColors.menuBackgroundColor,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text('/ ${widget.totalPages}', style: _totalTextStyle),
    );
  }

  // ── Button builders (Material + InkWell — pixel-perfect sizing) ─

  Widget _iconBtn({
    required bool enabled,
    required VoidCallback? onTap,
    required IconData icon,
    required String tooltip,
  }) {
    final btn = SizedBox(
      width: 50,
      height: _rowHeight,
      child: Material(
        color: _bg(enabled),
        borderRadius: BorderRadius.circular(3),
        child: InkWell(
          borderRadius: BorderRadius.circular(3),
          onTap: onTap,
          child: Center(
            child: Icon(icon, size: 18, color: _fg(enabled)),
          ),
        ),
      ),
    );
    return enabled ? Tooltip(message: tooltip, child: btn) : btn;
  }

  Widget _textBtn({
    required bool enabled,
    required VoidCallback? onTap,
    required String label,
    required String tooltip,
  }) {
    final btn = SizedBox(
      height: _rowHeight,
      child: Material(
        color: _bg(enabled),
        borderRadius: BorderRadius.circular(3),
        child: InkWell(
          borderRadius: BorderRadius.circular(3),
          onTap: onTap,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _fg(enabled),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return enabled ? Tooltip(message: tooltip, child: btn) : btn;
  }
}