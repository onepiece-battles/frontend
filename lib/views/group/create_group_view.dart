import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:one_piece_battles_flutter/utils/string_extensions.dart';
import 'package:openapi/api.dart';
import '../../components/creation_form_card.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../constants/path_constants.dart';
import '../../popup/onepiece_alert.dart';
import '../../utils/base64_helper.dart';
import '../../utils/data_validator.dart';
import '../../utils/i18n_helper.dart';
import '../../utils/image_helper.dart';
import '../../utils/onepiece_image_picker.dart';
import '../../utils/random_string_generator.dart';
import 'create_group_controller.dart';
import '../../l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

GetIt getIt = GetIt.instance;

class CreateGroupView extends StatefulWidget {
  const CreateGroupView({Key? key}) : super(key: key);

  @override
  State<CreateGroupView> createState() => _CreateGroupViewState();
}

class _CreateGroupViewState extends State<CreateGroupView> {
  // name controller
  TextEditingController groupNameEnController = TextEditingController(text: '');
  TextEditingController groupNameChController = TextEditingController(text: '');

  GroupCategory selectedGroupCategory = GroupCategory.pirate;
  final _formKey = GlobalKey<FormState>();
  final CreateGroupController _controller = CreateGroupController();

  @override
  void dispose() {
    groupNameEnController.dispose();
    groupNameChController.dispose();
    _controller.dispose();
    super.dispose();
  }

  List<TextEditingController> groupControlList() {
    return <TextEditingController>[
      groupNameEnController,
      groupNameChController,
    ];
  }

  Uint8List _pickedImage = Uint8List(0);
  bool _newImagePicked = false;
  String _chosenImageName = "";

