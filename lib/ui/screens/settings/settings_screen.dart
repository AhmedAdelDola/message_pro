import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/auth/auth_cubit.dart';
import '../../../logic/auth/auth_state.dart';
import '../../widgets/avatar_widget.dart';
import '../auth/login_screen.dart';
import 'profile_screen.dart';
import 'workspaces_screen.dart';
import 'appearance_screen.dart';
import 'language_screen.dart';
import 'change_password_screen.dart';
import 'notification_settings_screen.dart';
import '../../widgets/break_countdown_banner.dart';
import '../../../logic/settings/settings_cubit.dart';
import '../../../core/services/haptic_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final bgColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFFAFAFA);
    final textPrimary = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF0D0D0D);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF626F7F);
    final borderColor = isDark ? const Color(0xFF212121) : const Color(0xFFF0F0F3);
    final iconBg = isDark ? const Color(0xFF161616) : const Color(0xFFF0F0F3);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            final user = authState is Authenticated ? authState.user : null;
            final availability = user?.availabilityStatus ?? 'online';
            Color statusColor;
            String statusLabel;
            switch (availability.toLowerCase()) {
              case 'busy':
                statusColor = const Color(0xFFFA8900);
                statusLabel = isArabic ? 'مشغول (Busy)' : 'Busy';
                break;
              case 'on_break':
              case 'on break':
              case 'break':
                statusColor = const Color(0xFF6B5DE8);
                statusLabel = isArabic ? 'استراحة (On break)' : 'On break';
                break;
              case 'offline':
                statusColor = const Color(0xFF80838D);
                statusLabel = isArabic ? 'غير متصل (Offline)' : 'Offline';
                break;
              case 'online':
              default:
                statusColor = const Color(0xFF2CA54A);
                statusLabel = isArabic ? 'متصل (Online)' : 'Online';
                break;
            }
            final accounts = user?.accounts ?? [];
            final matchingAccount = accounts.where((a) => a.id == user?.accountId);
            final activeAccountName = matchingAccount.isNotEmpty
                ? matchingAccount.first.name
                : (accounts.isNotEmpty
                    ? accounts.first.name
                    : (isArabic ? 'مساحة العمل الخاصة بي' : 'My Workspace'));

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // Header Title
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: Text(
                    isArabic ? 'الإعدادات' : 'Settings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                      fontFamily: 'Gontserrat',
                    ),
                  ),
                ),
                const BreakCountdownBanner(),

                // User Profile Row
                if (user != null)
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                      ),
                      child: Row(
                        children: [
                          // 52x52 Avatar with status ring
                          Container(
                            width: 52,
                            height: 52,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: statusColor,
                                width: 2,
                              ),
                            ),
                            child: AvatarWidget(
                              avatarUrl: user.avatarUrl,
                              name: user.name,
                              size: 44,
                              showStatus: true,
                              availabilityStatus: availability,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                    fontFamily: 'Gontserrat',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user.email,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textSecondary,
                                    fontFamily: 'Gontserrat',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isArabic ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                            color: const Color(0xFF80838D),
                          ),
                        ],
                      ),
                    ),
                  ),

                // SECTION: GENERAL
                _buildSectionHeader(isArabic ? 'عام' : 'GENERAL'),

                // Set Availability
                _buildSettingsRow(
                  icon: Icon(Icons.person_outline_rounded, color: textSecondary, size: 20),
                  iconBg: iconBg,
                  borderColor: borderColor,
                  title: isArabic ? 'تحديد الحالة:' : 'Set availability:',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                          fontFamily: 'Gontserrat',
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _showAvailabilityPicker(context, availability, isArabic),
                ),

                // SECTION: ACCOUNT
                _buildSectionHeader(isArabic ? 'الحساب' : 'ACCOUNT'),

                _buildSettingsRow(
                  icon: Icon(Icons.domain_rounded, color: textSecondary, size: 20),
                  iconBg: iconBg,
                  borderColor: borderColor,
                  title: isArabic ? 'تغيير مساحة العمل' : 'Change Workspace',
                  subtitle: activeAccountName,
                  trailing: Icon(
                    isArabic ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                    color: const Color(0xFF80838D),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const WorkspacesScreen()),
                    );
                  },
                ),

                _buildSettingsRow(
                  icon: Icon(Icons.lock_outline_rounded, color: textSecondary, size: 20),
                  iconBg: iconBg,
                  borderColor: borderColor,
                  title: isArabic ? 'تغيير كلمة المرور' : 'Change Password',
                  trailing: Icon(
                    isArabic ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                    color: const Color(0xFF80838D),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                    );
                  },
                ),

                // SECTION: PREFERENCES
                _buildSectionHeader(isArabic ? 'التفضيلات' : 'PREFERENCES'),

                _buildSettingsRow(
                  icon: Icon(Icons.language_rounded, color: textSecondary, size: 20),
                  iconBg: iconBg,
                  borderColor: borderColor,
                  title: isArabic ? 'اللغة' : 'Language',
                  subtitle: isArabic ? 'العربية (Arabic)' : 'English',
                  trailing: Icon(
                    isArabic ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                    color: const Color(0xFF80838D),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LanguageScreen()),
                    );
                  },
                ),

                _buildSettingsRow(
                  icon: Icon(Icons.dark_mode_outlined, color: textSecondary, size: 20),
                  iconBg: iconBg,
                  borderColor: borderColor,
                  title: isArabic ? 'المظهر' : 'Theme',
                  subtitle: isDark ? 'Dark' : 'Light',
                  trailing: Icon(
                    isArabic ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                    color: const Color(0xFF80838D),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AppearanceScreen()),
                    );
                  },
                ),

                _buildSettingsRow(
                  icon: Icon(Icons.notifications_outlined, color: textSecondary, size: 20),
                  iconBg: iconBg,
                  borderColor: borderColor,
                  title: isArabic ? 'إعدادات الإشعارات' : 'Notification Settings',
                  trailing: Icon(
                    isArabic ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                    color: const Color(0xFF80838D),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                    );
                  },
                ),

                Builder(
                  builder: (context) {
                    SettingsCubit? cubit;
                    try {
                      cubit = context.watch<SettingsCubit>();
                    } catch (_) {}
                    final hapticEnabled = cubit?.state.hapticEnabled ?? HapticService.isEnabled;
                    return _buildSettingsRow(
                      icon: Icon(Icons.vibration_rounded, color: textSecondary, size: 20),
                      iconBg: iconBg,
                      borderColor: borderColor,
                      title: isArabic ? 'الاهتزاز والتفاعل اللمسي' : 'Haptic Feedback',
                      trailing: Switch(
                        value: hapticEnabled,
                        activeThumbColor: const Color(0xFF4162E3),
                        onChanged: (val) {
                          if (cubit != null) {
                            cubit.setHapticEnabled(val);
                          } else {
                            HapticService.setEnabled(val);
                            setState(() {});
                          }
                        },
                      ),
                      onTap: () {
                        final next = !hapticEnabled;
                        if (cubit != null) {
                          cubit.setHapticEnabled(next);
                        } else {
                          HapticService.setEnabled(next);
                          setState(() {});
                        }
                      },
                    );
                  },
                ),

                // LOGOUT
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => _confirmLogout(context, isArabic),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF382E).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.logout_rounded, color: Color(0xFFFF382E), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isArabic ? 'تسجيل الخروج' : 'Log Out',
                          style: const TextStyle(
                            color: Color(0xFFFF382E),
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            fontFamily: 'Gontserrat',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Version Footer
                Padding(
                  padding: const EdgeInsets.only(top: 32, bottom: 24),
                  child: Center(
                    child: Text(
                      'Version 3.3.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                        fontFamily: 'Gontserrat',
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF80838D),
          letterSpacing: 1.0,
          fontFamily: 'Gontserrat',
        ),
      ),
    );
  }

  Widget _buildSettingsRow({
    required Widget icon,
    required Color iconBg,
    required Color borderColor,
    required String title,
    String? subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF0D0D0D);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF626F7F);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: borderColor, width: 1)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: icon,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gontserrat',
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 13,
                        fontFamily: 'Gontserrat',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  void _showAvailabilityPicker(BuildContext context, String currentStatus, bool isArabic) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF161616) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF0D0D0D);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB);

    final statuses = [
      {
        'key': 'online',
        'label': isArabic ? 'متصل (Online)' : 'Online',
        'desc': isArabic ? 'متاح لاستقبال المحادثات الجديدة' : 'Available for new conversations',
        'color': const Color(0xFF2CA54A),
      },
      {
        'key': 'busy',
        'label': isArabic ? 'مشغول (Busy)' : 'Busy',
        'desc': isArabic ? 'غير متاح حالياً لاستقبال محادثات جديدة' : 'Currently not taking new conversations',
        'color': const Color(0xFFFA8900),
      },
      {
        'key': 'on_break',
        'label': isArabic ? 'استراحة (On break)' : 'On break',
        'desc': isArabic ? 'في استراحة مؤقتة عن استقبال المحادثات' : 'Taking a temporary break',
        'color': const Color(0xFF6B5DE8),
      },
      {
        'key': 'offline',
        'label': isArabic ? 'غير متصل (Offline)' : 'Offline',
        'desc': isArabic ? 'تسجيل الخروج من التواجد' : 'Not available to handle chats',
        'color': const Color(0xFF80838D),
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Text(
                  isArabic ? 'تحديد حالة التواجد' : 'Set Availability',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                    fontFamily: 'Gontserrat',
                  ),
                ),
                const SizedBox(height: 16),
                for (final item in statuses) ...[
                  InkWell(
                    onTap: () async {
                      Navigator.pop(sheetCtx);
                      final key = item['key'] as String;
                      if (key == 'on_break' || key == 'break') {
                        final duration = await BreakDurationSheet.show(context);
                        if (duration != null && context.mounted) {
                          context.read<AuthCubit>().updateAvailability('break', breakDurationMinutes: duration);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isArabic ? 'بدأت الاستراحة لمدة $duration دقيقة' : 'Break started for $duration minutes',
                                style: const TextStyle(fontFamily: 'Gontserrat'),
                              ),
                              duration: const Duration(seconds: 2),
                              backgroundColor: const Color(0xFF6B5DE8),
                            ),
                          );
                        }
                      } else {
                        context.read<AuthCubit>().updateAvailability(key);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isArabic
                                  ? 'تم تغيير الحالة إلى: ${item['label']}'
                                  : 'Status updated to: ${item['label']}',
                              style: const TextStyle(fontFamily: 'Gontserrat'),
                            ),
                            duration: const Duration(seconds: 2),
                            backgroundColor: const Color(0xFF1E2024),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: currentStatus == item['key']
                            ? (isDark ? const Color(0xFF1E222A) : const Color(0xFFF1F5F9))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: currentStatus == item['key']
                              ? (item['color'] as Color)
                              : borderColor,
                          width: currentStatus == item['key'] ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: item['color'] as Color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['label'] as String,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                    fontFamily: 'Gontserrat',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['desc'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                    fontFamily: 'Gontserrat',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (currentStatus == item['key'])
                            Icon(Icons.check_circle_rounded, color: item['color'] as Color, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmLogout(BuildContext context, bool isArabic) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isArabic ? 'تسجيل الخروج' : 'Log Out', style: const TextStyle(fontFamily: 'Gontserrat')),
        content: Text(
          isArabic ? 'هل أنت متأكد أنك تريد تسجيل الخروج؟' : 'Are you sure you want to log out?',
          style: const TextStyle(fontFamily: 'Gontserrat'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthCubit>().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: Text(
              isArabic ? 'تسجيل الخروج' : 'Log Out',
              style: const TextStyle(color: Color(0xFFFF382E), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
