import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/conversation_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/empty_state_widget.dart';
import '../chat/chat_screen.dart';
import '../search/search_screen.dart';
import '../contacts/add_contact_screen.dart';
import 'widgets/conversation_tile.dart';
import 'widgets/inbox_filter_bar.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversationProvider);
    final authState = ref.watch(authProvider);
    final notifier = ref.read(conversationProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final user = authState.user;
    final currentAccountName = user?.accounts.isNotEmpty == true
        ? user!.accounts.firstWhere((a) => a.id == user.accountId, orElse: () => user.accounts.first).name
        : 'Message Pro';

    final conversations = notifier.filteredConversations;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: user?.availabilityStatus == 'online'
                    ? AppColors.success
                    : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentAccountName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user != null ? '${user.name} (${user.role})' : 'متصل',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => notifier.loadConversations(),
          ),
        ],
      ),
      body: Column(
        children: [
          const InboxFilterBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => notifier.loadConversations(),
              child: state.isLoading && conversations.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                      ),
                    )
                  : conversations.isEmpty
                      ? EmptyStateWidget(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'لا توجد محادثات هنا',
                          description: 'لا توجد أي محادثات تطابق الفلتر الحالي حالياً.',
                          buttonText: 'تحديث المحادثات',
                          onButtonPressed: () => notifier.loadConversations(),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: conversations.length,
                          itemBuilder: (context, index) {
                            final conv = conversations[index];
                            return ConversationTile(
                              conversation: conv,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(conversation: conv),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_comment_rounded),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddContactScreen()),
          );
        },
      ),
    );
  }
}
