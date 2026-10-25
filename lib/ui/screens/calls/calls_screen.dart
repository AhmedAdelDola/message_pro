import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/calls_provider.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/empty_state_widget.dart';

class CallsScreen extends ConsumerWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callsState = ref.watch(callsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل المكالمات (Calls)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(callsProvider.notifier).loadCalls(),
          ),
        ],
      ),
      body: callsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : callsState.calls.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.phone_disabled_rounded,
                  title: 'لا توجد مكالمات',
                  description: 'سجل المكالمات الواردة والصادرة فارغ حالياً.',
                )
              : ListView.separated(
                  itemCount: callsState.calls.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  itemBuilder: (context, index) {
                    final call = callsState.calls[index];
                    final isMissed = call.callType == 'missed';
                    final isIncoming = call.callType == 'incoming';

                    return ListTile(
                      leading: AvatarWidget(
                        avatarUrl: call.avatarUrl,
                        name: call.contactName,
                        size: 44,
                      ),
                      title: Text(
                        call.contactName,
                        style: TextStyle(
                          fontWeight: isMissed ? FontWeight.bold : FontWeight.w600,
                          color: isMissed ? AppColors.danger : null,
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          Icon(
                            isMissed
                                ? Icons.call_missed_rounded
                                : (isIncoming ? Icons.call_received_rounded : Icons.call_made_rounded),
                            size: 15,
                            color: isMissed
                                ? AppColors.danger
                                : (isIncoming ? AppColors.success : AppColors.primaryLight),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isMissed
                                ? 'مكالمة لم يرد عليها'
                                : '${isIncoming ? 'واردة' : 'صادرة'} • ${call.duration}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('hh:mm a').format(call.timestamp),
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.call_rounded, color: AppColors.primaryLight),
                        onPressed: () async {
                          if (call.contactPhone != null) {
                            final uri = Uri.parse('tel:${call.contactPhone}');
                            if (await canLaunchUrl(uri)) await launchUrl(uri);
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
