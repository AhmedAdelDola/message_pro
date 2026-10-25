import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../logic/settings/settings_cubit.dart';
import '../../../logic/settings/settings_state.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'المظهر والوضع الليلي',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          final cubit = context.read<SettingsCubit>();
          return ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: RadioGroup<ThemeMode>(
                  groupValue: state.themeMode,
                  onChanged: (val) {
                    if (val != null) cubit.setThemeMode(val);
                  },
                  child: Column(
                    children: [
                      RadioListTile<ThemeMode>(
                        value: ThemeMode.system,
                        activeColor: AppColors.primaryLight,
                        title: Text(
                          'تلقائي حسب نظام الجهاز',
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'يتغير المظهر تلقائياً وفقاً لإعدادات الهاتف',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                      const Divider(height: 1),
                      RadioListTile<ThemeMode>(
                        value: ThemeMode.light,
                        activeColor: AppColors.primaryLight,
                        title: Text(
                          'الوضع النهاري (Light Mode)',
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'مظهر فاتح وأنيق',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                      const Divider(height: 1),
                      RadioListTile<ThemeMode>(
                        value: ThemeMode.dark,
                        activeColor: AppColors.primaryLight,
                        title: Text(
                          'الوضع الليلي (Dark Mode)',
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'مريح للعين وموفر لاستهلاك البطارية',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
