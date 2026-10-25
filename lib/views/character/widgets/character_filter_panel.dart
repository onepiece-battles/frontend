import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:openapi/api.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../../../constants/button_style.dart';
import '../../../components/desktop_card_layout.dart';
import '../../../constants/onepiece_colors.dart';
import '../../../constants/onepiece_fonts.dart';
import '../../../l10n/app_localizations.dart';

/// Search + filter control panel for the character roster: a name search box, a
/// create button, the resource-scope toggle (all / mine / system / exclude
/// system) and the battle-style / haki / race multi-select dropdowns.
///
/// Mutates the shared [characterFilter] and the selection lists in place and
/// asks the parent to re-query via [onSearch]; the collapse / scope-toggle UI
/// state is owned locally.
class CharacterFilterPanel extends StatefulWidget {
  final bool isNarrow;
  final bool hasCreate;
  final String myUserId;
  final TextEditingController searchNameController;
  final CharacterFilter characterFilter;
  final List<BattleStyle> selectedBattleStyles;
  final List<Race> selectedRaces;
  final List<Haki> selectedHakis;
  final Map<BattleStyle, String> battleStyleMap;
  final Map<Race, String> raceMap;
  final Map<Haki, String> hakiMap;
  final VoidCallback onCreate;
  final void Function(bool filterChange) onSearch;

  const CharacterFilterPanel({
    super.key,
    required this.isNarrow,
    required this.hasCreate,
    required this.myUserId,
    required this.searchNameController,
    required this.characterFilter,
    required this.selectedBattleStyles,
    required this.selectedRaces,
    required this.selectedHakis,
    required this.battleStyleMap,
    required this.raceMap,
    required this.hakiMap,
    required this.onCreate,
    required this.onSearch,
  });

  @override
  State<CharacterFilterPanel> createState() => _CharacterFilterPanelState();
}

class _CharacterFilterPanelState extends State<CharacterFilterPanel> {
  bool _showFilters = false;
  int initialLabelIndex = 0;

  CharacterFilter get characterFilter => widget.characterFilter;
  TextEditingController get searchNameController => widget.searchNameController;

  @override
  Widget build(BuildContext context) {
    return widget.isNarrow ? _buildMobile(context) : _buildDesktop(context);
  }

  // ── Mobile: collapsible filter panel ──────────────────────────────────

