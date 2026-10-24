import 'dart:async';

import 'package:flutter/material.dart';
import 'package:openapi/api.dart';

import '../../../components/square_image_loader.dart';
import '../../../constants/onepiece_colors.dart';
import '../../../constants/onepiece_fonts.dart';
import '../../../l10n/app_localizations.dart';
import 'add_group_character_controller.dart';
import '../../../utils/i18n_helper.dart' hide getIt;

class AddGroupCharacterDialog extends StatefulWidget {
  final String groupId;
  final VoidCallback? onCharactersAdded;

  const AddGroupCharacterDialog({
    super.key,
    required this.groupId,
    this.onCharactersAdded,
  });

  @override
  State<AddGroupCharacterDialog> createState() =>
      _AddGroupCharacterDialogState();
}

class _AddGroupCharacterDialogState extends State<AddGroupCharacterDialog> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AddGroupCharacterController _controller = AddGroupCharacterController();
  final Set<String> _selectedCharacterIds = {};
  List<CharacterListView> _characters = [];
  Timer? _searchDebounce;
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _searchCharacters('');
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _searchCharacters(String value) async {
    setState(() {
      _isLoading = true;
    });

    final request = ListCharacterRequest(
      pageSize: 20,
      pageIndex: 1,
      sortKeys: [],
      characterFilter: CharacterFilter(
        name: value.trim(),
        languageCode: I18nHelper.getLanguageCode(),
      ),
    );

    try {
      final response = await _controller.listCharacter(request);
      if (!mounted) return;
      setState(() {
        _characters = response?.characters ?? [];
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _characters = [];
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _searchCharacters(value),
    );
  }

  Future<void> _submit() async {
    if (_selectedCharacterIds.isEmpty || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _controller.addCharacter(
        AddCharacterRequest(
          groupId: widget.groupId,
          characterIds: _selectedCharacterIds.toList(),
        ),
      );
      widget.onCharactersAdded?.call();
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final dialogWidth = screenSize.width < 430 ? screenSize.width - 32 : 420.0;
    final dialogHeight = (screenSize.height * 0.72).clamp(420.0, 640.0);

    return SizedBox(
      width: dialogWidth,
      height: dialogHeight,
      child: Card(
        elevation: 2,
        color: Colors.white,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: OnepieceColors.separator),
        ),
        child: Column(
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: SizedBox(
                height: 38,
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: _searchDecoration(context),
                ),
              ),
            ),
            Expanded(child: _buildCharacterList(context)),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          bottom: BorderSide(color: OnepieceColors.separator, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: OnepieceColors.surface,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.person_add_alt_1_outlined,
                color: OnepieceColors.fancyBlue, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.addCharactersToGroup,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OnepieceFonts.smallHeaderStyle.copyWith(fontSize: 18, color: OnepieceColors.primaryLabel),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 20, color: OnepieceColors.secondaryLabel),
          ),
        ],
      ),
    );
  }

  InputDecoration _searchDecoration(BuildContext context) {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: OnepieceColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      floatingLabelBehavior: FloatingLabelBehavior.never,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: OnepieceColors.fancyBlue, width: 1.5),
      ),
      prefixIcon: const Icon(Icons.search,
          size: 19, color: OnepieceColors.secondaryLabel),
      labelText: AppLocalizations.of(context)!.search,
      labelStyle:
          const TextStyle(color: OnepieceColors.secondaryLabel, fontSize: 14),
    );
  }

  Widget _buildCharacterList(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            OnepieceColors.fancyBlue,
          ),
        ),
      );
    }

    if (_characters.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noCharactersFound,
          style: OnepieceFonts.smallContentStyle,
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      itemCount: _characters.length,
      itemBuilder: (context, index) {
        final character = _characters[index];
        final selected = _selectedCharacterIds.contains(character.id);
        return _CharacterSelectionCard(
          character: character,
          selected: selected,
          onTap: () {
            setState(() {
              if (selected) {
                _selectedCharacterIds.remove(character.id);
              } else {
                _selectedCharacterIds.add(character.id);
              }
            });
          },
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _selectedCharacterIds.isEmpty || _isSubmitting
                  ? null
                  : () {
                      setState(() {
                        _selectedCharacterIds.clear();
                      });
                    },
              child: Text(AppLocalizations.of(context)!.clearAll),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: _selectedCharacterIds.isEmpty || _isSubmitting
                  ? null
                  : _submit,
              child: Text(AppLocalizations.of(context)!.submitForm),
            ),
          ),
        ],
      ),
    );
  }
}

class _CharacterSelectionCard extends StatelessWidget {
  final CharacterListView character;
  final bool selected;
  final VoidCallback onTap;

  const _CharacterSelectionCard({
    required this.character,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final uri = character.imageUri ?? '';
    return Card(
      elevation: selected ? 2 : 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: selected
          ? OnepieceColors.fancyBlue.withValues(alpha: 0.10)
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected
              ? OnepieceColors.fancyBlue
              : OnepieceColors.separator,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        hoverColor: OnepieceColors.surface,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              SquareImageLoader(
                key: ValueKey('${character.id}-$uri'),
                uriProvider: () => uri,
                width: 42,
                borderWidth: 1.5,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  I18nHelper.getDisplayNameFromI18n(character.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OnepieceFonts.contentStyle
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 20,
                color: selected
                    ? OnepieceColors.fancyBlue
                    : OnepieceColors.menuIconColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
