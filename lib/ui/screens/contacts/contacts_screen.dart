import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection_container.dart';
import '../../../logic/contacts/contacts_cubit.dart';
import '../../../logic/contacts/contacts_state.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/app_bar_progress_bar.dart';
import '../../widgets/empty_state_widget.dart';
import 'add_contact_screen.dart';
import 'contact_details_screen.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      context.read<ContactsCubit>();
      return const _ContactsScreenContent();
    } catch (_) {
      return BlocProvider<ContactsCubit>(
        create: (_) => sl<ContactsCubit>()..fetchContacts(),
        child: const _ContactsScreenContent(),
      );
    }
  }
}

class _ContactsScreenContent extends StatefulWidget {
  const _ContactsScreenContent();

  @override
  State<_ContactsScreenContent> createState() => _ContactsScreenContentState();
}

class _ContactsScreenContentState extends State<_ContactsScreenContent> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final cubit = context.read<ContactsCubit>();
        if (cubit.state.status == ContactsStatus.initial) {
          cubit.fetchContacts();
        }
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<ContactsCubit>().loadMore();
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        context.read<ContactsCubit>().search(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return BlocBuilder<ContactsCubit, ContactsState>(
      builder: (context, state) {
        final isLoading = state.status == ContactsStatus.loading;
        final contacts = state.contacts;
        final hasMore = state.hasMore;

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
                      Text(
                        isArabic ? 'جهات الاتصال' : 'Contacts',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
                          if (created == true && context.mounted) {
                            context.read<ContactsCubit>().fetchContacts(refresh: true);
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // Global sleek blue linear progress indicator
                LinearHeaderLoader(isLoading: isLoading),

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
                            ),
                            decoration: InputDecoration(
                              hintText: isArabic
                                  ? 'بحث بالاسم، البريد أو الهاتف...'
                                  : 'Search by name, email, or phone...',
                              hintStyle: TextStyle(
                                color: textSecondary,
                                fontSize: 13,
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
                  child: (isLoading && contacts.isEmpty)
                      ? const SizedBox.shrink()
                      : contacts.isEmpty
                          ? EmptyStateWidget(
                              lottieAsset: 'assets/animations/empty_search.json',
                              title: isArabic ? 'لا توجد جهات اتصال' : 'No contacts found',
                              description: isArabic
                                  ? 'يمكنك إضافة جهات اتصال جديدة أو تحديث القائمة'
                                  : 'Add new contacts or pull to refresh',
                              buttonText: isArabic ? 'إضافة جهة اتصال' : 'Add Contact',
                              onButtonPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const AddContactScreen()),
                                ).then((added) {
                                  if (added == true && context.mounted) {
                                    context.read<ContactsCubit>().fetchContacts(refresh: true);
                                  }
                                });
                              },
                            )
                          : RefreshIndicator(
                              color: const Color(0xFF4162E3),
                              onRefresh: () => context.read<ContactsCubit>().fetchContacts(refresh: true),
                              child: ListView.separated(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                itemCount: contacts.length + (hasMore ? 1 : 0),
                                separatorBuilder: (_, __) => Divider(
                                  color: borderColor,
                                  height: 1,
                                  indent: 72,
                                ),
                                itemBuilder: (context, index) {
                                  if (index >= contacts.length) {
                                    return state.isLoadingMore
                                        ? const Center(
                                            child: Padding(
                                              padding: EdgeInsets.all(16),
                                              child: SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              ),
                                            ),
                                          )
                                        : const SizedBox(height: 16);
                                  }

                                  final contact = contacts[index];
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
                                          builder: (_) => ContactDetailsScreen(
                                            contact: contact,
                                            onContactUpdated: (updated) {
                                              context.read<ContactsCubit>().updateContactLocally(updated);
                                            },
                                          ),
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
      },
    );
  }
}
