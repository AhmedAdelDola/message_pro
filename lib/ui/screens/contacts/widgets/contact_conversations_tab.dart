import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/contact.dart';
import '../../../../logic/conversation/conversation_cubit.dart';
import '../../../../logic/conversation/conversation_state.dart';
import '../../chat/chat_screen.dart';

class ContactConversationsTab extends StatelessWidget {
  final Contact contact;
  final bool isStartingConversation;
  final VoidCallback onStartNewConversation;

  const ContactConversationsTab({
    super.key,
    required this.contact,
    required this.isStartingConversation,
    required this.onStartNewConversation,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB);
    final cardBg = isDark ? const Color(0xFF161616) : Colors.white;

    return BlocBuilder<ConversationCubit, ConversationState>(
      builder: (context, state) {
        final contactConversations = state.conversations.where((c) {
          return c.contact.id == contact.id ||
              (c.contact.phoneNumber != null &&
                  c.contact.phoneNumber == contact.phoneNumber &&
                  c.contact.phoneNumber!.isNotEmpty);
        }).toList();

        if (contactConversations.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 48, color: textSecondary.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text(
                    isArabic ? 'لا توجد محادثات سابقة' : 'No prior conversations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isArabic
                        ? 'محادثات هذا العميل ستظهر هنا عند التواصل معه.'
                        : 'Conversations with this contact will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: onStartNewConversation,
                    icon: isStartingConversation
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.chat_bubble_rounded, size: 18),
                    label: Text(
                      isArabic ? 'بدء محادثة على السيستم' : 'Start Conversation',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4162E3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: contactConversations.length,
          itemBuilder: (context, index) {
            final conv = contactConversations[index];
            final isOpen = conv.status == 'open';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Material(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  onTap: () {
                    try {
                      context.read<ConversationCubit>().markConversationAsRead(conv.id);
                    } catch (_) {}
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(conversation: conv.copyWith(unreadCount: 0)),
                      ),
                    );
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                title: Row(
                  children: [
                    Text(
                      '#${conv.id} - ${conv.inboxName ?? 'Chat'}',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOpen ? Colors.green.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isOpen ? (isArabic ? 'مفتوحة' : 'Open') : (isArabic ? 'مغلقة' : 'Resolved'),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: isOpen ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: conv.lastMessage?.content != null
                    ? Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          conv.lastMessage!.content!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, color: textSecondary),
                        ),
                      )
                    : null,
                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
              ),
            ),
          );
          },
        );
      },
    );
  }
}
