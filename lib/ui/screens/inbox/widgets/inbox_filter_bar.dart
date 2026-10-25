import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../logic/conversation/conversation_cubit.dart';
import '../../../../logic/conversation/conversation_state.dart';

class InboxFilterBar extends StatelessWidget {
  const InboxFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<ConversationCubit, ConversationState>(
      buildWhen: (prev, curr) =>
          prev.assigneeType != curr.assigneeType ||
          prev.status != curr.status ||
          prev.selectedInboxId != curr.selectedInboxId ||
          prev.inboxes != curr.inboxes,
      builder: (context, state) {
        final cubit = context.read<ConversationCubit>();

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1.h,
              ),
            ),
          ),
          child: Column(
            children: [
              // Assignee Tabs
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Container(
                  height: 38.h,
                  padding: EdgeInsets.all(3.r),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF262626) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    children: [
                      _buildTab(
                        label: 'الكل',
                        isSelected: state.assigneeType == 'all',
                        onTap: () => cubit.setAssigneeType('all'),
                        isDark: isDark,
                      ),
                      _buildTab(
                        label: 'محادثاتي',
                        isSelected: state.assigneeType == 'me',
                        onTap: () => cubit.setAssigneeType('me'),
                        isDark: isDark,
                      ),
                      _buildTab(
                        label: 'غير معين',
                        isSelected: state.assigneeType == 'unassigned',
                        onTap: () => cubit.setAssigneeType('unassigned'),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),

              // Horizontal Filter Chips (Status & Inboxes)
              SizedBox(
                height: 42.h,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  children: [
                    _buildStatusChip('open', 'مفتوحة (Open)', state.status, cubit),
                    _buildStatusChip('pending', 'معلقة (Pending)', state.status, cubit),
                    _buildStatusChip('snoozed', 'مؤجلة (Snoozed)', state.status, cubit),
                    _buildStatusChip('resolved', 'مغلقة (Resolved)', state.status, cubit),

                    if (state.inboxes.isNotEmpty) ...[
                      VerticalDivider(width: 16.w, indent: 8.h, endIndent: 8.h),
                      ...state.inboxes.map((inbox) {
                        final isSel = state.selectedInboxId == inbox.id;
                        return Padding(
                          padding: EdgeInsets.only(right: 6.w),
                          child: FilterChip(
                            selected: isSel,
                            label: Text(inbox.name, style: TextStyle(fontSize: 12.sp)),
                            onSelected: (_) => cubit.setInboxFilter(isSel ? null : inbox.id),
                            selectedColor: AppColors.primary.withValues(alpha: 0.15),
                            checkmarkColor: AppColors.primary,
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 6.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.darkCard : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4.r,
                      offset: Offset(0, 2.h),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? AppColors.primaryLight
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(
    String statusKey,
    String label,
    String currentStatus,
    ConversationCubit cubit,
  ) {
    final isSelected = currentStatus == statusKey;
    return Padding(
      padding: EdgeInsets.only(right: 6.w),
      child: ChoiceChip(
        selected: isSelected,
        label: Text(label, style: TextStyle(fontSize: 12.sp)),
        onSelected: (selected) {
          if (selected) cubit.setStatus(statusKey);
        },
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
      ),
    );
  }
}
