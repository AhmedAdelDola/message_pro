import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../logic/auth/auth_cubit.dart';
import '../../logic/auth/auth_state.dart';

class BreakDurationSheet extends StatefulWidget {
  const BreakDurationSheet({super.key});

  static Future<int?> show(BuildContext context) {
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const BreakDurationSheet(),
    );
  }

  @override
  State<BreakDurationSheet> createState() => _BreakDurationSheetState();
}

class _BreakDurationSheetState extends State<BreakDurationSheet> {
  int _selectedMinutes = 15;
  final List<int> _quickDurations = [15, 30, 45, 60];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final cardBg = isDark ? const Color(0xFF161616) : Colors.white;
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    const breakColor = Color(0xFF6B5DE8);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF333333) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: breakColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.coffee_rounded, color: breakColor, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'بدء فترة استراحة (On break)' : 'Start Break (On break)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                        fontFamily: 'Gontserrat',
                      ),
                    ),
                    Text(
                      isArabic ? 'اختر مدة الاستراحة بالدقائق (1 إلى 120 دقيقة)' : 'Choose break duration (1 to 120 mins)',
                      style: TextStyle(fontSize: 12, color: textSecondary, fontFamily: 'Gontserrat'),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Quick selection chips
          Row(
            children: _quickDurations.map((mins) {
              final isSelected = _selectedMinutes == mins;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => setState(() => _selectedMinutes = mins),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? breakColor.withValues(alpha: 0.15) : (isDark ? const Color(0xFF202226) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? breakColor : borderColor,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isArabic ? '$mins د' : '$mins m',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? breakColor : textPrimary,
                          fontFamily: 'Gontserrat',
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 18),

          // Slider for custom minute selection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'المدة المحددة:' : 'Selected Duration:',
                style: TextStyle(fontSize: 13, color: textSecondary, fontFamily: 'Gontserrat'),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: breakColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isArabic ? '$_selectedMinutes دقيقة' : '$_selectedMinutes minutes',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: breakColor,
                    fontFamily: 'Gontserrat',
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: breakColor,
              inactiveTrackColor: isDark ? const Color(0xFF2A2D34) : const Color(0xFFE2E8F0),
              thumbColor: breakColor,
              overlayColor: breakColor.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _selectedMinutes.toDouble(),
              min: 1,
              max: 120,
              divisions: 119,
              onChanged: (val) => setState(() => _selectedMinutes = val.round()),
            ),
          ),

          const SizedBox(height: 16),

          // Confirm button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _selectedMinutes),
              style: ElevatedButton.styleFrom(
                backgroundColor: breakColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                isArabic ? 'تأكيد بدء الاستراحة' : 'Confirm Start Break',
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, fontFamily: 'Gontserrat'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BreakCountdownBanner extends StatefulWidget {
  const BreakCountdownBanner({super.key});

  @override
  State<BreakCountdownBanner> createState() => _BreakCountdownBannerState();
}

class _BreakCountdownBannerState extends State<BreakCountdownBanner> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTicker();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  String _formatDuration(Duration diff) {
    if (diff.isNegative) return '00:00';
    final minutes = diff.inMinutes;
    final seconds = diff.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    const breakColor = Color(0xFF6B5DE8);

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is! Authenticated) return const SizedBox.shrink();
        final user = state.user;
        if (!user.isOnBreak) return const SizedBox.shrink();

        final endsAt = user.activeBreakEndsAt;
        if (endsAt == null) return const SizedBox.shrink();

        final now = DateTime.now();
        final remaining = endsAt.difference(now);

        // If time expired, trigger profile refresh to sync back to online
        if (remaining.isNegative) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<AuthCubit>().refreshProfile();
          });
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: breakColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: breakColor.withValues(alpha: 0.4), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: breakColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      isArabic ? 'في استراحة' : 'On break',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: breakColor,
                        fontFamily: 'Gontserrat',
                      ),
                    ),
                    const Text(' • ', style: TextStyle(color: breakColor)),
                    Text(
                      _formatDuration(remaining),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: breakColor,
                        fontFamily: 'Gontserrat',
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () async {
                  await context.read<AuthCubit>().endBreakEarly();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isArabic ? 'تم إنهاء الاستراحة والعودة متصلاً' : 'Break ended. You are now Online.',
                        ),
                        duration: const Duration(seconds: 2),
                        backgroundColor: const Color(0xFF1E2024),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: breakColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isArabic ? 'إنهاء الآن' : 'End Break',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Gontserrat',
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
