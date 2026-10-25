import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/settings_provider.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('اللغة (Language)'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'ar',
                  groupValue: settings.locale.languageCode,
                  activeColor: AppColors.primaryLight,
                  title: const Text('العربية (Arabic)'),
                  subtitle: const Text('واجهة من اليمين إلى اليسار (RTL)'),
                  onChanged: (val) {
                    if (val != null) notifier.setLocale(Locale(val));
                  },
                ),
                const Divider(height: 1),
                RadioListTile<String>(
                  value: 'en',
                  groupValue: settings.locale.languageCode,
                  activeColor: AppColors.primaryLight,
                  title: const Text('English (الإنجليزية)'),
                  subtitle: const Text('Left-to-Right interface (LTR)'),
                  onChanged: (val) {
                    if (val != null) notifier.setLocale(Locale(val));
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
