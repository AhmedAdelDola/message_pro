import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:message_pro/core/constants/app_colors.dart';
import 'package:message_pro/core/constants/app_lottie.dart';
import 'package:message_pro/data/models/conversation.dart';
import 'package:message_pro/logic/conversation/conversation_cubit.dart';
import 'package:message_pro/ui/screens/chat/chat_screen.dart';
import 'package:message_pro/ui/screens/chat/widgets/start_direct_chat_sheet.dart';
import '../conversation_tile.dart';

class InboxConversationsListView extends StatelessWidget {
  final List<Conversation> conversations;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final void Function(Conversation conv) onLongPress;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final VoidCallback onRetry;
  final bool isSearching;
  final String searchQuery;
  final bool isDark;
  final bool isArabic;

  const InboxConversationsListView({
    super.key,
    required this.conversations,
    required this.scrollController,
    required this.onRefresh,
    required this.onLongPress,
    required this.isLoading,
    required this.isLoadingMore,
    this.errorMessage,
    required this.onRetry,
    required this.isSearching,
    required this.searchQuery,
    required this.isDark,
    required this.isArabic,
  });

  bool _looksLikePhoneNumber(String text) {
    final clean = text.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    if (clean.length < 7 || clean.length > 16) return false;
    return RegExp(r'^\+?[0-9]{7,15}$').hasMatch(clean);
  }

  String _cleanSearchPhoneNumber(String text) {
    var p = text.trim().replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    if (p.startsWith('00')) {
      p = '+${p.substring(2)}';
    } else if (p.startsWith('01') && p.length == 11) {
      p = '+2$p';
    } else if (p.startsWith('201') && p.length == 12) {
      p = '+$p';
    }
    return p;
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark
        ? AppColors.textLightPrimary
        : AppColors.textDarkPrimary;
    final textSecondary = isDark
        ? AppColors.textLightSecondary
        : AppColors.textDarkSecondary;

    if (isLoading && conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (errorMessage != null && conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.danger,
              ),
              const SizedBox(height: 12),
              Text(
                isArabic
                    ? 'حدث خطأ أثناء تحميل المحادثات'
                    : 'Error loading conversations',
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(isArabic ? 'إعادة المحاولة' : 'Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (conversations.isEmpty) {
      final isPhoneQuery = isSearching && _looksLikePhoneNumber(searchQuery);

      if (isPhoneQuery) {
        final cleanNumber = _cleanSearchPhoneNumber(searchQuery);
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2024) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isArabic
                        ? 'لا توجد محادثة سابقة مع هذا الرقم'
                        : 'No existing chat with this number',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      searchQuery,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        StartDirectChatSheet.show(
                          context,
                          initialPhone: cleanNumber,
                        );
                      },
                      icon: const Icon(Icons.add_comment_rounded, size: 18),
                      label: Text(
                        isArabic
                            ? 'بدء محادثة جديدة مع الرقم'
                            : 'Start chat with this number',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child:
              Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppLottie.emptyInbox(width: 140, height: 140),
                      const SizedBox(height: 14),
                      Text(
                        isArabic
                            ? 'لا توجد محادثات لعرضها'
                            : 'No conversations to show',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  )
                  .animate()
                  .fadeIn(duration: 350.ms, curve: Curves.easeOut)
                  .scale(
                    begin: const Offset(0.95, 0.95),
                    end: const Offset(1, 1),
                  ),
        ),
      );
    }

    final isPhoneQuery = isSearching && _looksLikePhoneNumber(searchQuery);
    final cleanSearchNumber = isPhoneQuery
        ? _cleanSearchPhoneNumber(searchQuery)
        : '';
    final hasExactMatch =
        isPhoneQuery &&
        conversations.any((c) {
          final cPhone = (c.contact.phoneNumber ?? '').replaceAll(
            RegExp(r'[\s\-\(\)\.]'),
            '',
          );
          final sPhone = cleanSearchNumber.replaceAll('+', '');
          return cPhone.isNotEmpty &&
              (cPhone.endsWith(sPhone) || sPhone.endsWith(cPhone));
        });
    final showStartChatBanner = isPhoneQuery && !hasExactMatch;
    final extraBannerCount = showStartChatBanner ? 1 : 0;
    final totalItemCount =
        conversations.length + extraBannerCount + (isLoadingMore ? 1 : 0);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: isLoading ? 0.6 : 1.0,
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: onRefresh,
        child: ListView.builder(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: totalItemCount,
          itemBuilder: (context, index) {
            if (showStartChatBanner && index == 0) {
              return InkWell(
                onTap: () {
                  StartDirectChatSheet.show(
                    context,
                    initialPhone: cleanSearchNumber,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_comment_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isArabic
                                  ? 'بدء محادثة جديدة'
                                  : 'Start new conversation',
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                isArabic
                                    ? 'فتح محادثة مع $searchQuery'
                                    : 'Open chat with $searchQuery',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isArabic
                            ? Icons.arrow_back_ios_new_rounded
                            : Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              );
            }

            final effectiveIndex = showStartChatBanner ? index - 1 : index;

            if (effectiveIndex == conversations.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }

            final conv = conversations[effectiveIndex];
            return ConversationTile(
                  key: ValueKey(conv.id),
                  conversation: conv,
                  onTap: () async {
                    context.read<ConversationCubit>().markConversationAsRead(
                      conv.id,
                    );
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          conversation: conv.copyWith(unreadCount: 0),
                        ),
                      ),
                    );
                    if (context.mounted) {
                      context.read<ConversationCubit>().markConversationAsRead(
                        conv.id,
                      );
                    }
                  },
                  onLongPress: () => onLongPress(conv),
                )
                .animate()
                .fadeIn(duration: 250.ms, curve: Curves.easeOut)
                .slideY(
                  begin: 0.05,
                  end: 0,
                  duration: 250.ms,
                  curve: Curves.easeOut,
                );
          },
        ),
      ),
    );
  }
}
