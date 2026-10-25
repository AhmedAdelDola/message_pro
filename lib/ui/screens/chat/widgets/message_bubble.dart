import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
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
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF262626) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message.content ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ),
      );
    }

    final isPrivate = message.isPrivateNote;
    final isOutgoing = message.isOutgoing;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: isPrivate
            ? CrossAxisAlignment.center
            : (isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start),
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPrivate
                  ? (isDark ? AppColors.privateNoteDark : AppColors.privateNoteLight)
                  : (isOutgoing
                      ? AppColors.outgoingBubble
                      : (isDark ? AppColors.incomingBubbleDark : AppColors.incomingBubbleLight)),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(isOutgoing && !isPrivate ? 14 : 2),
                bottomRight: Radius.circular(!isOutgoing && !isPrivate ? 14 : 2),
              ),
              border: isPrivate
                  ? Border.all(color: AppColors.privateNoteBorder.withValues(alpha: 0.5), width: 1.2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
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
                      const Icon(Icons.lock_outline, size: 13, color: AppColors.privateNoteBorder),
                      const SizedBox(width: 4),
                      Text(
                        'ملاحظة خاصة • ${message.senderName ?? 'فريق العمل'}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.privateNoteBorder,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],

                // Attachments
                if (message.attachments.isNotEmpty) ...[
                  ...message.attachments.map((att) => _buildAttachment(context, att)),
                  const SizedBox(height: 6),
                ],

                // Text content
                if (message.content != null && message.content!.isNotEmpty)
                  Text(
                    message.content!,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.35,
                      color: isPrivate
                          ? (isDark ? Colors.amber[100] : Colors.brown[900])
                          : (isOutgoing
                              ? Colors.white
                              : (isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary)),
                    ),
                  ),

                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: isPrivate
                            ? Colors.amber[700]
                            : (isOutgoing ? Colors.white70 : Colors.grey[500]),
                      ),
                    ),
                    if (isOutgoing && !isPrivate) ...[
                      const SizedBox(width: 4),
                      _buildDeliveryStatus(message.status),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachment(BuildContext context, MessageAttachment att) {
    if (att.fileType == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: att.dataUrl,
          fit: BoxFit.cover,
          placeholder: (_, __) => const SizedBox(
            height: 150,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 40),
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              att.fileType == 'audio' ? Icons.audiotrack : Icons.insert_drive_file,
              size: 20,
              color: AppColors.primaryLight,
            ),
            const SizedBox(width: 8),
            Text(
              att.fileType == 'audio' ? 'رسالة صوتية' : 'مرفق ملف',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryStatus(String status) {
    switch (status.toLowerCase()) {
      case 'read':
        return const Icon(Icons.done_all_rounded, size: 14, color: Colors.lightBlueAccent);
      case 'delivered':
        return const Icon(Icons.done_all_rounded, size: 14, color: Colors.white70);
      case 'failed':
        return const Icon(Icons.error_outline, size: 14, color: Colors.redAccent);
      default:
        return const Icon(Icons.done_rounded, size: 14, color: Colors.white70);
    }
  }
}
