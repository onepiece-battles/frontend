import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:openapi/api.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../../../constants/button_style.dart';
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
                              BorderSide(color: OnepieceColors.menuHoverColor)),
                      enabledBorder: const OutlineInputBorder(
                          borderSide:
                              BorderSide(color: OnepieceColors.menuHoverColor)),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                            color: OnepieceColors.fancyGreen, width: 1.5),
                      ),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      labelText: AppLocalizations.of(context)!.starterName,
                      labelStyle: OnepieceFonts.dropDownItemStyle),
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: () => setState(() => _showFilters = !_showFilters),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 35,
                width: 35,
                decoration: BoxDecoration(
                  border: Border.all(color: OnepieceColors.menuHoverColor),
                  borderRadius: BorderRadius.circular(4),
                  color: _showFilters
                      ? OnepieceColors.fancyBlue.withValues(alpha: 0.1)
                      : null,
                ),
                child: Icon(
                  Icons.filter_list,
                  size: 20,
                  color:
                      _showFilters ? OnepieceColors.fancyBlue : Colors.grey[700],
                ),
              ),
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
                inactiveBgColor: OnepieceColors.liteFancyGreen,
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
          _buildDropdown<BattleStyle>(
            items: BattleStyle.values,
            selectedItems: widget.selectedBattleStyles,
            displayMap: widget.battleStyleMap,
            hint: AppLocalizations.of(context)!.battleStyle,
            width: double.infinity,
            onChanged: (list) {
              characterFilter.battleStyles = list;
              widget.onSearch(true);
            },
          ),
          const SizedBox(height: 6),
          _buildDropdown<Haki>(
            items: Haki.values,
            selectedItems: widget.selectedHakis,
            displayMap: widget.hakiMap,
            hint: AppLocalizations.of(context)!.hakis,
            width: double.infinity,
            onChanged: (list) {
              characterFilter.hakis = list;
              widget.onSearch(true);
            },
          ),
          const SizedBox(height: 6),
          _buildDropdown<Race>(
            items: Race.values,
            selectedItems: widget.selectedRaces,
            displayMap: widget.raceMap,
            hint: AppLocalizations.of(context)!.race,
            width: double.infinity,
            onChanged: (list) {
              characterFilter.races = list;
              widget.onSearch(true);
            },
          ),
        ],
      ],
    );
  }

  // ── Desktop: card-style search and filters ────────────────────────────

  Widget _buildDesktop(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: OnepieceColors.deepFancyBlue.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: OnepieceColors.fancyBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.tune,
                    size: 21, color: OnepieceColors.fancyBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: TextFormField(
                    controller: searchNameController,
                    onChanged: (value) {
                      characterFilter.name = value.trim();
                      widget.onSearch(true);
                    },
                    decoration: InputDecoration(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14),
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      filled: true,
                      fillColor: Colors.grey.withValues(alpha: 0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                        borderSide: BorderSide(
                            color: Colors.black.withValues(alpha: 0.07)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                        borderSide: const BorderSide(
                            color: OnepieceColors.fancyBlue, width: 1.5),
                      ),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: searchNameController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: MaterialLocalizations.of(context)
                                  .deleteButtonTooltip,
                              onPressed: () {
                                searchNameController.clear();
                                characterFilter.name = '';
                                widget.onSearch(true);
                                setState(() {});
                              },
                              icon: const Icon(Icons.close, size: 18),
                            ),
                      labelText: AppLocalizations.of(context)!.starterName,
                      labelStyle: OnepieceFonts.dropDownItemStyle,
                    ),
                  ),
                ),
              ),
              if (widget.hasCreate) ...[
                const SizedBox(width: 12),
                SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: widget.onCreate,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      backgroundColor: OnepieceColors.fancyBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11)),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(AppLocalizations.of(context)!.create),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              height: 38,
              child: ToggleSwitch(
                customWidths: const [150, 150, 150, 180],
                cornerRadius: 10,
                minHeight: 38,
                fontSize: 13,
                initialLabelIndex: initialLabelIndex,
                activeBgColor: const [OnepieceColors.fancyBlue],
                inactiveBgColor:
                    OnepieceColors.fancyBlue.withValues(alpha: 0.07),
                inactiveFgColor: Colors.grey[700],
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
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 10.0;
              final fieldWidth = (constraints.maxWidth - gap * 2) / 3;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  _buildDropdown<BattleStyle>(
                    items: BattleStyle.values,
                    selectedItems: widget.selectedBattleStyles,
                    displayMap: widget.battleStyleMap,
                    hint: AppLocalizations.of(context)!.battleStyle,
                    width: fieldWidth,
                    cardStyle: true,
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
                    width: fieldWidth,
                    cardStyle: true,
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
                    width: fieldWidth,
                    cardStyle: true,
                    onChanged: (list) {
                      characterFilter.races = list;
                      widget.onSearch(true);
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Generic multi-select dropdown builder to reduce repetition.
  Widget _buildDropdown<T>({
    required List<T> items,
    required List<T> selectedItems,
    required Map<T, String> displayMap,
    required String hint,
    required Function(List<T>) onChanged,
    double width = 200,
    bool cardStyle = false,
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
          height: cardStyle ? 42 : 35,
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cardStyle ? 11 : 3),
            color: cardStyle
                ? OnepieceColors.fancyBlue.withValues(alpha: 0.06)
                : OnepieceColors.liteFancyGreen,
            border: cardStyle
                ? Border.all(color: Colors.black.withValues(alpha: 0.07))
                : null,
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
