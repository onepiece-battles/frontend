import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @accountCheck.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get accountCheck;

  /// No description provided for @accountClosed.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get accountClosed;

  /// No description provided for @accountLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed In'**
  String get accountLoggedIn;

  /// No description provided for @accountLoggedOut.
  ///
  /// In en, this message translates to:
  /// **'Signed Out'**
  String get accountLoggedOut;

  /// No description provided for @accountStopped.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get accountStopped;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @allUserRoles.
  ///
  /// In en, this message translates to:
  /// **'All Roles'**
  String get allUserRoles;

  /// No description provided for @ancientZoanFruit.
  ///
  /// In en, this message translates to:
  /// **'Ancient Zoan'**
  String get ancientZoanFruit;

  /// No description provided for @artificialZoanFruit.
  ///
  /// In en, this message translates to:
  /// **'Artificial Zoan'**
  String get artificialZoanFruit;

  /// No description provided for @attackStrengthen.
  ///
  /// In en, this message translates to:
  /// **'Attack Bonus'**
  String get attackStrengthen;

  /// No description provided for @avatarHeader.
  ///
  /// In en, this message translates to:
  /// **'Public Avatar'**
  String get avatarHeader;

  /// No description provided for @avatarHeaderDescription.
  ///
  /// In en, this message translates to:
  /// **'You can upload your avatar here'**
  String get avatarHeaderDescription;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @backToLoginPage.
  ///
  /// In en, this message translates to:
  /// **'Back to Sign In'**
  String get backToLoginPage;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInfo;

  /// No description provided for @battle.
  ///
  /// In en, this message translates to:
  /// **'Battles'**
  String get battle;

  /// No description provided for @battleFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get battleFinished;

  /// No description provided for @battleInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get battleInProgress;

  /// No description provided for @battleInfo.
  ///
  /// In en, this message translates to:
  /// **'Battle Information'**
  String get battleInfo;

  /// No description provided for @battleStatusCanceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get battleStatusCanceled;

  /// No description provided for @battleStatusCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get battleStatusCreated;

  /// No description provided for @battleStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get battleStatusFailed;

  /// No description provided for @battleStatusFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get battleStatusFinished;

  /// No description provided for @battleUnFinished.
  ///
  /// In en, this message translates to:
  /// **'Unfinished'**
  String get battleUnFinished;

  /// No description provided for @battleNotInProgress.
  ///
  /// In en, this message translates to:
  /// **'Not Started'**
  String get battleNotInProgress;

  /// No description provided for @battleReportWaiting.
  ///
  /// In en, this message translates to:
  /// **'Report Pending'**
  String get battleReportWaiting;

  /// No description provided for @battleReportInProgress.
  ///
  /// In en, this message translates to:
  /// **'Generating Report…'**
  String get battleReportInProgress;

  /// No description provided for @battleReportGenerated.
  ///
  /// In en, this message translates to:
  /// **'Report Available'**
  String get battleReportGenerated;

  /// No description provided for @battleStatusHint.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get battleStatusHint;

  /// No description provided for @battleStatusStarted.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get battleStatusStarted;

  /// No description provided for @battleTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get battleTypeHint;

  /// No description provided for @battleProcess.
  ///
  /// In en, this message translates to:
  /// **'Battle Process'**
  String get battleProcess;

  /// No description provided for @battleDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Battle Details'**
  String get battleDetailTitle;

  /// No description provided for @battleReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Battle Report'**
  String get battleReportTitle;

  /// No description provided for @battleJourneyTitle.
  ///
  /// In en, this message translates to:
  /// **'Battle Progress'**
  String get battleJourneyTitle;

  /// No description provided for @battleStageFighting.
  ///
  /// In en, this message translates to:
  /// **'Battle Underway'**
  String get battleStageFighting;

  /// No description provided for @battleResultConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Result Confirmed'**
  String get battleResultConfirmed;

  /// No description provided for @battleRoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Battle Rounds'**
  String get battleRoundTitle;

  /// No description provided for @battleRoundNumber.
  ///
  /// In en, this message translates to:
  /// **'Round {number}'**
  String battleRoundNumber(int number);

  /// No description provided for @battleRoundNoData.
  ///
  /// In en, this message translates to:
  /// **'No round details are available for this battle.'**
  String get battleRoundNoData;

  /// No description provided for @showAllRounds.
  ///
  /// In en, this message translates to:
  /// **'Show all rounds'**
  String get showAllRounds;

  /// No description provided for @collapseRounds.
  ///
  /// In en, this message translates to:
  /// **'Show fewer rounds'**
  String get collapseRounds;

  /// No description provided for @battleRoundsAfterFinish.
  ///
  /// In en, this message translates to:
  /// **'Round details will appear when the battle finishes.'**
  String get battleRoundsAfterFinish;

  /// No description provided for @battleSkill.
  ///
  /// In en, this message translates to:
  /// **'Skill'**
  String get battleSkill;

  /// No description provided for @battleAttackHit.
  ///
  /// In en, this message translates to:
  /// **'Hit'**
  String get battleAttackHit;

  /// No description provided for @battleAttackMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get battleAttackMissed;

  /// No description provided for @battleDamage.
  ///
  /// In en, this message translates to:
  /// **'Damage'**
  String get battleDamage;

  /// No description provided for @battleEnergySpent.
  ///
  /// In en, this message translates to:
  /// **'Energy spent'**
  String get battleEnergySpent;

  /// No description provided for @battleDefenderEnergyLost.
  ///
  /// In en, this message translates to:
  /// **'Defender energy lost'**
  String get battleDefenderEnergyLost;

  /// No description provided for @battleReportGeneratingDescription.
  ///
  /// In en, this message translates to:
  /// **'The battle is finished. The report is being prepared; you can keep browsing while it completes.'**
  String get battleReportGeneratingDescription;

  /// No description provided for @battleReportWaitingDescription.
  ///
  /// In en, this message translates to:
  /// **'The battle report is waiting to be generated.'**
  String get battleReportWaitingDescription;

  /// No description provided for @battleReportReadyDescription.
  ///
  /// In en, this message translates to:
  /// **'The battle report is ready to download.'**
  String get battleReportReadyDescription;

  /// No description provided for @battleReportVisitorDescription.
  ///
  /// In en, this message translates to:
  /// **'Sign in to download this report.'**
  String get battleReportVisitorDescription;

  /// No description provided for @battleReportPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing the download…'**
  String get battleReportPreparing;

  /// No description provided for @battleFailedDescription.
  ///
  /// In en, this message translates to:
  /// **'This battle could not be completed.'**
  String get battleFailedDescription;

  /// No description provided for @battleAbilities.
  ///
  /// In en, this message translates to:
  /// **'Compare Abilities'**
  String get battleAbilities;

  /// No description provided for @previousBattle.
  ///
  /// In en, this message translates to:
  /// **'Previous battle'**
  String get previousBattle;

  /// No description provided for @nextBattle.
  ///
  /// In en, this message translates to:
  /// **'Next battle'**
  String get nextBattle;

  /// No description provided for @birthDay.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get birthDay;

  /// No description provided for @birthPlace.
  ///
  /// In en, this message translates to:
  /// **'Birthplace'**
  String get birthPlace;

  /// No description provided for @bloodStrengthen.
  ///
  /// In en, this message translates to:
  /// **'Health Bonus'**
  String get bloodStrengthen;

  /// No description provided for @body.
  ///
  /// In en, this message translates to:
  /// **'Martial Arts'**
  String get body;

  /// No description provided for @bounty.
  ///
  /// In en, this message translates to:
  /// **'Bounty'**
  String get bounty;

  /// No description provided for @bugReport.
  ///
  /// In en, this message translates to:
  /// **'Bug Report'**
  String get bugReport;

  /// No description provided for @busoshoku.
  ///
  /// In en, this message translates to:
  /// **'Armament Haki'**
  String get busoshoku;

  /// No description provided for @cancelPopUp.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelPopUp;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @character.
  ///
  /// In en, this message translates to:
  /// **'Character'**
  String get character;

  /// No description provided for @characterAttack.
  ///
  /// In en, this message translates to:
  /// **'Attack'**
  String get characterAttack;

  /// No description provided for @characterBlood.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get characterBlood;

  /// No description provided for @characterDefense.
  ///
  /// In en, this message translates to:
  /// **'Defense'**
  String get characterDefense;

  /// No description provided for @characterDetail.
  ///
  /// In en, this message translates to:
  /// **'Character Details'**
  String get characterDetail;

  /// No description provided for @characterEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get characterEnergy;

  /// No description provided for @characterFruits.
  ///
  /// In en, this message translates to:
  /// **'Devil Fruits'**
  String get characterFruits;

  /// No description provided for @characterImageRequired.
  ///
  /// In en, this message translates to:
  /// **'Please upload a character portrait.'**
  String get characterImageRequired;

  /// No description provided for @characterIntelligence.
  ///
  /// In en, this message translates to:
  /// **'Intelligence'**
  String get characterIntelligence;

  /// No description provided for @characterName.
  ///
  /// In en, this message translates to:
  /// **'Character Name'**
  String get characterName;

  /// No description provided for @characterSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get characterSpeed;

  /// No description provided for @battleStyle.
  ///
  /// In en, this message translates to:
  /// **'Battle Style'**
  String get battleStyle;

  /// No description provided for @chinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get chinese;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose File'**
  String get chooseFile;

  /// No description provided for @chooseFruit.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get chooseFruit;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearAll;

  /// No description provided for @clearForm.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearForm;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @confirmHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmHint;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @createBattle.
  ///
  /// In en, this message translates to:
  /// **'Create Battle'**
  String get createBattle;

  /// No description provided for @createCharacter.
  ///
  /// In en, this message translates to:
  /// **'Create Character'**
  String get createCharacter;

  /// No description provided for @createDevilFruit.
  ///
  /// In en, this message translates to:
  /// **'Create Devil Fruit'**
  String get createDevilFruit;

  /// No description provided for @createGroup.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get createGroup;

  /// No description provided for @createdBySystem.
  ///
  /// In en, this message translates to:
  /// **'System Resource'**
  String get createdBySystem;

  /// No description provided for @creationTime.
  ///
  /// In en, this message translates to:
  /// **'Creation Time'**
  String get creationTime;

  /// No description provided for @creator.
  ///
  /// In en, this message translates to:
  /// **'Creator'**
  String get creator;

  /// No description provided for @defenseStrengthen.
  ///
  /// In en, this message translates to:
  /// **'Defense Bonus'**
  String get defenseStrengthen;

  /// No description provided for @detailInformation.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailInformation;

  /// No description provided for @devilFruit.
  ///
  /// In en, this message translates to:
  /// **'Devil Fruit'**
  String get devilFruit;

  /// No description provided for @downloadReport.
  ///
  /// In en, this message translates to:
  /// **'Download Battle Report'**
  String get downloadReport;

  /// No description provided for @eat.
  ///
  /// In en, this message translates to:
  /// **'Eat'**
  String get eat;

  /// No description provided for @editHint.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editHint;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailAddress;

  /// No description provided for @emailSetting.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailSetting;

  /// No description provided for @emailStatus.
  ///
  /// In en, this message translates to:
  /// **'Email Status'**
  String get emailStatus;

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get empty;

  /// No description provided for @endOfList.
  ///
  /// In en, this message translates to:
  /// **'End of list'**
  String get endOfList;

  /// No description provided for @energyConsume.
  ///
  /// In en, this message translates to:
  /// **'Energy Cost'**
  String get energyConsume;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @featureSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Feature Suggestion'**
  String get featureSuggestion;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @feedbackContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get feedbackContent;

  /// No description provided for @feedbackContentHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue or suggestion in detail.'**
  String get feedbackContentHint;

  /// No description provided for @feedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get feedbackTitle;

  /// No description provided for @feedbackTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Briefly describe your issue or suggestion.'**
  String get feedbackTitleHint;

  /// No description provided for @fieldMustBeInt.
  ///
  /// In en, this message translates to:
  /// **'Please enter a whole number.'**
  String get fieldMustBeInt;

  /// No description provided for @fist.
  ///
  /// In en, this message translates to:
  /// **'Fist'**
  String get fist;

  /// No description provided for @fruitLimit.
  ///
  /// In en, this message translates to:
  /// **'Fruit Limit'**
  String get fruitLimit;

  /// No description provided for @fruitName.
  ///
  /// In en, this message translates to:
  /// **'Devil Fruit Name'**
  String get fruitName;

  /// No description provided for @fruitOwner.
  ///
  /// In en, this message translates to:
  /// **'Fruit Owners'**
  String get fruitOwner;

  /// No description provided for @fruitType.
  ///
  /// In en, this message translates to:
  /// **'Devil Fruit Type'**
  String get fruitType;

  /// No description provided for @group.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get group;

  /// No description provided for @groupBattle.
  ///
  /// In en, this message translates to:
  /// **'Group Battle'**
  String get groupBattle;

  /// No description provided for @groupCategory.
  ///
  /// In en, this message translates to:
  /// **'Group Category'**
  String get groupCategory;

  /// No description provided for @groupEmblemRequired.
  ///
  /// In en, this message translates to:
  /// **'Please upload a group emblem.'**
  String get groupEmblemRequired;

  /// No description provided for @groupGain.
  ///
  /// In en, this message translates to:
  /// **'Teamwork Bonus (%)'**
  String get groupGain;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupName;

  /// No description provided for @groupStrengthen.
  ///
  /// In en, this message translates to:
  /// **'Teamwork Bonus'**
  String get groupStrengthen;

  /// No description provided for @hakis.
  ///
  /// In en, this message translates to:
  /// **'Haki'**
  String get hakis;

  /// No description provided for @haoshoku.
  ///
  /// In en, this message translates to:
  /// **'Conqueror’s Haki'**
  String get haoshoku;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get height;

  /// No description provided for @helloWorld.
  ///
  /// In en, this message translates to:
  /// **'Hello World!'**
  String get helloWorld;

  /// No description provided for @hint.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get hint;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @initiator.
  ///
  /// In en, this message translates to:
  /// **'Initiator'**
  String get initiator;

  /// No description provided for @intelligenceStrengthen.
  ///
  /// In en, this message translates to:
  /// **'Intelligence Bonus'**
  String get intelligenceStrengthen;

  /// No description provided for @invalidName.
  ///
  /// In en, this message translates to:
  /// **'Use letters, Chinese characters, numbers, spaces, hyphens, middle dots, or periods.'**
  String get invalidName;

  /// No description provided for @issue.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get issue;

  /// No description provided for @issueType.
  ///
  /// In en, this message translates to:
  /// **'Issue Type'**
  String get issueType;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @jumpToPage.
  ///
  /// In en, this message translates to:
  /// **'Jump'**
  String get jumpToPage;

  /// No description provided for @katana.
  ///
  /// In en, this message translates to:
  /// **'Katana'**
  String get katana;

  /// No description provided for @kenbunshoku.
  ///
  /// In en, this message translates to:
  /// **'Observation Haki'**
  String get kenbunshoku;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @leaved.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get leaved;

  /// No description provided for @leg.
  ///
  /// In en, this message translates to:
  /// **'Leg'**
  String get leg;

  /// No description provided for @listToEnd.
  ///
  /// In en, this message translates to:
  /// **'End of list'**
  String get listToEnd;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @localizationDescription.
  ///
  /// In en, this message translates to:
  /// **'Customize your language and region settings.'**
  String get localizationDescription;

  /// No description provided for @localizationHeader.
  ///
  /// In en, this message translates to:
  /// **'Language and Region'**
  String get localizationHeader;

  /// No description provided for @logiaFruit.
  ///
  /// In en, this message translates to:
  /// **'Logia'**
  String get logiaFruit;

  /// No description provided for @loginRole.
  ///
  /// In en, this message translates to:
  /// **'Sign-in Role'**
  String get loginRole;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get logout;

  /// No description provided for @marine.
  ///
  /// In en, this message translates to:
  /// **'Marine'**
  String get marine;

  /// No description provided for @maxFileSizeDescription.
  ///
  /// In en, this message translates to:
  /// **'Maximum file size: 200 KB.'**
  String get maxFileSizeDescription;

  /// No description provided for @modificationTime.
  ///
  /// In en, this message translates to:
  /// **'Modification Time'**
  String get modificationTime;

  /// No description provided for @mythicalZoanFruit.
  ///
  /// In en, this message translates to:
  /// **'Mythical Zoan'**
  String get mythicalZoanFruit;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @nickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nickname;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'No account?'**
  String get noAccount;

  /// No description provided for @noFileChosen.
  ///
  /// In en, this message translates to:
  /// **'No file chosen'**
  String get noFileChosen;

  /// No description provided for @noSystemResource.
  ///
  /// In en, this message translates to:
  /// **'Exclude System Resources'**
  String get noSystemResource;

  /// No description provided for @notVerified.
  ///
  /// In en, this message translates to:
  /// **'Not Verified'**
  String get notVerified;

  /// No description provided for @onButton.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get onButton;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @organization.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get organization;

  /// No description provided for @otherType.
  ///
  /// In en, this message translates to:
  /// **'Other Types'**
  String get otherType;

  /// No description provided for @parameciaFruit.
  ///
  /// In en, this message translates to:
  /// **'Paramecia'**
  String get parameciaFruit;

  /// No description provided for @passWordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passWordHint;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @pirate.
  ///
  /// In en, this message translates to:
  /// **'Pirate'**
  String get pirate;

  /// No description provided for @receiver.
  ///
  /// In en, this message translates to:
  /// **'Opponent'**
  String get receiver;

  /// No description provided for @registerAccount.
  ///
  /// In en, this message translates to:
  /// **'Register Now'**
  String get registerAccount;

  /// No description provided for @registerPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get registerPasswordHint;

  /// No description provided for @registerPasswordHint2.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get registerPasswordHint2;

  /// No description provided for @registerUserNameHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a nickname'**
  String get registerUserNameHint;

  /// No description provided for @relatedBattles.
  ///
  /// In en, this message translates to:
  /// **'Related Battles'**
  String get relatedBattles;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required field'**
  String get requiredField;

  /// No description provided for @resetSort.
  ///
  /// In en, this message translates to:
  /// **'Reset Sort'**
  String get resetSort;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get roleAdmin;

  /// No description provided for @roleNika.
  ///
  /// In en, this message translates to:
  /// **'Nika'**
  String get roleNika;

  /// No description provided for @roleNormal.
  ///
  /// In en, this message translates to:
  /// **'Standard User'**
  String get roleNormal;

  /// No description provided for @roleVisitor.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get roleVisitor;

  /// No description provided for @route.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get route;

  /// No description provided for @science.
  ///
  /// In en, this message translates to:
  /// **'Science'**
  String get science;

  /// No description provided for @searchReceiver.
  ///
  /// In en, this message translates to:
  /// **'Search opponents…'**
  String get searchReceiver;

  /// No description provided for @searchResource.
  ///
  /// In en, this message translates to:
  /// **'Search Resources'**
  String get searchResource;

  /// No description provided for @searchResourceDetail.
  ///
  /// In en, this message translates to:
  /// **'Character, Devil Fruit, or group name'**
  String get searchResourceDetail;

  /// No description provided for @searchStarter.
  ///
  /// In en, this message translates to:
  /// **'Search initiators…'**
  String get searchStarter;

  /// No description provided for @selectCharacter.
  ///
  /// In en, this message translates to:
  /// **'Select Character'**
  String get selectCharacter;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @shoot.
  ///
  /// In en, this message translates to:
  /// **'Marksmanship'**
  String get shoot;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @signUpHeadLine.
  ///
  /// In en, this message translates to:
  /// **'Create a free account'**
  String get signUpHeadLine;

  /// No description provided for @singleBattle.
  ///
  /// In en, this message translates to:
  /// **'One-on-One'**
  String get singleBattle;

  /// No description provided for @speedStrengthen.
  ///
  /// In en, this message translates to:
  /// **'Speed Bonus'**
  String get speedStrengthen;

  /// No description provided for @startBattle.
  ///
  /// In en, this message translates to:
  /// **'Start Battle'**
  String get startBattle;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @statusBackLogged.
  ///
  /// In en, this message translates to:
  /// **'Backlog'**
  String get statusBackLogged;

  /// No description provided for @statusCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get statusCreated;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get statusResolved;

  /// No description provided for @statusRevoked.
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get statusRevoked;

  /// No description provided for @submitForm.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submitForm;

  /// No description provided for @systemResource.
  ///
  /// In en, this message translates to:
  /// **'System Resource'**
  String get systemResource;

  /// No description provided for @thisCharacter.
  ///
  /// In en, this message translates to:
  /// **'This Character'**
  String get thisCharacter;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @underworld.
  ///
  /// In en, this message translates to:
  /// **'Underworld'**
  String get underworld;

  /// No description provided for @unselected.
  ///
  /// In en, this message translates to:
  /// **'Unselected'**
  String get unselected;

  /// No description provided for @updateUserSettings.
  ///
  /// In en, this message translates to:
  /// **'Update User Settings'**
  String get updateUserSettings;

  /// No description provided for @uploadGroupEmblem.
  ///
  /// In en, this message translates to:
  /// **'Upload Group Emblem'**
  String get uploadGroupEmblem;

  /// No description provided for @uploadNewAvatar.
  ///
  /// In en, this message translates to:
  /// **'Upload Avatar'**
  String get uploadNewAvatar;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @userManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagement;

  /// No description provided for @userNameHint.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get userNameHint;

  /// No description provided for @userNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get userNameLabel;

  /// No description provided for @valueExceedsLimit.
  ///
  /// In en, this message translates to:
  /// **'Value exceeds the allowed range.'**
  String get valueExceedsLimit;

  /// No description provided for @valueRange.
  ///
  /// In en, this message translates to:
  /// **'Allowed range: '**
  String get valueRange;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Onepiece Battles'**
  String get welcome;

  /// No description provided for @winner.
  ///
  /// In en, this message translates to:
  /// **'Winner'**
  String get winner;

  /// No description provided for @worldGovernment.
  ///
  /// In en, this message translates to:
  /// **'World Government'**
  String get worldGovernment;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @zoanFruit.
  ///
  /// In en, this message translates to:
  /// **'Zoan'**
  String get zoanFruit;

  /// No description provided for @onceBelongTo.
  ///
  /// In en, this message translates to:
  /// **'Former Member'**
  String get onceBelongTo;

  /// No description provided for @userProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get userProfile;

  /// No description provided for @sendEmail.
  ///
  /// In en, this message translates to:
  /// **'Send Verification Email'**
  String get sendEmail;

  /// No description provided for @emailVerification.
  ///
  /// In en, this message translates to:
  /// **'Email Verification'**
  String get emailVerification;

  /// No description provided for @emailSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent'**
  String get emailSent;

  /// No description provided for @myCharacters.
  ///
  /// In en, this message translates to:
  /// **'My Characters'**
  String get myCharacters;

  /// No description provided for @myGroups.
  ///
  /// In en, this message translates to:
  /// **'My Groups'**
  String get myGroups;

  /// No description provided for @myBattles.
  ///
  /// In en, this message translates to:
  /// **'My Battles'**
  String get myBattles;

  /// No description provided for @homePage.
  ///
  /// In en, this message translates to:
  /// **'My Home'**
  String get homePage;

  /// No description provided for @selectTypeWarning.
  ///
  /// In en, this message translates to:
  /// **'Please select a type.'**
  String get selectTypeWarning;

  /// No description provided for @notCreated.
  ///
  /// In en, this message translates to:
  /// **'Not Created'**
  String get notCreated;

  /// No description provided for @goToCreationPage.
  ///
  /// In en, this message translates to:
  /// **'Create Now'**
  String get goToCreationPage;

  /// No description provided for @characters.
  ///
  /// In en, this message translates to:
  /// **'characters'**
  String get characters;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'MM'**
  String get month;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'DD'**
  String get day;

  /// No description provided for @historyGroups.
  ///
  /// In en, this message translates to:
  /// **'Former Groups'**
  String get historyGroups;

  /// No description provided for @searchList.
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get searchList;

  /// No description provided for @eaten.
  ///
  /// In en, this message translates to:
  /// **'Eaten'**
  String get eaten;

  /// No description provided for @verificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get verificationCode;

  /// No description provided for @currentMember.
  ///
  /// In en, this message translates to:
  /// **'Current Member'**
  String get currentMember;

  /// No description provided for @exMember.
  ///
  /// In en, this message translates to:
  /// **'Former Member'**
  String get exMember;

  /// No description provided for @groupMember.
  ///
  /// In en, this message translates to:
  /// **'Group Member'**
  String get groupMember;

  /// No description provided for @wakeUp.
  ///
  /// In en, this message translates to:
  /// **'Awakened'**
  String get wakeUp;

  /// No description provided for @sleep.
  ///
  /// In en, this message translates to:
  /// **'Not Awakened'**
  String get sleep;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @currentlyNone.
  ///
  /// In en, this message translates to:
  /// **'None yet'**
  String get currentlyNone;

  /// No description provided for @human.
  ///
  /// In en, this message translates to:
  /// **'Human'**
  String get human;

  /// No description provided for @fishman.
  ///
  /// In en, this message translates to:
  /// **'Fish-Man'**
  String get fishman;

  /// No description provided for @merfolk.
  ///
  /// In en, this message translates to:
  /// **'Merfolk'**
  String get merfolk;

  /// No description provided for @giant.
  ///
  /// In en, this message translates to:
  /// **'Giant'**
  String get giant;

  /// No description provided for @longArm.
  ///
  /// In en, this message translates to:
  /// **'Longarm Tribe'**
  String get longArm;

  /// No description provided for @longLeg.
  ///
  /// In en, this message translates to:
  /// **'Longleg Tribe'**
  String get longLeg;

  /// No description provided for @snakeNeck.
  ///
  /// In en, this message translates to:
  /// **'Snakeneck Tribe'**
  String get snakeNeck;

  /// No description provided for @threeEye.
  ///
  /// In en, this message translates to:
  /// **'Three-Eye Tribe'**
  String get threeEye;

  /// No description provided for @lunarian.
  ///
  /// In en, this message translates to:
  /// **'Lunarian'**
  String get lunarian;

  /// No description provided for @mink.
  ///
  /// In en, this message translates to:
  /// **'Mink Tribe'**
  String get mink;

  /// No description provided for @worldNobel.
  ///
  /// In en, this message translates to:
  /// **'Celestial Dragon (Human)'**
  String get worldNobel;

  /// No description provided for @dwarves.
  ///
  /// In en, this message translates to:
  /// **'Dwarf'**
  String get dwarves;

  /// No description provided for @race.
  ///
  /// In en, this message translates to:
  /// **'Race'**
  String get race;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @starterName.
  ///
  /// In en, this message translates to:
  /// **'Initiator'**
  String get starterName;

  /// No description provided for @receiverName.
  ///
  /// In en, this message translates to:
  /// **'Opponent'**
  String get receiverName;

  /// No description provided for @accountStatus.
  ///
  /// In en, this message translates to:
  /// **'Account Status'**
  String get accountStatus;

  /// No description provided for @showAllRoleResources.
  ///
  /// In en, this message translates to:
  /// **'Show resources created by all user roles'**
  String get showAllRoleResources;

  /// No description provided for @creatorEmail.
  ///
  /// In en, this message translates to:
  /// **'Creator Email'**
  String get creatorEmail;

  /// No description provided for @creatorNickname.
  ///
  /// In en, this message translates to:
  /// **'Creator Nickname'**
  String get creatorNickname;

  /// No description provided for @joined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joined;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @retrievePassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get retrievePassword;

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'Crew Member'**
  String get member;

  /// No description provided for @caption.
  ///
  /// In en, this message translates to:
  /// **'Captain'**
  String get caption;

  /// No description provided for @combatant.
  ///
  /// In en, this message translates to:
  /// **'Combatant'**
  String get combatant;

  /// No description provided for @cook.
  ///
  /// In en, this message translates to:
  /// **'Cook'**
  String get cook;

  /// No description provided for @doctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctor;

  /// No description provided for @firstMate.
  ///
  /// In en, this message translates to:
  /// **'First Mate'**
  String get firstMate;

  /// No description provided for @helmsman.
  ///
  /// In en, this message translates to:
  /// **'Helmsman'**
  String get helmsman;

  /// No description provided for @intern.
  ///
  /// In en, this message translates to:
  /// **'Intern'**
  String get intern;

  /// No description provided for @musician.
  ///
  /// In en, this message translates to:
  /// **'Musician'**
  String get musician;

  /// No description provided for @navigator.
  ///
  /// In en, this message translates to:
  /// **'Navigator'**
  String get navigator;

  /// No description provided for @scholar.
  ///
  /// In en, this message translates to:
  /// **'Scholar'**
  String get scholar;

  /// No description provided for @shipwright.
  ///
  /// In en, this message translates to:
  /// **'Shipwright'**
  String get shipwright;

  /// No description provided for @positionList.
  ///
  /// In en, this message translates to:
  /// **'Positions'**
  String get positionList;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword;

  /// No description provided for @combatPower.
  ///
  /// In en, this message translates to:
  /// **'Battle Rating'**
  String get combatPower;

  /// No description provided for @getByJoinCombat.
  ///
  /// In en, this message translates to:
  /// **'Increase your rating by taking part in battles.'**
  String get getByJoinCombat;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @combatScoreChange.
  ///
  /// In en, this message translates to:
  /// **'Score Change'**
  String get combatScoreChange;

  /// No description provided for @position.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get position;

  /// No description provided for @loginInfo.
  ///
  /// In en, this message translates to:
  /// **'Sign-in Information'**
  String get loginInfo;

  /// No description provided for @loginRoleOrLastLoginRole.
  ///
  /// In en, this message translates to:
  /// **'Current or Last Sign-in Role'**
  String get loginRoleOrLastLoginRole;

  /// No description provided for @permissionInfo.
  ///
  /// In en, this message translates to:
  /// **'Permission Information'**
  String get permissionInfo;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @issueDetail.
  ///
  /// In en, this message translates to:
  /// **'Feedback Details'**
  String get issueDetail;

  /// No description provided for @viewReport.
  ///
  /// In en, this message translates to:
  /// **'View Report'**
  String get viewReport;

  /// No description provided for @imageSizeExceedsLimit.
  ///
  /// In en, this message translates to:
  /// **'The image exceeds the size limit.'**
  String get imageSizeExceedsLimit;

  /// No description provided for @alert.
  ///
  /// In en, this message translates to:
  /// **'⚠️'**
  String get alert;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get search;

  /// No description provided for @fieldMustBeDigit.
  ///
  /// In en, this message translates to:
  /// **'Please enter a number.'**
  String get fieldMustBeDigit;

  /// No description provided for @basicValue.
  ///
  /// In en, this message translates to:
  /// **'Base value'**
  String get basicValue;

  /// No description provided for @statMultiplier.
  ///
  /// In en, this message translates to:
  /// **'Multiplier'**
  String get statMultiplier;

  /// No description provided for @statAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get statAdjustment;

  /// No description provided for @statFormulaHint.
  ///
  /// In en, this message translates to:
  /// **'Result = base value × multiplier + adjustment'**
  String get statFormulaHint;

  /// No description provided for @realValue.
  ///
  /// In en, this message translates to:
  /// **'With Fruit Bonuses'**
  String get realValue;

  /// No description provided for @startSuccess.
  ///
  /// In en, this message translates to:
  /// **'Started successfully'**
  String get startSuccess;

  /// No description provided for @searchResourceShortcut.
  ///
  /// In en, this message translates to:
  /// **'[ / ]'**
  String get searchResourceShortcut;

  /// No description provided for @searchResourceShortcutShrink.
  ///
  /// In en, this message translates to:
  /// **'[/]'**
  String get searchResourceShortcutShrink;

  /// No description provided for @revolutionaryArmy.
  ///
  /// In en, this message translates to:
  /// **'Revolutionary Army'**
  String get revolutionaryArmy;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @invalidPassword.
  ///
  /// In en, this message translates to:
  /// **'Use only letters, numbers, and underscores.'**
  String get invalidPassword;

  /// No description provided for @invalidNickname.
  ///
  /// In en, this message translates to:
  /// **'Use only letters, numbers, and Chinese characters.'**
  String get invalidNickname;

  /// No description provided for @passwordNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordNotMatch;

  /// No description provided for @lengthExceedsLimit.
  ///
  /// In en, this message translates to:
  /// **'Use no more than 20 characters.'**
  String get lengthExceedsLimit;

  /// No description provided for @reselect.
  ///
  /// In en, this message translates to:
  /// **'Reselect'**
  String get reselect;

  /// No description provided for @groupStructure.
  ///
  /// In en, this message translates to:
  /// **'Group Structure'**
  String get groupStructure;

  /// No description provided for @groupZoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get groupZoomIn;

  /// No description provided for @groupZoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get groupZoomOut;

  /// No description provided for @groupFitView.
  ///
  /// In en, this message translates to:
  /// **'Fit hierarchy'**
  String get groupFitView;

  /// No description provided for @groupExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand branch'**
  String get groupExpand;

  /// No description provided for @groupCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse branch'**
  String get groupCollapse;

  /// No description provided for @fatherGroups.
  ///
  /// In en, this message translates to:
  /// **'Parent Groups'**
  String get fatherGroups;

  /// No description provided for @thisGroup.
  ///
  /// In en, this message translates to:
  /// **'Current Group'**
  String get thisGroup;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @selectable.
  ///
  /// In en, this message translates to:
  /// **'Selectable'**
  String get selectable;

  /// No description provided for @selectNewMembers.
  ///
  /// In en, this message translates to:
  /// **'Add Members'**
  String get selectNewMembers;

  /// No description provided for @myAccount.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get myAccount;

  /// No description provided for @maxFileSize500.
  ///
  /// In en, this message translates to:
  /// **'Maximum file size: 500 KB.'**
  String get maxFileSize500;

  /// No description provided for @animal.
  ///
  /// In en, this message translates to:
  /// **'Animal'**
  String get animal;

  /// No description provided for @soul.
  ///
  /// In en, this message translates to:
  /// **'Supernatural Object'**
  String get soul;

  /// No description provided for @lifeless_object.
  ///
  /// In en, this message translates to:
  /// **'Inanimate Object'**
  String get lifeless_object;

  /// No description provided for @sword.
  ///
  /// In en, this message translates to:
  /// **'Sword'**
  String get sword;

  /// No description provided for @stick.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get stick;

  /// No description provided for @rifle.
  ///
  /// In en, this message translates to:
  /// **'Rifle'**
  String get rifle;

  /// No description provided for @fightAgain.
  ///
  /// In en, this message translates to:
  /// **'Fight Again'**
  String get fightAgain;

  /// No description provided for @loginAsVisitor.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get loginAsVisitor;

  /// No description provided for @allResources.
  ///
  /// In en, this message translates to:
  /// **'All Resources'**
  String get allResources;

  /// No description provided for @myResource.
  ///
  /// In en, this message translates to:
  /// **'My Resources'**
  String get myResource;

  /// No description provided for @excludeSystem.
  ///
  /// In en, this message translates to:
  /// **'Exclude System Resources'**
  String get excludeSystem;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get message;

  /// No description provided for @createChatting.
  ///
  /// In en, this message translates to:
  /// **'New Group Chat'**
  String get createChatting;

  /// No description provided for @addFriend.
  ///
  /// In en, this message translates to:
  /// **'Add Friends'**
  String get addFriend;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @chatting.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatting;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @noChatting.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noChatting;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @loadEarlierMessages.
  ///
  /// In en, this message translates to:
  /// **'Load earlier messages'**
  String get loadEarlierMessages;

  /// No description provided for @noEarlierMessages.
  ///
  /// In en, this message translates to:
  /// **'No earlier messages'**
  String get noEarlierMessages;

  /// No description provided for @cancelSelection.
  ///
  /// In en, this message translates to:
  /// **'Cancel Selection'**
  String get cancelSelection;

  /// No description provided for @draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// No description provided for @reference.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reference;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @chatInformation.
  ///
  /// In en, this message translates to:
  /// **'Chat information'**
  String get chatInformation;

  /// No description provided for @chatPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get chatPrivate;

  /// No description provided for @chatUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get chatUnread;

  /// No description provided for @chatActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get chatActions;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get clearHistory;

  /// No description provided for @leaveGroup.
  ///
  /// In en, this message translates to:
  /// **'Leave group'**
  String get leaveGroup;

  /// No description provided for @groupRenameApiNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Renaming group chats is not available yet.'**
  String get groupRenameApiNotConnected;

  /// No description provided for @addMemberApiNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Adding members is not available yet.'**
  String get addMemberApiNotConnected;

  /// No description provided for @addCharactersToGroup.
  ///
  /// In en, this message translates to:
  /// **'Add characters'**
  String get addCharactersToGroup;

  /// No description provided for @noCharactersFound.
  ///
  /// In en, this message translates to:
  /// **'No characters found'**
  String get noCharactersFound;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @messageRetracted.
  ///
  /// In en, this message translates to:
  /// **'This message was deleted'**
  String get messageRetracted;

  /// No description provided for @messageStillSending.
  ///
  /// In en, this message translates to:
  /// **'Please wait until the message finishes sending'**
  String get messageStillSending;

  /// No description provided for @messageNotSent.
  ///
  /// In en, this message translates to:
  /// **'Message not sent — connection lost. Please try again.'**
  String get messageNotSent;

  /// No description provided for @previousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous Page'**
  String get previousPage;

  /// No description provided for @nextPage.
  ///
  /// In en, this message translates to:
  /// **'Next Page'**
  String get nextPage;

  /// No description provided for @jumpToPageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Jump to Page'**
  String get jumpToPageTooltip;

  /// No description provided for @pageNumber.
  ///
  /// In en, this message translates to:
  /// **'Page Number'**
  String get pageNumber;

  /// No description provided for @pinMenu.
  ///
  /// In en, this message translates to:
  /// **'Pin Menu'**
  String get pinMenu;

  /// No description provided for @backToDrawer.
  ///
  /// In en, this message translates to:
  /// **'Use Drawer Menu'**
  String get backToDrawer;

  /// No description provided for @collapseMenu.
  ///
  /// In en, this message translates to:
  /// **'Collapse Menu'**
  String get collapseMenu;

  /// No description provided for @expandMenu.
  ///
  /// In en, this message translates to:
  /// **'Expand Menu'**
  String get expandMenu;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @saveAvatarFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your avatar. Please try again.'**
  String get saveAvatarFailed;

  /// No description provided for @sendVerificationEmailFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send the verification email. Please try again.'**
  String get sendVerificationEmailFailed;

  /// No description provided for @saveNicknameFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your nickname. Please try again.'**
  String get saveNicknameFailed;

  /// No description provided for @newConversation.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newConversation;

  /// No description provided for @versus.
  ///
  /// In en, this message translates to:
  /// **'VS'**
  String get versus;

  /// No description provided for @characterCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 character} other{{count} characters}}'**
  String characterCount(int count);

  /// No description provided for @fruitCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Devil Fruit} other{{count} Devil Fruits}}'**
  String fruitCount(int count);

  /// No description provided for @userCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 user} other{{count} users}}'**
  String userCount(int count);

  /// No description provided for @issueCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 feedback item} other{{count} feedback items}}'**
  String issueCount(int count);

  /// No description provided for @relatedBattleCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 related battle} other{{count} related battles}}'**
  String relatedBattleCount(int count);

  /// No description provided for @characterLimitCounter.
  ///
  /// In en, this message translates to:
  /// **'{current}/{max} characters'**
  String characterLimitCounter(int current, int max);

  /// No description provided for @resourceLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load resources. Please try again.'**
  String get resourceLoadFailed;

  /// No description provided for @noResourcesFound.
  ///
  /// In en, this message translates to:
  /// **'No resources found'**
  String get noResourcesFound;

  /// No description provided for @retryLoading.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retryLoading;

  /// No description provided for @resourceNoHolders.
  ///
  /// In en, this message translates to:
  /// **'No holders yet'**
  String get resourceNoHolders;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
