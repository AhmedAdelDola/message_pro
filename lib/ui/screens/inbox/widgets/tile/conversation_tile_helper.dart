import 'package:intl/intl.dart';
import 'package:message_pro/data/models/contact.dart';
import 'package:message_pro/data/models/conversation.dart';

/// Pure helper for formatting and data extraction in ConversationTile.
class ConversationTileHelper {
  ConversationTileHelper._();

  static String formatTime(DateTime dt, bool isArabic) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inDays == 0 && now.day == dt.day) {
      final hourMin = DateFormat('h:mm').format(dt);
      final amPm = dt.hour >= 12
          ? (isArabic ? 'م' : 'PM')
          : (isArabic ? 'ص' : 'AM');
      return '$hourMin $amPm';
    }

    final yesterday = now.subtract(const Duration(days: 1));
    if (yesterday.day == dt.day &&
        yesterday.month == dt.month &&
        yesterday.year == dt.year) {
      return isArabic ? 'أمس' : 'Yesterday';
    }

    if (difference.inDays < 7) {
      return DateFormat('EEE', isArabic ? 'ar' : 'en').format(dt);
    }

    return DateFormat('MMM d', isArabic ? 'ar' : 'en').format(dt);
  }

  static String resolveDisplayName(Conversation conversation, bool isArabic) {
    final contact = conversation.contact;
    String cname = conversation.displayContactName;
    final nameLower = cname.toLowerCase();
    final isGeneric = nameLower.isEmpty ||
        nameLower == 'contact #null' ||
        nameLower == 'null' ||
        nameLower == 'customer' ||
        nameLower == 'عميل' ||
        nameLower == 'عميل جديد' ||
        nameLower == 'new visitor' ||
        nameLower.startsWith('عميل #') ||
        nameLower.startsWith('contact #');

    if (isGeneric) {
      if (contact.phoneNumber != null && contact.phoneNumber!.isNotEmpty) {
        return contact.phoneNumber!;
      } else if (contact.email != null && contact.email!.isNotEmpty) {
        return contact.email!;
      } else if (conversation.id > 0) {
        return isArabic ? 'عميل #${conversation.id}' : 'Contact #${conversation.id}';
      } else {
        return isArabic ? 'عميل جديد' : 'New Visitor';
      }
    }
    return cname;
  }

  static String resolveLastMessagePreview(Conversation conversation, bool isArabic) {
    final lastMsg = conversation.lastMessage;
    if (lastMsg == null) {
      return isArabic ? 'لا توجد رسائل' : 'No messages yet';
    }

    if (lastMsg.isDeleted) {
      return isArabic ? 'تم حذف هذه الرسالة' : 'This message was deleted';
    }

    if (lastMsg.cleanContent.isNotEmpty) {
      return lastMsg.cleanContent;
    } else if (lastMsg.attachments.isNotEmpty) {
      final count = lastMsg.attachments.length;
      final firstType = lastMsg.attachments.first.fileType;
      if (firstType == 'image') {
        return isArabic
            ? (count > 1 ? '📷 $count صور' : '📷 صورة')
            : (count > 1 ? '📷 $count Photos' : '📷 Image');
      } else if (firstType == 'audio') {
        return isArabic ? '🎵 تسجيل صوتي' : '🎵 Audio';
      } else if (firstType == 'video') {
        return isArabic
            ? (count > 1 ? '🎥 $count فيديوهات' : '🎥 فيديو')
            : (count > 1 ? '🎥 $count Videos' : '🎥 Video');
      } else {
        return isArabic
            ? (count > 1 ? '📎 $count ملفات' : '📎 ملف مرفق')
            : (count > 1 ? '📎 $count Files' : '📎 Attachment');
      }
    } else if (lastMsg.isActivity) {
      return lastMsg.content ?? (isArabic ? 'نشاط في المحادثة' : 'Activity');
    }
    return isArabic ? 'لا توجد رسائل' : 'No messages yet';
  }

  static String resolveChannel(
    Conversation conversation,
    List<Inbox> inboxes,
    String displayName,
  ) {
    final matchingInbox = inboxes.where((i) => i.id == conversation.inboxId).firstOrNull;

    String resolvedChannel = (matchingInbox != null && matchingInbox.channelType.isNotEmpty)
        ? matchingInbox.channelType
        : conversation.channelType;

    final chLower = resolvedChannel.toLowerCase();
    if (resolvedChannel.isEmpty || chLower == 'web' || chLower == 'channel::webwidget') {
      final inbName = (matchingInbox?.name ?? conversation.inboxName ?? '').toLowerCase();
      final cPhone = conversation.contact.phoneNumber ?? '';
      final cNameLower = displayName.toLowerCase();

      if (inbName.contains('whatsapp') || cPhone.isNotEmpty || cNameLower.contains('@c.us')) {
        resolvedChannel = 'whatsapp';
      } else if (inbName.contains('instagram')) {
        resolvedChannel = 'instagram';
      } else if (inbName.contains('facebook') || inbName.contains('messenger')) {
        resolvedChannel = 'facebook';
      } else if (inbName.contains('telegram')) {
        resolvedChannel = 'telegram';
      } else if (inbName.contains('email') || (conversation.contact.email != null && conversation.contact.email!.isNotEmpty)) {
        resolvedChannel = 'email';
      } else if (inbName.contains('sms')) {
        resolvedChannel = 'sms';
      } else if (inbName.contains('api')) {
        resolvedChannel = 'api';
      } else {
        resolvedChannel = conversation.channel.isNotEmpty ? conversation.channel : 'web';
      }
    }
    return resolvedChannel;
  }
}
