import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../logic/calls/calls_cubit.dart';
import '../../../logic/calls/calls_state.dart';
import '../../widgets/avatar_widget.dart';
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
                          fontFamily: 'Gontserrat',
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

                // Calls Content
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => cubit.loadCalls(),
                    child: callsState.isLoading && calls.isEmpty
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          )
                        : calls.isEmpty
                            // Exact Coming Soon view from browser Tab 2
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.phone_outlined,
                                        size: 40,
                                        color: textSecondary.withValues(alpha: 0.8),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        isArabic ? 'قريبًا' : 'Coming soon',
                                        style: TextStyle(
                                          color: textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          fontFamily: 'Gontserrat',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        isArabic
                                            ? 'ستكون المكالمات متاحة هنا في تحديث مستقبلي.'
                                            : 'Calls will be available here in a future update.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: textSecondary,
                                          fontSize: 14,
                                          height: 1.4,
                                          fontFamily: 'Gontserrat',
                                        ),
                                      ),
                                    ],
                                  ),
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
                                                  fontFamily: 'Gontserrat',
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
                                                      fontFamily: 'Gontserrat',
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
                                  );
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
