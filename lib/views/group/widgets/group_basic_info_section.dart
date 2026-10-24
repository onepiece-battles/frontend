import 'dart:typed_data';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openapi/api.dart';

import '../../../components/image_lazy_loader.dart';
import '../../../components/string_text_form_field.dart';
import '../../../constants/onepiece_colors.dart';
import '../../../constants/onepiece_fonts.dart';
import '../../../constants/onepiece_tag.dart';
import '../../../l10n/app_localizations.dart';
import '../../../popup/onepiece_alert.dart';
import '../../../utils/base64_helper.dart';
import '../../../utils/i18n_helper.dart';
import '../../../utils/image_helper.dart';
import '../../../utils/onepiece_image_picker.dart';
import '../group_detail_controller.dart';

/// The "basic info" section of the group detail screen: avatar (editable on
/// desktop), name and category. Owns its own form state and submits through
/// [GroupDetailController].
///
/// The group update sends the FULL [Group] — only name / category come from
/// this section, while fatherGroupId / imageUri / record ids are copied from
/// the loaded [group]. The backend does a full-column update with no
/// fetch-merge, so a partial request would null those columns, losing the
/// parent-group link and avatar (see BUG-004).
class GroupBasicInfoSection extends StatefulWidget {
  final GroupFullView group;
  final bool editButtonVisible;
  final GroupDetailController controller;
  final bool isNarrow;

  const GroupBasicInfoSection({
    super.key,
    required this.group,
    required this.editButtonVisible,
    required this.controller,
    required this.isNarrow,
  });

  @override
  State<GroupBasicInfoSection> createState() => _GroupBasicInfoSectionState();
}

class _GroupBasicInfoSectionState extends State<GroupBasicInfoSection> {
  final groupNameController = TextEditingController();
  late GroupCategory selectedGroupCategory;
  String? selectedImage;
  bool basicInfoEditable = false;

  GroupFullView get group => widget.group;

  @override
  void initState() {
    super.initState();
    _syncFromGroup();
  }

