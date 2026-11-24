import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/contact.dart';
import '../../../../data/models/conversation.dart';
import '../../../../data/models/user.dart';
import '../../../widgets/app_bar_progress_bar.dart';
import '../../../widgets/avatar_widget.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Conversation conversation;
  final Contact contact;
  final String status;
  final bool isMuted;
  final bool isLoading;
  final User? currentAssignee;
  final VoidCallback onContactTap;
  final VoidCallback onUnsnoozeTap;
  final VoidCallback onAssigneeTap;
  final VoidCallback onCollaboratorsTap;
  final VoidCallback onToggleResolveReopen;
  final VoidCallback onSnoozeOptionsTap;
  final VoidCallback onToggleMute;
  final VoidCallback onCopyLink;
  final VoidCallback onCannedResponsesTap;

  const ChatAppBar({
    super.key,
    required this.conversation,
    required this.contact,
    required this.status,
    required this.isMuted,
    required this.isLoading,
    required this.currentAssignee,
    required this.onContactTap,
    required this.onUnsnoozeTap,
    required this.onAssigneeTap,
    required this.onCollaboratorsTap,
    required this.onToggleResolveReopen,
    required this.onSnoozeOptionsTap,
    required this.onToggleMute,
    required this.onCopyLink,
    required this.onCannedResponsesTap,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + 2.h);

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      bottom: AppBarProgressBar(isLoading: isLoading),
      titleSpacing: 0,
      title: InkWell(
        onTap: onContactTap,
        child: Row(
          children: [
            AvatarWidget(
              avatarUrl: contact.avatarUrl,
              name: conversation.displayContactName,
              size: 38,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    conversation.displayContactName,
                    style: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 1.h),
                  if (status == 'snoozed')
                    Row(
                      children: [
                        Icon(Icons.alarm_rounded, size: 11.r, color: const Color(0xFFFA8900)),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(
                            conversation.snoozedUntil != null
                                ? 'Snoozed until ${DateFormat('d MMM, h:mma').format(conversation.snoozedUntil!)}'
                                : 'Snoozed',
                            style: TextStyle(
                              fontSize: 10.5.sp,
                              color: const Color(0xFFFA8900),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      contact.phoneNumber ?? contact.email ?? 'المحادثة #${conversation.id}',
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (status == 'snoozed')
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 2.w),
            child: InkWell(
              onTap: onUnsnoozeTap,
              borderRadius: BorderRadius.circular(6.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFA8900).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: const Color(0xFFFA8900), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.alarm_off_rounded, size: 12.r, color: const Color(0xFFFA8900)),
                    SizedBox(width: 3.w),
                    Text(
                      'Unsnooze',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFA8900),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // Assignee avatar or button
        _buildAssigneeButton(context, isDark),
        // Collaborators button
        IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedUserGroup,
            size: 20.r,
            color: isDark ? Colors.white : Colors.black87,
          ),
          tooltip: 'المتعاونين (Collaborators)',
          onPressed: onCollaboratorsTap,
        ),
        // Overflow Menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (val) {
            switch (val) {
              case 'resolve_reopen':
                onToggleResolveReopen();
                break;
              case 'snooze_options':
                onSnoozeOptionsTap();
                break;
              case 'canned':
                onCannedResponsesTap();
                break;
              case 'mute':
                onToggleMute();
                break;
              case 'contact_details':
                onContactTap();
                break;
              case 'assign_agent':
                onAssigneeTap();
                break;
              case 'collaborators':
                onCollaboratorsTap();
                break;
              case 'copy_link':
                onCopyLink();
                break;
            }
          },
          itemBuilder: (context) {
            final isResolved = status == 'resolved';
            return [
              PopupMenuItem(
                value: 'resolve_reopen',
                child: Row(
                  children: [
                    Icon(
                      isResolved ? Icons.replay_rounded : Icons.check_circle_outline_rounded,
                      color: isResolved ? const Color(0xFF10B981) : const Color(0xFF0284C7),
                      size: 19.r,
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      isResolved
                          ? (isArabic ? 'إعادة فتح المحادثة (Reopen)' : 'Reopen conversation')
                          : (isArabic ? 'إنهاء المحادثة (Resolve)' : 'Resolve conversation'),
                      style: TextStyle(fontSize: 13.sp),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'snooze_options',
                child: Row(
                  children: [
                    Icon(
                      status == 'snoozed' ? Icons.alarm_off_rounded : Icons.alarm_rounded,
                      color: const Color(0xFFFA8900),
                      size: 19.r,
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      isArabic ? 'تأجيل المحادثة (Snooze...)' : 'Snooze conversation...',
                      style: TextStyle(fontSize: 13.sp),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'canned',
                child: Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: const Color(0xFFF59E0B), size: 19.r),
                    SizedBox(width: 10.w),
                    Text(
                      isArabic ? 'الردود الجاهزة (Canned responses)' : 'Canned responses',
                      style: TextStyle(fontSize: 13.sp),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'mute',
                child: Row(
                  children: [
                    Icon(
                      isMuted ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                      color: isMuted ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      size: 19.r,
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      isMuted
                          ? (isArabic ? 'إلغاء كتم المحادثة' : 'Unmute conversation')
                          : (isArabic ? 'كتم المحادثة (Mute)' : 'Mute conversation'),
                      style: TextStyle(fontSize: 13.sp),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'contact_details',
                child: Row(
                  children: [
                    Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 19.r),
                    SizedBox(width: 10.w),
                    Text(
                      isArabic ? 'عرض بيانات العميل' : 'View contact details',
                      style: TextStyle(fontSize: 13.sp),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'assign_agent',
                child: Row(
                  children: [
                    Icon(Icons.assignment_ind_outlined, color: const Color(0xFF10B981), size: 19.r),
                    SizedBox(width: 10.w),
                    Text(
                      isArabic ? 'تعيين مسؤول (Assign)' : 'Assign agent',
                      style: TextStyle(fontSize: 13.sp),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'collaborators',
                child: Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedUserGroup,
                      size: 19.r,
                      color: const Color(0xFF4162E3),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      isArabic ? 'المتعاونين (Collaborators)' : 'Collaborators',
                      style: TextStyle(fontSize: 13.sp),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'copy_link',
                child: Row(
                  children: [
                    Icon(Icons.link_rounded, color: const Color(0xFF6366F1), size: 19.r),
                    SizedBox(width: 10.w),
                    Text(
                      isArabic ? 'نسخ رابط المحادثة' : 'Copy conversation link',
                      style: TextStyle(fontSize: 13.sp),
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
      ],
    );
  }

  Widget _buildAssigneeButton(BuildContext context, bool isDark) {
    final activeAssignee = currentAssignee ?? conversation.assignee;
    if (activeAssignee != null) {
      final isBot = activeAssignee.isBot || activeAssignee.assigneeType == 'AgentBot';
      final botEmoji = activeAssignee.emoji ??
          (activeAssignee.name.isNotEmpty && activeAssignee.name.trim().characters.first.runes.first > 255
              ? activeAssignee.name.trim().characters.first
              : '🤖');
      return InkWell(
        onTap: onAssigneeTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 12.r,
                backgroundColor: isBot
                    ? const Color(0xFF5850EC).withValues(alpha: 0.2)
                    : const Color(0xFF4162E3).withValues(alpha: 0.2),
                backgroundImage: (!isBot && activeAssignee.avatarUrl != null && activeAssignee.avatarUrl!.isNotEmpty)
                    ? NetworkImage(activeAssignee.avatarUrl!)
                    : null,
                child: isBot
                    ? Text(botEmoji, style: TextStyle(fontSize: 12.sp))
                    : (activeAssignee.avatarUrl == null || activeAssignee.avatarUrl!.isEmpty
                        ? Text(
                            activeAssignee.name.isNotEmpty ? activeAssignee.name[0].toUpperCase() : 'A',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4162E3),
                            ),
                          )
                        : null),
              ),
              Icon(Icons.keyboard_arrow_down_rounded, size: 14.r, color: Colors.grey),
            ],
          ),
        ),
      );
    }
    return InkWell(
      onTap: onAssigneeTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF282C35) : const Color(0xFFEFF2F6),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark ? const Color(0xFF3E4451) : const Color(0xFFD1D5DB),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_outline_rounded,
              size: 13.r,
              color: isDark ? Colors.grey[300] : const Color(0xFF4B5563),
            ),
            SizedBox(width: 3.w),
            Text(
              Localizations.localeOf(context).languageCode == 'ar' ? 'غير معيّن' : 'Unassigned',
              style: TextStyle(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : const Color(0xFF4B5563),
              ),
            ),
            SizedBox(width: 2.w),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 13.r,
              color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }
}
