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

  /// Display name of the app, used in launcher and splash.
  ///
  /// In en, this message translates to:
  /// **'Velvet'**
  String get appName;

  /// Feed tab · all moments.
  ///
  /// In en, this message translates to:
  /// **'ALL'**
  String get tabAll;

  /// Feed tab · followed users' moments.
  ///
  /// In en, this message translates to:
  /// **'FOLLOW'**
  String get tabFollow;

  /// Feed tab · same-city / nearby moments.
  ///
  /// In en, this message translates to:
  /// **'NEARBY'**
  String get tabNearby;

  /// Feed tab · personalized recommendations.
  ///
  /// In en, this message translates to:
  /// **'FOR YOU'**
  String get tabRecommend;

  /// Retry CTA on error / empty states (RetryChip default label).
  ///
  /// In en, this message translates to:
  /// **'RETRY'**
  String get retryButton;

  /// Generic loading indicator label.
  ///
  /// In en, this message translates to:
  /// **'LOADING'**
  String get loadingLabel;

  /// Empty state title on the main feed when zero moments exist.
  ///
  /// In en, this message translates to:
  /// **'— NO STORIES YET —'**
  String get emptyFeedTitle;

  /// Empty state subtitle inviting user to publish their first moment.
  ///
  /// In en, this message translates to:
  /// **'Tap + below to hang your first'**
  String get emptyFeedSubtitle;

  /// Empty state title on the recommend tab when no personalized results are available.
  ///
  /// In en, this message translates to:
  /// **'— NO TASTE MATCH YET —'**
  String get emptyRecommendTitle;

  /// Empty state subtitle on recommend tab encouraging interaction.
  ///
  /// In en, this message translates to:
  /// **'Tap more hearts, let time find your match'**
  String get emptyRecommendSubtitle;

  /// Empty state title on chat list when there are zero conversations.
  ///
  /// In en, this message translates to:
  /// **'— NO WHISPERS YET —'**
  String get emptyChatTitle;

  /// Empty state subtitle on chat list · editorial reassurance.
  ///
  /// In en, this message translates to:
  /// **'The right ones will find you'**
  String get emptyChatSubtitle;

  /// Search screen initial empty state title (before any query is entered).
  ///
  /// In en, this message translates to:
  /// **'What are you looking for'**
  String get emptySearchInitialTitle;

  /// Search screen initial empty state subtitle suggesting sample queries.
  ///
  /// In en, this message translates to:
  /// **'Try silk  vintage  night ...'**
  String get emptySearchInitialSubtitle;

  /// Search screen no-result empty state title.
  ///
  /// In en, this message translates to:
  /// **'— NOT HERE YET —'**
  String get emptySearchNoResultTitle;

  /// Search screen no-result subtitle inviting user to rephrase.
  ///
  /// In en, this message translates to:
  /// **'Try another word'**
  String get emptySearchNoResultSubtitle;

  /// Orders screen empty state title (buyer / seller tab).
  ///
  /// In en, this message translates to:
  /// **'— NO ORDERS —'**
  String get emptyOrderBuyerTitle;

  /// Orders screen buyer-side empty subtitle inviting discovery.
  ///
  /// In en, this message translates to:
  /// **'Browse around, find something that moves you'**
  String get emptyOrderBuyerSubtitle;

  /// Orders screen seller-side empty subtitle.
  ///
  /// In en, this message translates to:
  /// **'No trades yet, good things find their people'**
  String get emptyOrderSellerSubtitle;

  /// Favorites screen empty state title.
  ///
  /// In en, this message translates to:
  /// **'— NO SAVES YET —'**
  String get emptyFavoritesTitle;

  /// Favorites screen empty state subtitle.
  ///
  /// In en, this message translates to:
  /// **'tap heart to keep what moves you'**
  String get emptyFavoritesSubtitle;

  /// Generic error / not-found title.
  ///
  /// In en, this message translates to:
  /// **'— NOT FOUND —'**
  String get errorGenericTitle;

  /// Generic network failure message.
  ///
  /// In en, this message translates to:
  /// **'Network error, please try again'**
  String get errorNetworkMessage;

  /// Onboarding skip CTA (J2 owned file · declared here so locale is complete).
  ///
  /// In en, this message translates to:
  /// **'SKIP'**
  String get onboardingSkip;

  /// Onboarding final CTA.
  ///
  /// In en, this message translates to:
  /// **'BEGIN'**
  String get onboardingBegin;

  /// Onboarding next-page CTA.
  ///
  /// In en, this message translates to:
  /// **'NEXT'**
  String get onboardingNext;

  /// Appearance mode · light.
  ///
  /// In en, this message translates to:
  /// **'LIGHT'**
  String get themeLight;

  /// Appearance mode · dark.
  ///
  /// In en, this message translates to:
  /// **'DARK'**
  String get themeDark;

  /// Appearance mode · follow system.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM'**
  String get themeSystem;

  /// Profile screen appearance section header.
  ///
  /// In en, this message translates to:
  /// **'APPEARANCE'**
  String get themeSectionTitle;

  /// Profile screen language section header.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get languageSectionTitle;

  /// Language selection · follow device locale.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM'**
  String get languageSystem;

  /// Language selection · English label (always shown in English).
  ///
  /// In en, this message translates to:
  /// **'ENGLISH'**
  String get languageEnglish;

  /// Language selection · Chinese label (always shown in Chinese, intentionally untranslated).
  ///
  /// In en, this message translates to:
  /// **'中 文'**
  String get languageChinese;

  /// Moderation rejection message shown on publish.
  ///
  /// In en, this message translates to:
  /// **'Content contains inappropriate information'**
  String get contentViolation;

  /// Moderation forbidden state.
  ///
  /// In en, this message translates to:
  /// **'Forbidden content'**
  String get moderationForbidden;
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
