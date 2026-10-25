import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/config/app_config.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/shorebird_provider.dart';
import '../../widgets/avatar_widget.dart';
import '../auth/login_screen.dart';
import 'profile_screen.dart';
import 'workspaces_screen.dart';
import 'appearance_screen.dart';
import 'language_screen.dart';
import 'change_password_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final shorebirdState = ref.watch(shorebirdProvider);
    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات (Settings)'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // User Card
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      AvatarWidget(
                        avatarUrl: user.avatarUrl,
                        name: user.name,
                        size: 54,
                        isOnline: user.availabilityStatus == 'online',
                        showStatus: true,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.email,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                user.role.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Availability Selector
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.circle, color: AppColors.success, size: 16),
                      title: const Text('متصل (Online)'),
                      trailing: user.availabilityStatus == 'online'
                          ? const Icon(Icons.check, color: AppColors.success)
                          : null,
                      onTap: () => ref.read(authProvider.notifier).updateAvailability('online'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.circle, color: AppColors.warning, size: 16),
                      title: const Text('مشغول (Busy)'),
                      trailing: user.availabilityStatus == 'busy'
                          ? const Icon(Icons.check, color: AppColors.warning)
                          : null,
                      onTap: () => ref.read(authProvider.notifier).updateAvailability('busy'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.circle, color: Colors.grey, size: 16),
                      title: const Text('غير متصل (Offline)'),
                      trailing: user.availabilityStatus == 'offline'
                          ? const Icon(Icons.check, color: Colors.grey)
                          : null,
                      onTap: () => ref.read(authProvider.notifier).updateAvailability('offline'),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),
          // General Settings
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline_rounded),
                    title: const Text('الملف الشخصي (Profile)'),
                    trailing: const Icon(Icons.chevron_left_rounded),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.business_rounded),
                    title: const Text('مساحات العمل (Workspaces)'),
                    subtitle: Text('${user?.accounts.length ?? 0} مساحة عمل مسجلة'),
                    trailing: const Icon(Icons.chevron_left_rounded),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const WorkspacesScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.dark_mode_outlined),
                    title: const Text('المظهر والوضع الليلي (Appearance)'),
                    trailing: const Icon(Icons.chevron_left_rounded),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AppearanceScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.translate_rounded),
                    title: const Text('اللغة (Language)'),
                    trailing: const Icon(Icons.chevron_left_rounded),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LanguageScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.lock_reset_rounded),
                    title: const Text('تغيير كلمة المرور'),
                    trailing: const Icon(Icons.chevron_left_rounded),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          // Shorebird Code Push Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.system_update_rounded, color: AppColors.primaryLight),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'تحديثات Shorebird المباشرة (Code Push)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        if (shorebirdState.status == ShorebirdStatus.checking ||
                            shorebirdState.status == ShorebirdStatus.updating)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      shorebirdState.currentPatch != null
                          ? 'الترقيعة الحالية: #${shorebirdState.currentPatch}'
                          : 'إصدار التطبيق الأساسي: v${AppConfig.appVersion}',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('التحقق من وجود تحديث الآن'),
                      onPressed: () => ref.read(shorebirdProvider.notifier).checkForUpdate(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),
          // Sign Out Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.danger.withValues(alpha: 0.3)),
              ),
              tileColor: AppColors.danger.withValues(alpha: 0.08),
              leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
              title: const Text(
                'تسجيل الخروج (Sign Out)',
                style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('تسجيل الخروج'),
                    content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج من Message Pro؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('إلغاء'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await ref.read(authProvider.notifier).logout();
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                          }
                        },
                        child: const Text('خروج', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
