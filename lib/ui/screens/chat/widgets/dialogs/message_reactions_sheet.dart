import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../data/models/message.dart';
import '../../../../../logic/chat/chat_cubit.dart';
import '../../../../widgets/avatar_widget.dart';

class MessageReactionsSheet extends StatelessWidget {
  final Message message;

  const MessageReactionsSheet({
    super.key,
    required this.message,
  });

  static Future<void> show({
    required BuildContext context,
    required Message message,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF161616) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => MessageReactionsSheet(message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatCubit = context.read<ChatCubit>();

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF31343A) : const Color(0xFFEAEAEA),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  isArabic ? 'التفاعلات على الرسالة' : 'Message Reactions',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4162E3).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${message.reactions.length}',
                    style: const TextStyle(color: Color(0xFF4162E3), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: FutureBuilder(
              future: chatCubit.getReactions(message.id, contentAttributes: message.contentAttributes),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final result = snapshot.data;
                if (result == null || result.isLeft()) {
                  if (message.reactions.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          isArabic ? 'لا توجد تفاعلات' : 'No reactions',
                          style: const TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: message.reactions.length,
                    itemBuilder: (_, i) {
                      final r = message.reactions[i];
                      return ListTile(
                        title: Text(r.userName ?? (isArabic ? 'مشارك' : 'Participant')),
                        trailing: Text(r.emoji, style: const TextStyle(fontSize: 22)),
                      );
                    },
                  );
                }

                final participants = result.getOrElse(() => []);
                if (participants.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        isArabic ? 'لا توجد تفاعلات' : 'No reactions',
                        style: const TextStyle(color: Color(0xFF94A3B8)),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: participants.length,
                  itemBuilder: (_, i) {
                    final p = participants[i];
                    return ListTile(
                      leading: AvatarWidget(
                        avatarUrl: p.avatarUrl,
                        name: p.name,
                        size: 36,
                      ),
                      title: Text(
                        p.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: Text(
                        p.emoji ?? '👍',
                        style: const TextStyle(fontSize: 24),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
