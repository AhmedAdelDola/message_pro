import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/settings_provider.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المظهر والوضع الليلي'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  groupValue: settings.themeMode,
                  activeColor: AppColors.primaryLight,
                  title: const Text('تلقائي حسب نظام الجهاز'),
                  subtitle: const Text('يتغير المظهر تلقائياً وفقاً لإعدادات الهاتف'),
                  onChanged: (val) {
                    if (val != null) notifier.setThemeMode(val);
                  },
                ),
                const Divider(height: 1),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: settings.themeMode,
                  activeColor: AppColors.primaryLight,
                  title: const Text('الوضع النهاري (Light Mode)'),
                  subtitle: const Text('مظهر فاتح وأنيق'),
                  onChanged: (val) {
                    if (val != null) notifier.setThemeMode(val);
                  },
                ),
                const Divider(height: 1),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: settings.themeMode,
                  activeColor: AppColors.primaryLight,
                  title: const Text('الوضع الليلي (Dark Mode)'),
                  subtitle: const Text('مريح للعين وموفر لاستهلاك البطارية'),
                  onChanged: (val) {
                    if (val != null) notifier.setThemeMode(val);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
