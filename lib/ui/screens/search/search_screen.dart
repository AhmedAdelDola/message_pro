import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:message_pro/core/constants/app_colors.dart';
import 'package:message_pro/data/models/conversation.dart';
import 'package:message_pro/logic/contacts/contacts_cubit.dart';
import 'package:message_pro/logic/contacts/contacts_state.dart';
import 'package:message_pro/logic/conversation/conversation_cubit.dart';
import 'package:message_pro/logic/conversation/conversation_state.dart';
import 'package:message_pro/ui/screens/chat/chat_screen.dart';
import 'package:message_pro/ui/screens/contacts/contact_details_screen.dart';
import 'package:message_pro/ui/screens/inbox/widgets/conversation_tile.dart';
import 'package:message_pro/ui/widgets/empty_state_widget.dart';
import 'widgets/search_contact_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    context.read<ContactsCubit>().search(query.trim());
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return BlocBuilder<ConversationCubit, ConversationState>(
      builder: (context, convState) {
        return BlocBuilder<ContactsCubit, ContactsState>(
          builder: (context, contactsState) {
            final query = _controller.text.trim().toLowerCase();

            final matchingConvs = query.isEmpty
                ? <Conversation>[]
                : convState.conversations.where((c) {
                    return c.contact.name.toLowerCase().contains(query) ||
                        (c.lastMessage?.content?.toLowerCase().contains(query) ?? false);
                  }).toList();

            final contacts = contactsState.contacts;
            final isSearching = contactsState.status == ContactsStatus.loading;

            return Scaffold(
              appBar: AppBar(
                title: TextField(
                  controller: _controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: isArabic
                        ? 'ابحث في المحادثات وجهات الاتصال...'
                        : 'Search conversations & contacts...',
                    border: InputBorder.none,
                  ),
                  onChanged: _onSearchChanged,
                ),
                actions: [
                  if (_controller.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        _onSearchChanged('');
                      },
                    ),
                ],
              ),
              body: isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : query.isEmpty
                      ? EmptyStateWidget(
                          title: isArabic ? 'بحث' : 'Search',
                          description: isArabic
                              ? 'ابحث في المحادثات باسم جهة الاتصال أو محتوى الرسائل.'
                              : 'Search for conversations by contact name or message, or search contacts.',
                          icon: Icons.search,
                        )
                      : (matchingConvs.isEmpty && contacts.isEmpty)
                          ? EmptyStateWidget(
                              title: isArabic ? 'لا توجد نتائج' : 'No Results',
                              description: isArabic
                                  ? 'لم يتم العثور على أي محادثات أو جهات اتصال مطابقة.'
                                  : 'No conversations or contacts match your query.',
                              icon: Icons.search_off,
                            )
                          : ListView(
                              children: [
                                if (matchingConvs.isNotEmpty) ...[
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                    child: Text(
                                      isArabic
                                          ? 'المحادثات (${matchingConvs.length})'
                                          : 'Conversations (${matchingConvs.length})',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textLightSecondary,
                                      ),
                                    ),
                                  ),
                                  ...matchingConvs.map(
                                    (conv) => ConversationTile(
                                      conversation: conv,
                                      onTap: () async {
                                        try {
                                          context.read<ConversationCubit>().markConversationAsRead(conv.id);
                                        } catch (_) {}
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ChatScreen(conversation: conv.copyWith(unreadCount: 0)),
                                          ),
                                        );
                                        if (context.mounted) {
                                          try {
                                            context.read<ConversationCubit>().markConversationAsRead(conv.id);
                                          } catch (_) {}
                                        }
                                      },
                                    ),
                                  ),
                                ],
                                if (contacts.isNotEmpty) ...[
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                    child: Text(
                                      isArabic
                                          ? 'جهات الاتصال (${contacts.length})'
                                          : 'Contacts (${contacts.length})',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textLightSecondary,
                                      ),
                                    ),
                                  ),
                                  ...contacts.map(
                                    (contact) => SearchContactTile(
                                      contact: contact,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ContactDetailsScreen(contact: contact),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
            );
          },
        );
      },
    );
  }
}
