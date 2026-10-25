import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../logic/conversation/conversation_cubit.dart';
import '../../../logic/conversation/conversation_state.dart';
import '../../../logic/auth/auth_cubit.dart';
import '../../../logic/auth/auth_state.dart';
import '../../widgets/empty_state_widget.dart';
import '../chat/chat_screen.dart';
import '../search/search_screen.dart';
import '../contacts/add_contact_screen.dart';
import 'widgets/conversation_tile.dart';
import 'widgets/inbox_filter_bar.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            final user = authState is Authenticated ? authState.user : null;
            final currentAccountName = user?.accounts.isNotEmpty == true
                ? user!.accounts.firstWhere((a) => a.id == user.accountId, orElse: () => user.accounts.first).name
                : 'Message Pro';

            return Row(
              children: [
                Container(
                  width: 10.r,
                  height: 10.r,
                  decoration: BoxDecoration(
                    color: user?.availabilityStatus == 'online'
                        ? AppColors.success
                        : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentAccountName,
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user != null ? '${user.name} (${user.role})' : 'متصل',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded, size: 22.r),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, size: 22.r),
            onPressed: () => context.read<ConversationCubit>().loadConversations(),
          ),
        ],
      ),
      body: Column(
        children: [
          const InboxFilterBar(),
          Expanded(
            child: BlocBuilder<ConversationCubit, ConversationState>(
              builder: (context, state) {
                final cubit = context.read<ConversationCubit>();
                final conversations = cubit.filteredConversations;

                return RefreshIndicator(
                  onRefresh: () => cubit.loadConversations(),
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
                              onButtonPressed: () => cubit.loadConversations(),
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              addRepaintBoundaries: true,
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
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: Icon(Icons.add_comment_rounded, size: 24.r),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddContactScreen()),
          );
        },
      ),
    );
  }
}