  Widget _buildMobileLayout(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CreationPageHeader(
            icon: Icons.group_add_rounded,
            title: localizations.createGroup,
          ),
          const SizedBox(height: 18),
          CreationFormCard(
            icon: Icons.flag_rounded,
            title: localizations.basicInfo,
            badge: localizations.required,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _getAvatar(context),
                const SizedBox(height: 18),
                _buildMobileField(
                  context,
                  groupNameChController,
                  '${localizations.groupName} (CN)',
                  Icons.people_rounded,
                ),
                if (getIt<User>().loginRole == UserRole.NIKA)
                  _buildMobileField(
                    context,
                    groupNameEnController,
                    '${localizations.groupName} (EN)',
                    Icons.translate_rounded,
                  ),
                Text(
                  localizations.groupCategory,
                  style: OnepieceFonts.deepBlackHintFont
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 7),
                _getDropDownList(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileField(BuildContext context, TextEditingController ctrl,
      String hint, IconData? icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        validator: (value) {
          if (value == null || value.isWhiteSpace()) {
            return AppLocalizations.of(context)!.requiredField;
          }
          if (!DataValidator.validName(value)) {
            return AppLocalizations.of(context)!.invalidName;
          }
          return null;
        },
        autovalidateMode: AutovalidateMode.onUserInteraction,
        maxLength: 30,
        maxLengthEnforcement: MaxLengthEnforcement.enforced,
        decoration: InputDecoration(
          labelText: hint,
          counterText: '',
          prefixIcon: icon != null ? Icon(icon, size: 20) : null,
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: OnepieceColors.separator),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: OnepieceColors.separator),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: OnepieceColors.fancyGreen, width: 1.6),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            ColoredBox(
              color: const Color(0xFFF5F7FB),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                padding: EdgeInsets.fromLTRB(
                  constraints.maxWidth >= 700 ? 28 : 12,
                  18,
                  constraints.maxWidth >= 700 ? 28 : 12,
                  100,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: _buildMobileLayout(context),
                  ),
                ),
              ),
            ),
            _getFootBar(context),
          ],
        );
      },
    );
  }

  Widget _getAvatar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OnepieceColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECF2)),
      ),
      child: Row(
        children: [
          Container(
            width: 78,
            height: 78,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: OnepieceColors.fancyGreen, width: 2),
            ),
            child: ClipOval(
              child: _pickedImage.isEmpty
                  ? Image.asset(PathConstants.luffyFlag, fit: BoxFit.cover)
                  : Image.memory(_pickedImage, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.uploadGroupEmblem,
                  style: OnepieceFonts.deepBlackHintFont
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickAndProcessImage,
                      icon: const Icon(Icons.upload_rounded, size: 18),
                      label: Text(AppLocalizations.of(context)!.chooseFile),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Text(
                        _chosenImageName.isNotEmpty
                            ? _chosenImageName
                            : AppLocalizations.of(context)!.noFileChosen,
                        style: OnepieceFonts.contentStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  AppLocalizations.of(context)!.maxFileSize500,
                  style: OnepieceFonts.contentStyle.copyWith(
                    color: OnepieceColors.menuIconColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndProcessImage() async {
    if (!mounted) return;
    final alert = AppLocalizations.of(context)!.alert;
    final message = AppLocalizations.of(context)!.imageSizeExceedsLimit;
    final showAlert = OnepieceAlert.createAlertShower(context);
    final pickedImage = await OnepieceImagePicker.pickWebImage();
    if (pickedImage == null) return;
    final imageInByte = await pickedImage.readAsBytes();
    if (!ImageHelper.isValidImageSize(500 * 1024, imageInByte)) {
      showAlert(alert, message);
      return;
    }
    if (!mounted) return;
    setState(() {
      _pickedImage = imageInByte;
      _chosenImageName = pickedImage.name;
      _newImagePicked = true;
    });
  }

  Widget _getDropDownList(BuildContext context) {
    Map<GroupCategory, String> groupCategoryToDisplayName = {
      GroupCategory.marine: AppLocalizations.of(context)!.marine,
      GroupCategory.pirate: AppLocalizations.of(context)!.pirate,
      GroupCategory.underWorld: AppLocalizations.of(context)!.underworld,
      GroupCategory.government: AppLocalizations.of(context)!.worldGovernment,
      GroupCategory.other: AppLocalizations.of(context)!.otherType,
      GroupCategory.group: AppLocalizations.of(context)!.group,
      GroupCategory.revolutionArmy:
          AppLocalizations.of(context)!.revolutionaryArmy,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2(
          isExpanded: true,
          value: selectedGroupCategory,
          hint: Text(
            AppLocalizations.of(context)!.groupCategory,
            style: OnepieceFonts.dropDownItemStyle,
          ),
          onChanged: (value) {
            setState(() {
              selectedGroupCategory = value!;
            });
          },
          selectedItemBuilder: (context) {
            return GroupCategory.values.map(
              (item) {
                return Container(
                  alignment: AlignmentDirectional.center,
                  child: Text(
                    groupCategoryToDisplayName[selectedGroupCategory]!,
                    style: const TextStyle(
                      fontSize: 16,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ).toList();
          },
          buttonStyleData: ButtonStyleData(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 46,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: OnepieceColors.surface,
                border: Border.all(color: OnepieceColors.separator),
              )),
          menuItemStyleData: const MenuItemStyleData(
            height: 35,
          ),
          items: GroupCategory.values.map((GroupCategory groupCategory) {
            return DropdownMenuItem<GroupCategory>(
              value: groupCategory,
              child: Text(
                groupCategoryToDisplayName[groupCategory]!,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _getFootBar(BuildContext context) {
    return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: OnepieceColors.separator, width: 0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(AppLocalizations.of(context)!.clearForm),
                  onPressed: () {
                    setState(() {
                      groupControlList().forEach((element) {
                        element.clear();
                      });
                      _pickedImage = Uint8List(0);
                      _chosenImageName = '';
                      _newImagePicked = false;
                    });
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(132, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 19),
                  onPressed: () {
                    if (!_newImagePicked) {
                      OnepieceAlert.getBasicAlertDialogFunc(
                          context,
                          AppLocalizations.of(context)!.hint,
                          AppLocalizations.of(context)!.groupEmblemRequired);
                      return;
                    }
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }
                    CreateGroupRequest createGroupRequest = CreateGroupRequest(
                      name: RandomStringGenerator.generateI18n(
                          groupNameEnController.text,
                          groupNameChController.text),
                      groupCategory: selectedGroupCategory,
                    );
                    final router = GoRouter.of(context);
                    _controller
                        .createGroup(createGroupRequest)
                        .then((createGroupResponse) {
                      if (!mounted) return;
                      var encodedImage = Base64Helper.encode(_pickedImage);
                      UploadImageRequest uploadImageRequest =
                          UploadImageRequest(
                              resourceId: createGroupResponse!.id.toString(),
                              image: encodedImage,
                              type: ResourceType.GROUP);
                      _controller
                          .addImage(uploadImageRequest)
                          .then((value) {
                        if (!mounted) return;
                        router.goNamed('groupDetails',
                            extra: createGroupResponse.id,
                            pathParameters: {
                              'name': I18nHelper.getDisplayNameFromI18n(
                                  createGroupResponse.name)
                            });
                      });
                    });
                  },
                  label: Text(AppLocalizations.of(context)!.submitForm),
                ),
              ],
            ),
          ),
        ));
  }
}
