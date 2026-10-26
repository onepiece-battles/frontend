import 'package:flutter/material.dart';

import '../constants/onepiece_colors.dart';
import 'page_foot.dart';

/// The same full-width, aligned footer for every resource list.
class ResourceListPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final String? jumpLabel;

  const ResourceListPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    this.jumpLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      height: 38,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: OnepieceColors.separator)),
      ),
      alignment: Alignment.center,
      child: PageFoot(
        currentPage: currentPage,
        totalPages: totalPages,
        onPageChanged: onPageChanged,
        jumpLabel: jumpLabel,
      ),
    );
  }
}
