import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection_container.dart';
import '../../../data/models/contact.dart';
import '../../../data/repositories/contact_repository.dart';
import '../../widgets/avatar_widget.dart';
import 'add_contact_screen.dart';
import 'contact_details_screen.dart';
import '../../widgets/app_bar_progress_bar.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Contact> _contacts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String _searchQuery = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _fetchContacts(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isLoadingMore &&
        _hasMore) {
      _fetchContacts(page: _currentPage + 1);
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      setState(() {
        _searchQuery = query.trim();
      });
      _fetchContacts(refresh: true);
    });
  }

  Future<void> _fetchContacts({bool refresh = false, int page = 1}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _hasMore = true;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final repo = sl<IContactRepository>();
      final result = _searchQuery.isEmpty
          ? await repo.getContacts(page: page, perPage: 25)
          : await repo.searchContacts(_searchQuery, page: page);

      result.fold(
        (failure) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isLoadingMore = false;
            });
          }
        },
        (data) {
          if (mounted) {
            setState(() {
              if (refresh) {
                _contacts.clear();
              }
              _contacts.addAll(data);
              _currentPage = page;
              _hasMore = data.length >= 25;
              _isLoading = false;
              _isLoadingMore = false;
            });
          }
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar Header
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        isArabic ? 'جهات الاتصال' : 'Contacts',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Gontserrat',
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedUserAdd01,
                      color: textPrimary,
                      size: 21,
                    ),
                    onPressed: () async {
                      final created = await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddContactScreen()),
                      );
                      if (created == true) {
                        _fetchContacts(refresh: true);
                      }
                    },
                  ),
                ],
              ),
            ),

            // Global sleek blue linear progress indicator
            LinearHeaderLoader(isLoading: _isLoading),

            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor, width: 0.8)),
              ),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : const Color(0xFFF1F2F4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedSearch01,
                      color: textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 13.5,
                          fontFamily: 'Gontserrat',
                        ),
                        decoration: InputDecoration(
                          hintText: isArabic ? 'بحث بالاسم، البريد أو الهاتف...' : 'Search by name, email, or phone...',
                          hintStyle: TextStyle(
                            color: textSecondary,
                            fontSize: 13,
                            fontFamily: 'Gontserrat',
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                        child: Icon(Icons.close_rounded, size: 18, color: textSecondary),
                      ),
                  ],
                ),
              ),
            ),

            // Contacts List
            Expanded(
              child: (_isLoading && _contacts.isEmpty)
                  ? const SizedBox.shrink()
                  : _contacts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedUserGroup,
                                color: textSecondary.withValues(alpha: 0.5),
                                size: 52,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                isArabic ? 'لا توجد جهات اتصال' : 'No contacts found',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Gontserrat',
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: const Color(0xFF4162E3),
                          onRefresh: () => _fetchContacts(refresh: true),
                          child: ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _contacts.length + (_hasMore ? 1 : 0),
                            separatorBuilder: (_, __) => Divider(
                              color: borderColor,
                              height: 1,
                              indent: 72,
                            ),
                            itemBuilder: (context, index) {
                              if (index >= _contacts.length) {
                                return const SizedBox(height: 16);
                              }

                              final contact = _contacts[index];
                              final subtitle = contact.phoneNumber?.isNotEmpty == true
                                  ? contact.phoneNumber!
                                  : (contact.email?.isNotEmpty == true
                                      ? contact.email!
                                      : (contact.identifier?.isNotEmpty == true
                                          ? contact.identifier!
                                          : '#${contact.id}'));

                              return InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ContactDetailsScreen(contact: contact),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      AvatarWidget(
                                        avatarUrl: contact.avatarUrl,
                                        name: contact.name,
                                        size: 44,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              contact.name,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: textPrimary,
                                                fontFamily: 'Gontserrat',
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              subtitle,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: textSecondary,
                                                fontFamily: 'Gontserrat',
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        size: 20,
                                        color: textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
