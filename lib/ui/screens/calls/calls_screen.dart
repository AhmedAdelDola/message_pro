import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../logic/calls/calls_cubit.dart';
import '../../../logic/calls/calls_state.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/app_bar_progress_bar.dart';
import '../contacts/add_contact_screen.dart';

class CallsScreen extends StatefulWidget {
  const CallsScreen({super.key});

  @override
  State<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> {
  final String _selectedFilter = 'all'; // 'all', 'missed', 'incoming'

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: BlocBuilder<CallsCubit, CallsState>(
          builder: (context, callsState) {
            final cubit = context.read<CallsCubit>();

            var calls = callsState.calls;
            if (_selectedFilter == 'missed') {
              calls = calls.where((c) => c.callType == 'missed').toList();
            } else if (_selectedFilter == 'incoming') {
              calls = calls.where((c) => c.callType == 'incoming').toList();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Height 56px matching web layout)
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isArabic ? 'المكالمات' : 'Calls',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.person_add_alt_outlined, color: textPrimary, size: 20),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const AddContactScreen()),
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.refresh_rounded, color: textPrimary, size: 20),
                            onPressed: () => cubit.loadCalls(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                LinearHeaderLoader(isLoading: callsState.isLoading),

                // Calls Content
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => cubit.loadCalls(),
                    child: callsState.isLoading && calls.isEmpty
                        ? const SizedBox.shrink()
                        : calls.isEmpty
                            // Coming Soon / Empty Calls view with Lottie animation
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 140,
                                        height: 140,
                                        child: Lottie.asset(
                                          'assets/animations/calls_empty.json',
                                          repeat: true,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => Icon(
                                            Icons.phone_outlined,
                                            size: 52,
                                            color: textSecondary.withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        isArabic ? 'سجل المكالمات' : 'Calls log',
                                        style: TextStyle(
                                          color: textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        isArabic
                                            ? 'ستكون المكالمات وسجل الاتصالات مع العملاء متاحة هنا قريبًا.'
                                            : 'Calls and communication logs will be available here soon.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: textSecondary,
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  )
                                      .animate()
                                      .fadeIn(duration: 350.ms, curve: Curves.easeOut)
                                      .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
                                ),
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: calls.length,
                                itemBuilder: (context, index) {
                                  final call = calls[index];
                                  final isMissed = call.callType == 'missed';
                                  final isIncoming = call.callType == 'incoming';
                                  final timeStr = DateFormat('MMM d, hh:mm a').format(call.timestamp);

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                                    ),
                                    child: Row(
                                      children: [
                                        AvatarWidget(
                                          avatarUrl: call.avatarUrl,
                                          name: call.contactName,
                                          size: 42,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                call.contactName,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                  color: isMissed ? AppColors.danger : textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Row(
                                                children: [
                                                  Icon(
                                                    isMissed
                                                        ? Icons.call_missed_rounded
                                                        : (isIncoming ? Icons.call_received_rounded : Icons.call_made_rounded),
                                                    size: 14,
                                                    color: isMissed
                                                        ? AppColors.danger
                                                        : (isIncoming ? AppColors.success : AppColors.primary),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    timeStr,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF80838D),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (call.phoneNumber.isNotEmpty)
                                          IconButton(
                                            icon: const Icon(Icons.phone_rounded, color: AppColors.primary, size: 20),
                                            onPressed: () => launchUrl(Uri.parse('tel:${call.phoneNumber}')),
                                          ),
                                      ],
                                    ),
                                  )
                                      .animate()
                                      .fadeIn(duration: 250.ms, curve: Curves.easeOut)
                                      .slideY(begin: 0.05, end: 0, duration: 250.ms, curve: Curves.easeOut);
                                },
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
}
