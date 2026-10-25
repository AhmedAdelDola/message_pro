import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../logic/settings/settings_cubit.dart';
import '../../../logic/settings/settings_state.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'اللغة (Language)',
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
                child: RadioGroup<String>(
                  groupValue: state.locale.languageCode,
                  onChanged: (val) {
                    if (val != null) cubit.setLocale(Locale(val));
                  },
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        value: 'ar',
                        activeColor: AppColors.primaryLight,
                        title: Text(
                          'العربية (Arabic)',
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'واجهة من اليمين إلى اليسار (RTL)',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                      const Divider(height: 1),
                      RadioListTile<String>(
                        value: 'en',
                        activeColor: AppColors.primaryLight,
                        title: Text(
                          'English (الإنجليزية)',
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Left-to-Right interface (LTR)',
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
