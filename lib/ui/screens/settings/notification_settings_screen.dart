import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:message_pro/core/constants/app_colors.dart';
import 'package:message_pro/data/models/notification_settings.dart';
import 'package:message_pro/logic/notification/notification_cubit.dart';
import 'package:message_pro/ui/widgets/app_bar_progress_bar.dart';
import 'widgets/notification/push_preset_card.dart';
import 'widgets/notification/push_events_card.dart';
import 'widgets/notification/email_events_card.dart';
import 'widgets/notification/chat_sounds_card.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSaving = false;
  String? _saveFeedback;
  Timer? _feedbackTimer;

  NotificationSettings _settings = const NotificationSettings();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final cubit = context.read<NotificationCubit>();
    await cubit.loadSettings();
    if (mounted) {
      setState(() {
        _settings = cubit.state.settings;
        _isLoading = false;
        _errorMessage = cubit.state.errorMessage;
      });
    }
  }

  Future<void> _saveSettings(NotificationSettings newSettings, {bool isArabic = false}) async {
    setState(() {
      _settings = newSettings;
      _isSaving = true;
    });

    final success = await context.read<NotificationCubit>().saveSettings(newSettings);
    if (!mounted) return;

    setState(() {
      _isSaving = false;
      _saveFeedback = success
          ? (isArabic ? 'تم حفظ التغييرات بنجاح' : 'Changes saved successfully')
          : (isArabic ? 'تم حفظ التغييرات محلياً' : 'Settings saved locally');
    });

    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _saveFeedback = null);
      }
    });
  }

  String _eventTitle(String eventKey, bool isArabic) {
    switch (eventKey) {
      case NotificationSettings.flagConversationCreation:
        return isArabic ? 'إنشاء محادثة جديدة' : 'A new conversation is created';
      case NotificationSettings.flagConversationAssignment:
        return isArabic ? 'تم تعيين محادثة لك' : 'A conversation is assigned to you';
      case NotificationSettings.flagConversationMention:
        return isArabic ? 'تمت الإشارة إليك في محادثة' : 'You are mentioned in a conversation';
      case NotificationSettings.flagAssignedConversationNewMessage:
        return isArabic
            ? 'رسالة جديدة في محادثة معينة لك'
            : 'A new message is created in an assigned conversation';
      case NotificationSettings.flagParticipatingConversationNewMessage:
        return isArabic
            ? 'رسالة جديدة في محادثة تشارك بها'
            : 'A new message is created in a participating conversation';
      default:
        return eventKey;
    }
  }

  String _eventDescription(String eventKey, bool isArabic) {
    switch (eventKey) {
      case NotificationSettings.flagConversationCreation:
        return isArabic
            ? 'تنبيهك عندما يبدأ عميل محادثة جديدة في صندوق الوارد'
            : 'Get alerted when an incoming customer conversation is created';
      case NotificationSettings.flagConversationAssignment:
        return isArabic
            ? 'تنبيهك عندما يقوم زميل أو النظام بتعيين محادثة لك'
            : 'Receive notification when any conversation is assigned to you';
      case NotificationSettings.flagConversationMention:
        return isArabic
            ? 'تنبيهك عندما يقوم زميل بالإشارة إليك @mention في ملاحظة خاصة'
            : 'Notify when you are mentioned in private notes or conversations';
      case NotificationSettings.flagAssignedConversationNewMessage:
        return isArabic
            ? 'تنبيهك عند وصول رسالة جديدة من العميل في محادثتك المعينة'
            : 'Get notified for customer messages in conversations assigned to you';
      case NotificationSettings.flagParticipatingConversationNewMessage:
        return isArabic
            ? 'تنبيهك عند وصول رسالة جديدة في محادثة أرسلت فيها رداً من قبل'
            : 'Receive alerts for conversations where you participated';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isArabic ? 'إعدادات الإشعارات' : 'Notification Settings',
          style: TextStyle(
            color: textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        bottom: AppBarProgressBar(
          isLoading: _isLoading || _isSaving,
          idleBorderColor: borderColor,
          height: 2.5,
        ),
      ),
      body: _isLoading
          ? const SizedBox.shrink()
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFFF382E), size: 48),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _loadSettings,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_saveFeedback != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _saveFeedback!,
                                  style: const TextStyle(
                                    color: Color(0xFF16A34A),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Text(
                        isArabic
                            ? 'اختر تنبيهات الموبايل والبريد الإلكتروني لمساحة العمل هذه. يتم حفظ جميع التغييرات مباشرة على الخادم.'
                            : 'Choose mobile alerts and email preferences for this workspace. Changes are synchronized automatically with the server.',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: textSecondary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isArabic
                            ? 'يرجى التأكد من السماح بالإشعارات للتطبيق في إعدادات نظام هاتفك لتصلك الرسائل في الخلفية.'
                            : 'Ensure notification permissions are granted in your device settings to receive alerts while the app is running in the background.',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary.withValues(alpha: 0.85),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      PushPresetCard(
                        presetValue: _settings.pushPresetMode,
                        onPresetChanged: (val) {
                          if (val != null) {
                            _saveSettings(_settings.applyPushPreset(val), isArabic: isArabic);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      PushEventsCard(
                        settings: _settings,
                        onToggleEvent: (key, enable) {
                          _saveSettings(_settings.togglePushFlag(key, enable), isArabic: isArabic);
                        },
                        eventTitle: _eventTitle,
                        eventDescription: _eventDescription,
                      ),
                      const SizedBox(height: 16),
                      EmailEventsCard(
                        settings: _settings,
                        onToggleEvent: (key, enable) {
                          _saveSettings(_settings.toggleEmailFlag(key, enable), isArabic: isArabic);
                        },
                        eventTitle: _eventTitle,
                        eventDescription: _eventDescription,
                      ),
                      const SizedBox(height: 16),
                      const ChatSoundsCard(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }
}