  @override
  void didUpdateWidget(covariant GroupBasicInfoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group.id != widget.group.id) {
      basicInfoEditable = false;
      selectedImage = null;
      _syncFromGroup();
    }
  }

  void _syncFromGroup() {
    groupNameController.text = I18nHelper.getDisplayNameFromI18n(group.name!);
    selectedGroupCategory = group.groupCategory!;
  }

  @override
  void dispose() {
    groupNameController.dispose();
    super.dispose();
  }

  Map<GroupCategory, String> _categoryMap(BuildContext context) =>
      <GroupCategory, String>{
        GroupCategory.pirate: AppLocalizations.of(context)!.pirate,
        GroupCategory.marine: AppLocalizations.of(context)!.marine,
        GroupCategory.government: AppLocalizations.of(context)!.worldGovernment,
        GroupCategory.underWorld: AppLocalizations.of(context)!.underworld,
        GroupCategory.group: AppLocalizations.of(context)!.group,
        GroupCategory.other: AppLocalizations.of(context)!.otherType,
        GroupCategory.revolutionArmy:
            AppLocalizations.of(context)!.revolutionaryArmy,
      };

  void _submit(BuildContext context) {
    final changed = group.groupCategory != selectedGroupCategory ||
        I18nHelper.getDisplayNameFromI18n(group.name) !=
            groupNameController.text;
    if (changed) {
      // Full group: only name/category change; everything else preserved so
      // the full-column update does not null fatherGroupId / imageUri / records.
      final updated = Group(
        id: group.id,
        fatherGroupId: group.fatherGroupId,
        creationRecordId: group.creationRecordId,
        modificationRecordId: group.modificationRecordId,
        imageUri: group.imageUri,
        groupCategory: selectedGroupCategory,
        name: I18nHelper.getI18nFromDisplayName(
            group.name!, groupNameController.text),
      );
      final router = GoRouter.of(context);
      final alertHint = AppLocalizations.of(context)!.hint;
      final showAlert = OnepieceAlert.createAlertShower(context);
      widget.controller.updateGroups(updated).then((value) {
        if (!mounted) return;
        showAlert(
            alertHint, I18nHelper.getDisplayNameFromI18n(value!.result));
        if (value.success) {
          router.goNamed('groupDetails', extra: group.id, pathParameters: {
            'name': I18nHelper.getDisplayNameFromI18n(updated.name)
          });
        }
      });
    }
    if (selectedImage != null) {
      final router = GoRouter.of(context);
      final alertHint = AppLocalizations.of(context)!.hint;
      final showAlert = OnepieceAlert.createAlertShower(context);
      widget.controller
          .addImage(UploadImageRequest(
              type: ResourceType.GROUP,
              resourceId: group.id,
              image: selectedImage!))
          .then((value) {
        if (!mounted) return;
        showAlert(
            alertHint, I18nHelper.getDisplayNameFromI18n(value!.result));
        router.goNamed('groupDetails', extra: group.id, pathParameters: {
          'name': I18nHelper.getDisplayNameFromI18n(group.name)
        });
      });
    }
  }

  void _toggleEdit() {
    setState(() {
      basicInfoEditable = !basicInfoEditable;
      if (!basicInfoEditable) {
        _submit(context);
      }
    });
  }

  Future<void> _pickImage(BuildContext context) async {
    final alertTitle = AppLocalizations.of(context)!.alert;
    final alertMsg = AppLocalizations.of(context)!.imageSizeExceedsLimit;
    final showAlert = OnepieceAlert.createAlertShower(context);
    final XFile? pickedImage = await OnepieceImagePicker.pickWebImage();
    if (pickedImage == null) return;
    final Uint8List bytes = await pickedImage.readAsBytes();
    if (!mounted) return;
    if (!ImageHelper.isValidImageSize(500 * 1024, bytes)) {
      showAlert(alertTitle, alertMsg);
      return;
    }
    setState(() => selectedImage = Base64Helper.encode(bytes));
  }

  @override
  Widget build(BuildContext context) =>
      widget.isNarrow ? _buildMobile(context) : _buildDesktop(context);

  // ── Mobile ─────────────────────────────────────────────────────────

  Widget _buildMobile(BuildContext context) {
    final catMap = _categoryMap(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
            child: Column(children: [
          ImageLazyLoader(
              uriProvider: () => group.imageUri ?? '',
              width: 120,
              borderWidth: 2,
              borderRadios: 15,
              fullImage: true),
          const SizedBox(height: 8),
          Text(I18nHelper.getDisplayNameFromI18n(group.name),
              style: OnepieceFonts.headerStyle.copyWith(fontSize: 20)),
          const SizedBox(height: 4),
          OnepieceTag.getGroupTag(
              group.groupCategory!, catMap[group.groupCategory]!),
          if (widget.editButtonVisible) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _toggleEdit,
              icon: Icon(basicInfoEditable ? Icons.check : Icons.edit,
                  size: 14, color: OnepieceColors.fancyBlue),
              label: Text(
                  basicInfoEditable
                      ? AppLocalizations.of(context)!.submitForm
                      : AppLocalizations.of(context)!.editHint,
                  style: const TextStyle(
                      fontSize: 11, color: OnepieceColors.fancyBlue)),
            ),
          ],
        ])),
        if (basicInfoEditable) ...[
          const SizedBox(height: 12),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.basicInfo,
                          style:
                              OnepieceFonts.headerStyle.copyWith(fontSize: 16)),
                      const SizedBox(height: 10),
                      SizedBox(
                          height: 35,
                          child: TextFormField(
                            controller: groupNameController,
                            decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.never,
                                disabledBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: OnepieceColors.separator)),
                                enabledBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: OnepieceColors.separator)),
                                focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: OnepieceColors.fancyGreen)),
                                prefixIcon: const Icon(Icons.edit, size: 18),
                                labelText: AppLocalizations.of(context)!.name),
                          )),
                    ])),
          ),
        ],
      ],
    );
  }

  // ── Desktop ────────────────────────────────────────────────────────

  Widget _buildDesktop(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(AppLocalizations.of(context)!.basicInfo,
                style: OnepieceFonts.headerStyle),
            const SizedBox(width: 15),
            if (widget.editButtonVisible)
              Tooltip(
                message: basicInfoEditable
                    ? AppLocalizations.of(context)!.submitForm
                    : AppLocalizations.of(context)!.editHint,
                child: InkWell(
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  onTap: _toggleEdit,
                  child: SizedBox(
                      width: 25,
                      height: 25,
                      child: !basicInfoEditable
                          ? ImageHelper.getSvgIconWithColor('images/svgs/edit.svg',
                              150, 150, OnepieceColors.fancyBlue)
                          : ImageHelper.getSvgIconWithColor('images/svgs/check.svg',
                              150, 150, OnepieceColors.fancyBlue)),
                ),
              ),
          ],
        ),
        InkWell(
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          onTap: basicInfoEditable ? () => _pickImage(context) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: selectedImage == null
                ? ImageLazyLoader(
                    uriProvider: () => group.imageUri!,
                    width: 200,
                    borderWidth: 3,
                    borderRadios: 20,
                    fullImage: true)
                : ImageHelper.getRoundImageFrame(200, 200, 3,
                    OnepieceColors.liteFancyBlue, 20,
                    Base64Helper.decode(selectedImage!)),
          ),
        ),
        StringTextFormField(
            context,
            basicInfoEditable,
            groupNameController,
            AppLocalizations.of(context)!.name,
            30,
            ImageHelper.getTextFormFieldIcon(
                'images/character_digits_icon/name.svg', true, null),
            true),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ImageHelper.getTextFormFieldIcon('images/svgs/type.svg', true, 22),
            const SizedBox(width: 10),
            SizedBox(
              width: 300,
              child: Text(AppLocalizations.of(context)!.category,
                  style: OnepieceFonts.deepBlackHintFont),
            ),
          ],
        ),
        _categoryDropdown(context),
      ],
    );
  }

  Widget _categoryDropdown(BuildContext context) {
    final catMap = _categoryMap(context);
    final isGroupOfGroups = group.groupCategory == GroupCategory.group;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 5, 0, 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2(
          isExpanded: true,
          value: selectedGroupCategory,
          hint: Text(AppLocalizations.of(context)!.groupCategory,
              style: OnepieceFonts.dropDownItemStyle),
          onChanged: !basicInfoEditable || isGroupOfGroups
              ? null
              : (value) {
                  setState(() {
                    selectedGroupCategory = value! as GroupCategory;
                  });
                },
          buttonStyleData: ButtonStyleData(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 35,
              width: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: OnepieceColors.surface,
              )),
          menuItemStyleData: const MenuItemStyleData(height: 35),
          items: GroupCategory.values
              .where((e) =>
                  isGroupOfGroups ? e == GroupCategory.group : e != GroupCategory.group)
              .map((GroupCategory groupCategory) {
            return DropdownMenuItem<GroupCategory>(
              value: groupCategory,
              child: Text(catMap[groupCategory]!,
                  style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
        ),
      ),
    );
  }
}
