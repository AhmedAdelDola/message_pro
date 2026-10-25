import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  String _formatTime(DateTime dt) {
    return DateFormat('hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Activity message (e.g. system assignment or status change)
    if (message.isActivity) {
      return Center(
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 24.w),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF262626) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Text(
            message.content ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ),
      );
    }

    final isPrivate = message.isPrivateNote;
    final isOutgoing = message.isOutgoing;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      child: Column(
        crossAxisAlignment: isPrivate
            ? CrossAxisAlignment.center
            : (isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start),
        children: [
          RepaintBoundary(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 0.78.sw,
              ),
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: isPrivate
                    ? (isDark ? AppColors.privateNoteDark : AppColors.privateNoteLight)
                    : (isOutgoing
                        ? AppColors.outgoingBubble
                        : (isDark ? AppColors.incomingBubbleDark : AppColors.incomingBubbleLight)),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14.r),
                  topRight: Radius.circular(14.r),
                  bottomLeft: Radius.circular(isOutgoing && !isPrivate ? 14.r : 2.r),
                  bottomRight: Radius.circular(!isOutgoing && !isPrivate ? 14.r : 2.r),
                ),
                border: isPrivate
                    ? Border.all(color: AppColors.privateNoteBorder.withValues(alpha: 0.5), width: 1.2.r)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 3.r,
                    offset: Offset(0, 1.h),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isPrivate) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline, size: 13.r, color: AppColors.privateNoteBorder),
                        SizedBox(width: 4.w),
                        Text(
                          'ملاحظة خاصة • ${message.senderName ?? 'فريق العمل'}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.privateNoteBorder,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                  ],

                  // Attachments
                  if (message.attachments.isNotEmpty) ...[
                    ...message.attachments.map((att) => _buildAttachment(context, att)),
                    SizedBox(height: 6.h),
                  ],

                  // Text content
                  if (message.content != null && message.content!.isNotEmpty)
                    Text(
                      message.content!,
                      style: TextStyle(
                        fontSize: 14.5.sp,
                        height: 1.35,
                        color: isPrivate
                            ? (isDark ? Colors.amber[100] : Colors.brown[900])
                            : (isOutgoing
                                ? Colors.white
                                : (isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary)),
                      ),
                    ),

                  SizedBox(height: 4.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: isPrivate
                              ? Colors.amber[700]
                              : (isOutgoing ? Colors.white70 : Colors.grey[500]),
                        ),
                      ),
                      if (isOutgoing && !isPrivate) ...[
                        SizedBox(width: 4.w),
                        _buildDeliveryStatus(message.status),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachment(BuildContext context, MessageAttachment att) {
    if (att.fileType == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: CachedNetworkImage(
          imageUrl: att.dataUrl,
          fit: BoxFit.cover,
          memCacheWidth: 600,
          placeholder: (_, __) => SizedBox(
            height: 150.h,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (_, __, ___) => Icon(Icons.broken_image, size: 40.r),
        ),
      );
    }

    return InkWell(
      onTap: () async {
        if (att.dataUrl.isNotEmpty) {
          final uri = Uri.parse(att.dataUrl);
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        }
      },
      child: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              att.fileType == 'audio' ? Icons.audiotrack : Icons.insert_drive_file,
              size: 20.r,
              color: AppColors.primaryLight,
            ),
            SizedBox(width: 8.w),
            Text(
              att.fileType == 'audio' ? 'رسالة صوتية' : 'مرفق ملف',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryStatus(String status) {
    switch (status.toLowerCase()) {
      case 'read':
        return Icon(Icons.done_all_rounded, size: 14.r, color: Colors.lightBlueAccent);
      case 'delivered':
        return Icon(Icons.done_all_rounded, size: 14.r, color: Colors.white70);
      case 'failed':
        return Icon(Icons.error_outline, size: 14.r, color: Colors.redAccent);
      default:
        return Icon(Icons.done_rounded, size: 14.r, color: Colors.white70);
    }
  }
}