  Widget _buildMobile(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: Create button + search field + filter toggle
        Row(
          children: [
            if (widget.hasCreate)
              Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: SizedBox(
                  height: 35,
                  child: ElevatedButton(
                    onPressed: widget.onCreate,
                    style: OnepieceButtonStyle.getDefaultStyle(),
                    child: Text(AppLocalizations.of(context)!.create,
                        style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ),
            Expanded(
              child: SizedBox(
                height: 35,
                child: TextFormField(
                  controller: searchNameController,
                  onChanged: (value) {
                    characterFilter.name = value.trim();
                    widget.onSearch(true);
                  },
                  decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 0),
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      disabledBorder: const OutlineInputBorder(
                          borderSide:
                              BorderSide(color: OnepieceColors.separator)),
                      enabledBorder: const OutlineInputBorder(
                          borderSide:
                              BorderSide(color: OnepieceColors.separator)),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                            color: OnepieceColors.fancyGreen, width: 1.5),
                      ),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      labelText: AppLocalizations.of(context)!.characterName,
                      labelStyle: OnepieceFonts.dropDownItemStyle
                          .copyWith(fontSize: 13)),
                ),
              ),
            ),
            const SizedBox(width: 6),
            ListFilterButton(
              active: _showFilters ||
                  initialLabelIndex != 0 ||
                  widget.selectedBattleStyles.isNotEmpty ||
                  widget.selectedRaces.isNotEmpty ||
                  widget.selectedHakis.isNotEmpty,
              onPressed: () => setState(() => _showFilters = !_showFilters),
            ),
          ],
        ),
        // Expandable filter panel
        if (_showFilters) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              height: 36,
              child: ToggleSwitch(
                customWidths: const [90, 90, 100, 120],
                cornerRadius: 4,
                minHeight: 35.0,
                fontSize: 12.0,
                initialLabelIndex: initialLabelIndex,
                activeBgColor: const [OnepieceColors.fancyBlue],
                inactiveBgColor: OnepieceColors.surface,
                inactiveFgColor: Colors.grey[600],
                totalSwitches: 4,
                labels: [
                  AppLocalizations.of(context)!.allResources,
                  AppLocalizations.of(context)!.myResource,
                  AppLocalizations.of(context)!.systemResource,
                  AppLocalizations.of(context)!.excludeSystem
                ],
                onToggle: (index) {
                  initialLabelIndex = index!;
                  characterFilter.systemResource =
                      (index == 2) ? true : (index == 3 ? false : null);
                  characterFilter.userId =
                      (index == 1) ? widget.myUserId : null;
                  widget.onSearch(true);
                },
              ),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [
            _buildDropdown<BattleStyle>(
              items: BattleStyle.values,
              selectedItems: widget.selectedBattleStyles,
              displayMap: widget.battleStyleMap,
              hint: AppLocalizations.of(context)!.battleStyle,
              width: widget.isNarrow ? double.infinity : 180,
              onChanged: (list) {
                characterFilter.battleStyles = list;
                widget.onSearch(true);
              },
            ),
            _buildDropdown<Haki>(
              items: Haki.values,
              selectedItems: widget.selectedHakis,
              displayMap: widget.hakiMap,
              hint: AppLocalizations.of(context)!.hakis,
              width: widget.isNarrow ? double.infinity : 180,
              onChanged: (list) {
                characterFilter.hakis = list;
                widget.onSearch(true);
              },
            ),
            _buildDropdown<Race>(
              items: Race.values,
              selectedItems: widget.selectedRaces,
              displayMap: widget.raceMap,
              hint: AppLocalizations.of(context)!.race,
              width: widget.isNarrow ? double.infinity : 180,
              onChanged: (list) {
                characterFilter.races = list;
                widget.onSearch(true);
              },
            ),
          ]),
        ],
      ],
    );
  }

  // ── Desktop: card-style search and filters ────────────────────────────

  Widget _buildDesktop(BuildContext context) => _buildMobile(context);

  Widget _buildDropdown<T>({
    required List<T> items,
    required List<T> selectedItems,
    required Map<T, String> displayMap,
    required String hint,
    required Function(List<T>) onChanged,
    double width = 200,
  }) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2(
        isExpanded: true,
        value: selectedItems.isEmpty ? null : selectedItems.last,
        hint: Text(hint, style: OnepieceFonts.dropDownItemStyle),
        onChanged: (value) {}, // Handled by MenuItem onTap
        selectedItemBuilder: (context) {
          return items.map((item) {
            return Container(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                selectedItems.map((e) => displayMap[e]).join(', '),
                style: const TextStyle(
                    fontSize: 16, overflow: TextOverflow.ellipsis),
                maxLines: 1,
              ),
            );
          }).toList();
        },
        buttonStyleData: ButtonStyleData(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 35,
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: OnepieceColors.surface,
          ),
        ),
        menuItemStyleData: const MenuItemStyleData(height: 35),
        items: items.map((T item) {
          return DropdownMenuItem<T>(
            value: item,
            enabled:
                false, // Disable default selection to handle multi-select manually
            child: StatefulBuilder(
              builder: (context, menuSetState) {
                final isSelected = selectedItems.contains(item);
                return InkWell(
                  onTap: () {
                    isSelected
                        ? selectedItems.remove(item)
                        : selectedItems.add(item);
                    onChanged(selectedItems);
                    setState(() {});
                    menuSetState(() {});
                  },
                  child: Container(
                    height: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 3.0),
                    child: Row(
                      children: [
                        Icon(isSelected
                            ? Icons.check_box_outlined
                            : Icons.check_box_outline_blank),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(displayMap[item]!,
                                style: const TextStyle(fontSize: 16))),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
