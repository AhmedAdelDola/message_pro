import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection_container.dart';
import '../../../data/models/contact.dart';
import '../../../data/models/conversation.dart';
import '../../../data/repositories/contact_repository.dart';
import '../../../logic/conversation/conversation_cubit.dart';
import '../../../logic/conversation/conversation_state.dart';
import '../chat/chat_screen.dart';
import '../contacts/contact_details_screen.dart';
import '../inbox/widgets/conversation_tile.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/empty_state_widget.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
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
    final result = await sl<IContactRepository>().searchContacts(query.trim());
    if (!mounted) return;

    result.fold(
      (failure) => setState(() => _isSearching = false),
      (results) => setState(() {
        _contacts = results;
        _isSearching = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConversationCubit, ConversationState>(
      builder: (context, convState) {
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
              style: TextStyle(fontSize: 15.sp),
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
                  icon: Icon(Icons.clear, size: 20.r),
                  onPressed: () {
                    _controller.clear();
                    _onSearchChanged('');
                  },
                ),
            ],
          ),
          body: query.isEmpty
              ? const EmptyStateWidget(
                  lottieAsset: 'assets/animations/empty_search.json',
                  title: 'البحث الموحد',
                  description: 'اكتب للبحث السريع في المحادثات وجهات الاتصال',
                )
              : ListView(
                  children: [
                    if (matchingConvs.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                        child: Text(
                          'المحادثات المطابقة',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, color: AppColors.primaryLight),
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
                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                        child: Text(
                          'جهات الاتصال المطابقة',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, color: AppColors.primaryLight),
                        ),
                      ),
                      ..._contacts.map((contact) => ListTile(
                            leading: AvatarWidget(
                              avatarUrl: contact.avatarUrl,
                              name: contact.name,
                              size: 40,
                            ),
                            title: Text(contact.name, style: TextStyle(fontSize: 14.sp)),
                            subtitle: Text(contact.phoneNumber ?? contact.email ?? '', style: TextStyle(fontSize: 12.sp)),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => ContactDetailsScreen(contact: contact)),
                              );
                            },
                          )),
                    ],

                    if (matchingConvs.isEmpty && _contacts.isEmpty && !_isSearching)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: EmptyStateWidget(
                          lottieAsset: 'assets/animations/empty_search.json',
                          title: 'لا توجد نتائج مطابقة',
                          description: 'تأكد من كتابة الاسم أو رقم الهاتف بدقة',
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}
