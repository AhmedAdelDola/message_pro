import 'package:flutter/widgets.dart';
import 'translations_ar.dart';
import 'translations_en.dart';

/// AppLocalizations provides strongly-typed, centralized translations for Message Pro.
/// Accessible via `AppLocalizations.of(context)` or `context.l10n`.
class AppLocalizations {
  final Locale locale;
  final Map<String, String> _localizedStrings;

  AppLocalizations(this.locale)
      : _localizedStrings = locale.languageCode == 'ar'
            ? TranslationsAr.values
            : TranslationsEn.values;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('ar'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isArabic => locale.languageCode == 'ar';

  /// General lookup by string key with optional fallback.
  String translate(String key, {String? defaultVal}) {
    return _localizedStrings[key] ?? defaultVal ?? key;
  }

  // --- Auth & Onboarding ---
  String get appTitle => translate('app_title');
  String get loginTitle => translate('login_title');
  String get email => translate('email');
  String get emailHint => translate('email_hint');
  String get emailRequired => translate('email_required');
  String get emailInvalid => translate('email_invalid');
  String get password => translate('password');
  String get passwordRequired => translate('password_required');
  String get forgotPassword => translate('forgot_password');
  String get login => translate('login');
  String get loggingIn => translate('logging_in');
  String get or => translate('or');
  String get googleSignIn => translate('google_sign_in');
  String get switchLanguage => translate('switch_language');
  String get preparingWorkspace => translate('preparing_workspace');

  // --- General Navigation & Tabs ---
  String get inbox => translate('inbox');
  String get contacts => translate('contacts');
  String get settings => translate('settings');
  String get calls => translate('calls');
  String get search => translate('search');
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get confirm => translate('confirm');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get close => translate('close');
  String get done => translate('done');
  String get retry => translate('retry');
  String get loading => translate('loading');
  String get noResults => translate('no_results');

  // --- Inbox & Conversations ---
  String get all => translate('all');
  String get mine => translate('mine');
  String get unassigned => translate('unassigned');
  String get collaborating => translate('collaborating');
  String get open => translate('open');
  String get closed => translate('closed');
  String get snoozed => translate('snoozed');
  String get newest => translate('newest');
  String get oldest => translate('oldest');
  String get unreplied => translate('unreplied');
  String get searchConversationsHint => translate('search_conversations_hint');
  String get noConversationsFound => translate('no_conversations_found');
  String get noConversationsSubtitle => translate('no_conversations_subtitle');
  String get pinConversation => translate('pin_conversation');
  String get unpinConversation => translate('unpin_conversation');
  String get markAsResolved => translate('mark_as_resolved');
  String get reopenConversation => translate('reopen_conversation');
  String get muteConversation => translate('mute_conversation');
  String get unmuteConversation => translate('unmute_conversation');
  String get assignAgent => translate('assign_agent');
  String get assignTeam => translate('assign_team');
  String get labels => translate('labels');
  String get lifecycleStage => translate('lifecycle_stage');
  String get copyLink => translate('copy_link');
  String get conversationLinkCopied => translate('conversation_link_copied');

  // --- Chat Screen ---
  String get typeMessageHint => translate('type_message_hint');
  String get send => translate('send');
  String get reply => translate('reply');
  String get privateNote => translate('private_note');
  String get sendAsPrivateNote => translate('send_as_private_note');
  String get audioRecording => translate('audio_recording');
  String get slideToCancel => translate('slide_to_cancel');
  String get releaseToSend => translate('release_to_send');
  String get photo => translate('photo');
  String get document => translate('document');
  String get camera => translate('camera');
  String get cannedResponses => translate('canned_responses');
  String get conversationResolvedSuccess => translate('conversation_resolved_success');
  String get conversationReopenedSuccess => translate('conversation_reopened_success');
  String get updateStatusFailed => translate('update_status_failed');
  String get conversationMutedSuccess => translate('conversation_muted_success');
  String get conversationUnmutedSuccess => translate('conversation_unmuted_success');
  String get aiAgentTakeover => translate('ai_agent_takeover');
  String get takeOverFromAi => translate('take_over_from_ai');
  String get returnToAi => translate('return_to_ai');

  // --- Settings & Profile ---
  String get preferences => translate('preferences');
  String get language => translate('language');
  String get languageName => translate('language_name');
  String get theme => translate('theme');
  String get themeLight => translate('theme_light');
  String get themeDark => translate('theme_dark');
  String get themeSystem => translate('theme_system');
  String get notificationSettings => translate('notification_settings');
  String get hapticFeedback => translate('haptic_feedback');
  String get workspaces => translate('workspaces');
  String get activeWorkspace => translate('active_workspace');
  String get switchWorkspace => translate('switch_workspace');
  String get logout => translate('logout');
  String get logoutConfirmTitle => translate('logout_confirm_title');
  String get logoutConfirmDesc => translate('logout_confirm_desc');
  String get profile => translate('profile');
  String get status => translate('status');
  String get online => translate('online');
  String get busy => translate('busy');
  String get offline => translate('offline');
  String get onBreak => translate('on_break');
  String get startBreak => translate('start_break');
  String get endBreak => translate('end_break');
  String get breakDurationPrompt => translate('break_duration_prompt');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
