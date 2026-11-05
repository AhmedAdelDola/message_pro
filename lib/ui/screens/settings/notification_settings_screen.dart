import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection_container.dart';
import '../../../data/models/notification_settings.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../core/services/sound_service.dart';
import '../../widgets/app_bar_progress_bar.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final INotificationRepository _repo = sl<INotificationRepository>();

  bool _isLoading = true;
  String? _errorMessage;
  bool _isSaving = false;
  String? _saveFeedback;
  Timer? _feedbackTimer;

  NotificationSettings _settings = const NotificationSettings();
  bool _isAdvancedExpanded = true;
  bool _isEmailExpanded = false;

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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _repo.getNotificationSettings();

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.message;
        });
      },
      (data) {
        setState(() {
          _settings = data;
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _saveSettings(NotificationSettings newSettings, {bool isArabic = false}) async {
    setState(() {
      _settings = newSettings;
      _isSaving = true;
    });

    final result = await _repo.updateNotificationSettings(newSettings);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isSaving = false;
          _saveFeedback = isArabic ? 'تم حفظ التغييرات محلياً' : 'Settings saved locally';
        });
        _feedbackTimer?.cancel();
        _feedbackTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _saveFeedback = null);
          }
        });
      },
      (saved) {
        setState(() {
          _settings = saved;
          _isSaving = false;
          _saveFeedback = isArabic ? 'تم حفظ التغييرات بنجاح' : 'Changes saved successfully';
        });

        _feedbackTimer?.cancel();
        _feedbackTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _saveFeedback = null);
          }
        });
      },
    );
  }

  void _onPresetChanged(String? val, bool isArabic) {
    if (val == null) return;
    final updated = _settings.applyPushPreset(val);
    _saveSettings(updated, isArabic: isArabic);
  }

  void _togglePushEvent(String eventKey, bool enable, bool isArabic) {
    final updated = _settings.togglePushFlag(eventKey, enable);
    _saveSettings(updated, isArabic: isArabic);
  }

  void _toggleEmailEvent(String eventKey, bool enable, bool isArabic) {
    final updated = _settings.toggleEmailFlag(eventKey, enable);
    _saveSettings(updated, isArabic: isArabic);
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
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;

    final presetValue = _settings.pushPresetMode;

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
            fontFamily: 'Gontserrat',
          ),
        ),
        centerTitle: false,
        actions: [
          if (_isSaving)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
            ),
        ],
        bottom: AppBarProgressBar(
          isLoading: _isLoading || _isSaving,
          idleBorderColor: borderColor,
          height: 2.5,
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
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
                            fontFamily: 'Gontserrat',
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
                      // Save feedback banner
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
                                    fontFamily: 'Gontserrat',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Informational description texts
                      Text(
                        isArabic
                            ? 'اختر تنبيهات الموبايل والبريد الإلكتروني لمساحة العمل هذه. يتم حفظ جميع التغييرات مباشرة على الخادم.'
                            : 'Choose mobile alerts and email preferences for this workspace. Changes are synchronized automatically with the server.',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: textSecondary,
                          height: 1.45,
                          fontFamily: 'Gontserrat',
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
                          fontFamily: 'Gontserrat',
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Card 1: Mobile push preset selector
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.notifications_active_outlined, color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  isArabic ? 'إشعارات الموبايل المباشرة (Push)' : 'Mobile push notifications',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                    fontFamily: 'Gontserrat',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: borderColor),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: presetValue,
                                  isExpanded: true,
                                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: textSecondary),
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Gontserrat',
                                  ),
                                  dropdownColor: cardBg,
                                  onChanged: (val) => _onPresetChanged(val, isArabic),
                                  items: [
                                    DropdownMenuItem(
                                      value: 'All conversations',
                                      child: Text(isArabic ? 'كل المحادثات' : 'All conversations'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Assigned only',
                                      child: Text(isArabic ? 'المحادثات المعينة لي فقط' : 'Assigned only'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Custom selection',
                                      child: Text(isArabic ? 'تحديد مخصص' : 'Custom selection'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'None',
                                      child: Text(isArabic ? 'إيقاف الإشعارات' : 'None'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              isArabic
                                  ? 'تتحكم هذه القائمة في أحداث التنبيهات لأجهزتك المحمولة المسجلة لدى الخادم.'
                                  : 'Controls notification events dispatched to your registered mobile devices.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: textSecondary,
                                height: 1.4,
                                fontFamily: 'Gontserrat',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Card 2: Advanced Push notification events
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () => setState(() => _isAdvancedExpanded = !_isAdvancedExpanded),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isArabic ? 'تخصيص أحداث الموبايل' : 'Mobile Alert Events',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: textPrimary,
                                              fontFamily: 'Gontserrat',
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            isArabic
                                                ? 'حدد الأحداث التي تود تلقي إشعار فوري بها على هاتفك.'
                                                : 'Select exactly which events trigger a push alert.',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: textSecondary,
                                              fontFamily: 'Gontserrat',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      _isAdvancedExpanded
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      color: textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            if (_isAdvancedExpanded) ...[
                              Divider(color: borderColor, height: 1),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Column(
                                  children: NotificationSettings.allEvents.map((eventKey) {
                                    final isEnabled = _settings.hasPushFlag(eventKey);
                                    return SwitchListTile.adaptive(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      activeTrackColor: AppColors.primary,
                                      activeThumbColor: Colors.white,
                                      title: Text(
                                        _eventTitle(eventKey, isArabic),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: textPrimary,
                                          fontFamily: 'Gontserrat',
                                        ),
                                      ),
                                      subtitle: Text(
                                        _eventDescription(eventKey, isArabic),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: textSecondary,
                                          fontFamily: 'Gontserrat',
                                        ),
                                      ),
                                      value: isEnabled,
                                      onChanged: (val) => _togglePushEvent(eventKey, val, isArabic),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Card 3: Email notification settings
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () => setState(() => _isEmailExpanded = !_isEmailExpanded),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    const Icon(Icons.email_outlined, color: AppColors.primary, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isArabic ? 'إشعارات البريد الإلكتروني' : 'Email Notifications',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: textPrimary,
                                              fontFamily: 'Gontserrat',
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            isArabic
                                                ? 'تحديد الرسائل والأنشطة المرسلة إلى بريدك المسجل.'
                                                : 'Choose which activity updates are sent to your inbox.',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: textSecondary,
                                              fontFamily: 'Gontserrat',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      _isEmailExpanded
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      color: textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            if (_isEmailExpanded) ...[
                              Divider(color: borderColor, height: 1),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Column(
                                  children: NotificationSettings.allEvents.map((eventKey) {
                                    final isEnabled = _settings.hasEmailFlag(eventKey);
                                    return SwitchListTile.adaptive(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      activeTrackColor: AppColors.primary,
                                      activeThumbColor: Colors.white,
                                      title: Text(
                                        _eventTitle(eventKey, isArabic),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: textPrimary,
                                          fontFamily: 'Gontserrat',
                                        ),
                                      ),
                                      subtitle: Text(
                                        _eventDescription(eventKey, isArabic),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: textSecondary,
                                          fontFamily: 'Gontserrat',
                                        ),
                                      ),
                                      value: isEnabled,
                                      onChanged: (val) => _toggleEmailEvent(eventKey, val, isArabic),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Card 4: In-App Chat Sounds (WhatsApp chime & sent pop)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  isArabic ? 'أصوات المحادثات المباشرة' : 'In-App Chat Sounds',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                    fontFamily: 'Gontserrat',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              activeTrackColor: AppColors.primary,
                              activeThumbColor: Colors.white,
                              title: Text(
                                isArabic ? 'نغمات الرسائل الواردة والمرسلة' : 'Message Sent & Received Tones',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                  fontFamily: 'Gontserrat',
                                ),
                              ),
                              subtitle: Text(
                                isArabic
                                    ? 'تشغيل نغمة واتساب المميزة عند استقبال أو إرسال أي رسالة داخل التطبيق.'
                                    : 'Play WhatsApp sound effects for incoming and outgoing messages while using the app.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: textSecondary,
                                  fontFamily: 'Gontserrat',
                                ),
                              ),
                              value: SoundService().isSoundEnabled,
                              onChanged: (val) async {
                                await SoundService().setSoundEnabled(val);
                                setState(() {});
                                if (val) {
                                  SoundService().playIncomingSound();
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }
}
