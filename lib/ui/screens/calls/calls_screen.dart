import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../logic/calls/calls_cubit.dart';
import '../../../logic/calls/calls_state.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/empty_state_widget.dart';

class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل المكالمات (Calls)'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, size: 22.r),
            onPressed: () => context.read<CallsCubit>().loadCalls(),
          ),
        ],
      ),
      body: BlocBuilder<CallsCubit, CallsState>(
        builder: (context, callsState) {
          if (callsState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (callsState.calls.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.phone_disabled_rounded,
              title: 'لا توجد مكالمات',
              description: 'سجل المكالمات الواردة والصادرة فارغ حالياً.',
            );
          }

          return ListView.separated(
            itemCount: callsState.calls.length,
            separatorBuilder: (_, __) => Divider(
              height: 1.h,
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
                    fontSize: 14.sp,
                    color: isMissed ? AppColors.danger : null,
                  ),
                ),
                subtitle: Row(
                  children: [
                    Icon(
                      isMissed
                          ? Icons.call_missed_rounded
                          : (isIncoming ? Icons.call_received_rounded : Icons.call_made_rounded),
                      size: 15.r,
                      color: isMissed
                          ? AppColors.danger
                          : (isIncoming ? AppColors.success : AppColors.primaryLight),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      isMissed
                          ? 'مكالمة لم يرد عليها'
                          : '${isIncoming ? 'واردة' : 'صادرة'} • ${call.duration}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      DateFormat('hh:mm a').format(call.timestamp),
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.call_rounded, color: AppColors.primaryLight, size: 22.r),
                  onPressed: () async {
                    if (call.contactPhone != null) {
                      final uri = Uri.parse('tel:${call.contactPhone}');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
