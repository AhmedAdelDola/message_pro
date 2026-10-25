import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/contact.dart';
import '../../../data/models/conversation.dart';
import '../../../data/repositories/contact_repository.dart';
import '../../../providers/conversation_provider.dart';
import '../chat/chat_screen.dart';
import '../contacts/contact_details_screen.dart';
import '../inbox/widgets/conversation_tile.dart';
import '../../widgets/avatar_widget.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  List<Contact> _contacts = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _contacts = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await ContactRepository().searchContacts(query.trim());
      setState(() {
        _contacts = results;
        _isSearching = false;
      });
    } catch (_) {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final convState = ref.watch(conversationProvider);
    final query = _controller.text.trim().toLowerCase();

    final matchingConvs = query.isEmpty
        ? <Conversation>[]
        : convState.conversations.where((c) {
            return c.contact.name.toLowerCase().contains(query) ||
                (c.lastMessage?.content?.toLowerCase().contains(query) ?? false);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'بحث في المحادثات وجهات الاتصال...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
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
      body: query.isEmpty
          ? const Center(
              child: Text(
                'اكتب للبحث في الرسائل وجهات الاتصال...',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView(
              children: [
                if (matchingConvs.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'المحادثات المطابقة',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryLight),
                    ),
                  ),
                  ...matchingConvs.map((conv) => ConversationTile(
                        conversation: conv,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ChatScreen(conversation: conv)),
                          );
                        },
                      )),
                ],

                if (_contacts.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'جهات الاتصال المطابقة',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryLight),
                    ),
                  ),
                  ..._contacts.map((contact) => ListTile(
                        leading: AvatarWidget(
                          avatarUrl: contact.avatarUrl,
                          name: contact.name,
                          size: 40,
                        ),
                        title: Text(contact.name),
                        subtitle: Text(contact.phoneNumber ?? contact.email ?? ''),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ContactDetailsScreen(contact: contact)),
                          );
                        },
                      )),
                ],

                if (matchingConvs.isEmpty && _contacts.isEmpty && !_isSearching)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text('لا توجد نتائج مطابقة لبحثك', style: TextStyle(color: Colors.grey)),
                    ),
                  ),
              ],
            ),
    );
  }
}
