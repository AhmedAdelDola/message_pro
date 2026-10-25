import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/config/app_config.dart';
import '../../../logic/auth/auth_cubit.dart';
import '../../../logic/auth/auth_state.dart';
import '../../../logic/shorebird/shorebird_cubit.dart';
import '../../../logic/shorebird/shorebird_state.dart';
import '../../widgets/avatar_widget.dart';
import '../auth/login_screen.dart';
import 'profile_screen.dart';
import 'workspaces_screen.dart';
import 'appearance_screen.dart';
import 'language_screen.dart';
import 'change_password_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات (Settings)'),
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final user = authState is Authenticated ? authState.user : null;

          return ListView(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            children: [
              // User Card
              if (user != null)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0.r),
                      child: Row(
                        children: [
                          AvatarWidget(
                            avatarUrl: user.avatarUrl,
                            name: user.name,
                            size: 54,
                            isOnline: user.availabilityStatus == 'online',
                            showStatus: true,
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  user.email,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    user.role.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10.sp,
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
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                  child: Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.circle, color: AppColors.success, size: 16.r),
                          title: Text('متصل (Online)', style: TextStyle(fontSize: 14.sp)),
                          trailing: user.availabilityStatus == 'online'
                              ? const Icon(Icons.check, color: AppColors.success)
                              : null,
                          onTap: () => context.read<AuthCubit>().updateAvailability('online'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.circle, color: AppColors.warning, size: 16.r),
                          title: Text('مشغول (Busy)', style: TextStyle(fontSize: 14.sp)),
                          trailing: user.availabilityStatus == 'busy'
                              ? const Icon(Icons.check, color: AppColors.warning)
                              : null,
                          onTap: () => context.read<AuthCubit>().updateAvailability('busy'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.circle, color: Colors.grey, size: 16.r),
                          title: Text('غير متصل (Offline)', style: TextStyle(fontSize: 14.sp)),
                          trailing: user.availabilityStatus == 'offline'
                              ? const Icon(Icons.check, color: Colors.grey)
                              : null,
                          onTap: () => context.read<AuthCubit>().updateAvailability('offline'),
                        ),
                      ],
                    ),
                  ),
                ),

              SizedBox(height: 12.h),
              // General Settings
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.person_outline_rounded, size: 22.r),
                        title: Text('الملف الشخصي (Profile)', style: TextStyle(fontSize: 14.sp)),
                        trailing: Icon(Icons.chevron_left_rounded, size: 22.r),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ProfileScreen()),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.business_rounded, size: 22.r),
                        title: Text('مساحات العمل (Workspaces)', style: TextStyle(fontSize: 14.sp)),
                        subtitle: Text('${user?.accounts.length ?? 0} مساحة عمل مسجلة', style: TextStyle(fontSize: 12.sp)),
                        trailing: Icon(Icons.chevron_left_rounded, size: 22.r),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const WorkspacesScreen()),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.dark_mode_outlined, size: 22.r),
                        title: Text('المظهر والوضع الليلي (Appearance)', style: TextStyle(fontSize: 14.sp)),
                        trailing: Icon(Icons.chevron_left_rounded, size: 22.r),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AppearanceScreen()),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.translate_rounded, size: 22.r),
                        title: Text('اللغة (Language)', style: TextStyle(fontSize: 14.sp)),
                        trailing: Icon(Icons.chevron_left_rounded, size: 22.r),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LanguageScreen()),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.lock_reset_rounded, size: 22.r),
                        title: Text('تغيير كلمة المرور', style: TextStyle(fontSize: 14.sp)),
                        trailing: Icon(Icons.chevron_left_rounded, size: 22.r),
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

              SizedBox(height: 12.h),
              // Shorebird Code Push Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0.r),
                    child: BlocBuilder<ShorebirdCubit, ShorebirdState>(
                      builder: (context, shorebirdState) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.system_update_rounded, color: AppColors.primaryLight, size: 22.r),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Text(
                                    'تحديثات Shorebird المباشرة (Code Push)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                                  ),
                                ),
                                if (shorebirdState.status == ShorebirdStatus.checking ||
                                    shorebirdState.status == ShorebirdStatus.updating)
                                  SizedBox(
                                    width: 16.r,
                                    height: 16.r,
                                    child: const CircularProgressIndicator(strokeWidth: 2),
                                  ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              shorebirdState.currentPatch != null
                                  ? 'الترقيعة الحالية: #${shorebirdState.currentPatch}'
                                  : 'إصدار التطبيق الأساسي: v${AppConfig.appVersion}',
                              style: TextStyle(fontSize: 12.sp, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                            ),
                            SizedBox(height: 10.h),
                            OutlinedButton.icon(
                              icon: Icon(Icons.refresh_rounded, size: 16.r),
                              label: Text('التحقق من وجود تحديث الآن', style: TextStyle(fontSize: 12.sp)),
                              onPressed: () => context.read<ShorebirdCubit>().checkForUpdate(),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),

              SizedBox(height: 12.h),
              // Sign Out Button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    side: BorderSide(color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  tileColor: AppColors.danger.withValues(alpha: 0.08),
                  leading: Icon(Icons.logout_rounded, color: AppColors.danger, size: 22.r),
                  title: Text(
                    'تسجيل الخروج (Sign Out)',
                    style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 14.sp),
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
                              await context.read<AuthCubit>().logout();
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
              SizedBox(height: 24.h),
            ],
          );
        },
      ),
    );
  }
}
