import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:message_pro/logic/auth/auth_cubit.dart';
import 'package:message_pro/logic/auth/auth_state.dart';
import 'package:message_pro/logic/settings/settings_cubit.dart';
import 'package:message_pro/core/services/haptic_service.dart';
import 'package:message_pro/ui/widgets/break_countdown_banner.dart';
import 'profile_screen.dart';
import 'workspaces_screen.dart';
import 'appearance_screen.dart';
import 'language_screen.dart';
import 'change_password_screen.dart';
import 'notification_settings_screen.dart';
import 'widgets/settings_row.dart';
import 'widgets/settings_user_profile_tile.dart';
import 'widgets/availability_picker_modal.dart';
import 'widgets/logout_confirm_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
                    ),
                  ),
                ),
                const BreakCountdownBanner(),

                // User Profile Row
                if (user != null)
                  SettingsUserProfileTile(
                    user: user,
                    statusColor: statusColor,
                    borderColor: borderColor,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    },
                  ),

                // SECTION: GENERAL
                _buildSectionHeader(isArabic ? 'عام' : 'GENERAL'),

                // Set Availability
                SettingsRow(
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
                        ),
                      ),
                    ],
                  ),
                  onTap: () => AvailabilityPickerModal.show(context, availability, isArabic),
                ),

                // SECTION: ACCOUNT
                _buildSectionHeader(isArabic ? 'الحساب' : 'ACCOUNT'),

                SettingsRow(
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

                SettingsRow(
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

                SettingsRow(
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

                SettingsRow(
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

                SettingsRow(
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
                    return SettingsRow(
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
                          }
                        },
                      ),
                      onTap: () {
                        final next = !hapticEnabled;
                        if (cubit != null) {
                          cubit.setHapticEnabled(next);
                        } else {
                          HapticService.setEnabled(next);
                        }
                      },
                    );
                  },
                ),

                // LOGOUT
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => LogoutConfirmDialog.show(context, isArabic),
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
        ),
      ),
    );
  }
}
