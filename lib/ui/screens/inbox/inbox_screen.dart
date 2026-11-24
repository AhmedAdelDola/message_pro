import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:message_pro/core/constants/app_colors.dart';
import 'package:message_pro/core/localization/app_localizations.dart';
import 'package:message_pro/data/models/conversation.dart';
import 'package:message_pro/logic/conversation/conversation_cubit.dart';
import 'package:message_pro/logic/conversation/conversation_state.dart';
import 'package:message_pro/ui/widgets/break_countdown_banner.dart';
import 'package:message_pro/ui/widgets/app_bar_progress_bar.dart';
import '../contacts/add_contact_screen.dart';
import 'widgets/inbox_screen_header.dart';
import 'widgets/inbox_filter_drawer.dart';
import 'widgets/filter_dropdown_modal.dart';
import 'widgets/workspaces_bottom_sheet.dart';
import 'widgets/conversation_action_sheet.dart';
import 'widgets/content/inbox_segment_tab_bar.dart';
import 'widgets/content/inbox_active_filter_bar.dart';
import 'widgets/content/inbox_conversations_list_view.dart';
import 'widgets/content/conversation_advanced_filters_sheet.dart';

/// Clean, decomposed Inbox Screen orchestrating header, active filter bar, segment tab bar, and conversations list.
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  String _activeSegment = 'all';
  String _selectedStatus = 'all';
  String _sortBy = 'newest';
  bool _unrepliedOnly = false;

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  List<Conversation> _searchResults = [];
  bool _isSearchingServer = false;

  String _activeKey = 'all';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<ConversationCubit>();
      if (cubit.state.conversations.isEmpty && !cubit.state.isLoading) {
        cubit.loadConversations();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      if (currentScroll >= (maxScroll - 250)) {
        context.read<ConversationCubit>().loadMoreConversations();
      }
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearchingServer = false;
      });
      return;
    }

    setState(() {});

    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _isSearchingServer = true);
      try {
        final res = await context.read<ConversationCubit>().searchConversations(
          trimmed,
        );
        if (mounted) {
          res.fold(
            (_) => setState(() => _isSearchingServer = false),
            (list) => setState(() {
              _searchResults = list;
              _isSearchingServer = false;
            }),
          );
        }
      } catch (_) {
        if (mounted) setState(() => _isSearchingServer = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSegmentChanged(String segment) {
    setState(() => _activeSegment = segment);
    final cubit = context.read<ConversationCubit>();
    if (segment == 'all') {
      cubit.selectDrawerFilter(assigneeType: 'all');
    } else if (segment == 'mine') {
      cubit.selectDrawerFilter(assigneeType: 'me');
    } else if (segment == 'unassigned') {
      cubit.selectDrawerFilter(assigneeType: 'unassigned');
    } else if (segment == 'collaborating') {
      cubit.selectDrawerFilter(assigneeType: 'collaborating');
    }
  }

  void _onSelectDrawerItem(String key, String label) {
    setState(() {
      _activeKey = key;
      if (key == 'all') _activeSegment = 'all';
      if (key == 'mine') _activeSegment = 'mine';
      if (key == 'unassigned') _activeSegment = 'unassigned';
      if (key == 'collaborating') _activeSegment = 'collaborating';
    });

    final cubit = context.read<ConversationCubit>();
    if (key == 'mine') {
      cubit.selectDrawerFilter(assigneeType: 'me');
    } else if (key == 'all') {
      cubit.selectDrawerFilter(assigneeType: 'all');
    } else if (key == 'unassigned') {
      cubit.selectDrawerFilter(assigneeType: 'unassigned');
    } else if (key == 'collaborating') {
      cubit.selectDrawerFilter(assigneeType: 'collaborating');
    } else if (key.startsWith('inbox_')) {
      final id = int.tryParse(key.replaceFirst('inbox_', ''));
      cubit.setInboxFilter(id);
    } else if (key.startsWith('label_')) {
      final lbl = key.replaceFirst('label_', '');
      cubit.setLabelFilter(lbl);
    } else if (key.startsWith('stage_')) {
      final id = int.tryParse(key.replaceFirst('stage_', ''));
      cubit.setLifecycleStageFilter(id);
    }

    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.of(context).pop();
    }
  }

  String _formatFilterDropdownLabel(BuildContext context) {
    final l10n = context.l10n;
    String statusStr = l10n.all;
    if (_selectedStatus == 'open') statusStr = l10n.open;
    if (_selectedStatus == 'closed' || _selectedStatus == 'resolved') {
      statusStr = l10n.closed;
    }
    if (_selectedStatus == 'snoozed') {
      statusStr = l10n.snoozed;
    }

    final sortStr = _sortBy == 'newest' ? l10n.newest : l10n.oldest;
    return l10n.isArabic ? '$statusStr، $sortStr' : '$statusStr, $sortStr';
  }

  void _showFilterDropdownModal() {
    FilterDropdownModal.show(
      context: context,
      selectedStatus: _selectedStatus,
      sortBy: _sortBy,
      onStatusChanged: (val) {
        setState(() {
          _selectedStatus = val;
          final cubitStatus = val == 'closed' ? 'resolved' : val;
          context.read<ConversationCubit>().setStatus(cubitStatus);
        });
      },
      onSortChanged: (val) => setState(() => _sortBy = val),
      onAdvancedFiltersTap: () {
        ConversationAdvancedFiltersSheet.show(
          context: context,
          activeKey: _activeKey,
          onSelectFilter: _onSelectDrawerItem,
        );
      },
    );
  }

  void _showActionSheet(Conversation conv) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final cubit = context.read<ConversationCubit>();

    ConversationActionSheet.show(
      context: context,
      conversation: conv,
      onToggleResolve: () async {
        final nextStatus = conv.status == 'resolved' ? 'open' : 'resolved';
        final res = await cubit.toggleConversationStatus(conv.id, nextStatus);
        if (mounted) {
          res.fold(
            (_) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isArabic
                      ? 'تعذر تحديث حالة المحادثة'
                      : 'Failed to update conversation status',
                ),
                backgroundColor: Colors.red,
              ),
            ),
            (_) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  nextStatus == 'resolved'
                      ? (isArabic
                            ? 'تم حل وإغلاق المحادثة'
                            : 'Conversation marked as resolved')
                      : (isArabic
                            ? 'تمت إعادة فتح المحادثة'
                            : 'Conversation reopened'),
                ),
                duration: const Duration(seconds: 2),
              ),
            ),
          );
        }
      },
      onSnooze: () async {
        final res = await cubit.toggleConversationStatus(conv.id, 'snoozed');
        if (mounted) {
          res.fold(
            (_) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isArabic
                      ? 'تعذر تأجيل المحادثة'
                      : 'Failed to snooze conversation',
                ),
                backgroundColor: Colors.red,
              ),
            ),
            (_) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isArabic ? 'تم تأجيل المحادثة' : 'Conversation snoozed',
                ),
                duration: const Duration(seconds: 2),
              ),
            ),
          );
        }
      },
      onToggleMute: () async {
        if (conv.muted) {
          await cubit.unmuteConversation(conv.id);
        } else {
          await cubit.muteConversation(conv.id);
        }
      },
      onTogglePin: () async {
        final nextPinned = !conv.isPinned;
        final res = await cubit.togglePinConversation(conv.id);
        if (mounted) {
          res.fold(
            (_) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isArabic
                      ? 'تعذر تثبيت/إلغاء تثبيت المحادثة'
                      : 'Failed to pin/unpin conversation',
                ),
                backgroundColor: Colors.red,
              ),
            ),
            (_) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  nextPinned
                      ? (isArabic
                            ? 'تم تثبيت المحادثة في الأعلى'
                            : 'Conversation pinned to top')
                      : (isArabic
                            ? 'تم إلغاء تثبيت المحادثة'
                            : 'Conversation unpinned'),
                ),
                duration: const Duration(seconds: 2),
              ),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final bgColor = isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final textPrimary = isDark
        ? AppColors.textLightPrimary
        : AppColors.textDarkPrimary;
    final textSecondary = isDark
        ? AppColors.textLightSecondary
        : AppColors.textDarkSecondary;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const InboxFilterDrawer(),
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            InboxScreenHeader(
              isSearching: _isSearching,
              searchController: _searchController,
              onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
              onWorkspacesTap: () {
                WorkspacesBottomSheet.show(
                  context,
                  onWorkspaceSwitched: () {
                    setState(() {
                      _activeSegment = 'all';
                      _activeKey = 'all';
                      _selectedStatus = 'all';
                    });
                  },
                );
              },
              onAddContactTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddContactScreen()),
                );
              },
              onStartSearch: () => setState(() => _isSearching = true),
              onCloseSearch: () {
                _searchDebounce?.cancel();
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  _searchResults = [];
                  _isSearchingServer = false;
                });
              },
              onSearchChanged: _onSearchChanged,
              onClearSearch: () {
                _searchController.clear();
                _searchDebounce?.cancel();
                setState(() {
                  _searchResults = [];
                  _isSearchingServer = false;
                });
              },
            ),

            const BreakCountdownBanner(),

            if (!_isSearching)
              InboxActiveFilterBar(isDark: isDark, isArabic: isArabic),

            if (!_isSearching)
              InboxSegmentTabBar(
                activeSegment: _activeSegment,
                onSegmentChanged: _onSegmentChanged,
                isDark: isDark,
                isArabic: isArabic,
              ),

            // Secondary Filter Row
            if (!_isSearching)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: _showFilterDropdownModal,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            Text(
                              _formatFilterDropdownLabel(context),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: _unrepliedOnly,
                            activeThumbColor: AppColors.primary,
                            onChanged: (val) =>
                                setState(() => _unrepliedOnly = val),
                          ),
                        ),
                        Text(
                          context.l10n.unreplied,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Live progress bar directly above conversations
            LinearHeaderLoader(
              isLoading:
                  context.watch<ConversationCubit>().state.isLoading ||
                  context.watch<ConversationCubit>().state.isLoadingMore ||
                  _isSearchingServer,
            ),

            // Conversations List View
            Expanded(
              child: BlocBuilder<ConversationCubit, ConversationState>(
                builder: (context, state) {
                  final cubit = context.read<ConversationCubit>();
                  var conversations = cubit.filteredConversations;

                  if (_unrepliedOnly) {
                    conversations = conversations
                        .where((c) => c.unreadCount > 0)
                        .toList();
                  }

                  final isAllTab =
                      _activeSegment == 'all' || state.assigneeType == 'all';
                  conversations = List<Conversation>.from(conversations);
                  conversations.sort((a, b) {
                    if (isAllTab && a.isPinned != b.isPinned) {
                      return a.isPinned ? -1 : 1;
                    }
                    if (_sortBy == 'oldest') {
                      return a.updatedAt.compareTo(b.updatedAt);
                    }
                    return b.updatedAt.compareTo(a.updatedAt);
                  });

                  if (_isSearching &&
                      _searchController.text.trim().isNotEmpty) {
                    final query = _searchController.text.toLowerCase().trim();
                    final Map<int, Conversation> combined = {};
                    for (final c in _searchResults) {
                      combined[c.id] = c;
                    }
                    for (final c in conversations) {
                      combined[c.id] = c;
                    }
                    conversations = combined.values.where((c) {
                      final name = c.contact.name.toLowerCase();
                      final snippet = (c.lastMessage?.content ?? '')
                          .toLowerCase();
                      final email = (c.contact.email ?? '').toLowerCase();
                      final phone = (c.contact.phoneNumber ?? '').toLowerCase();
                      return name.contains(query) ||
                          snippet.contains(query) ||
                          email.contains(query) ||
                          phone.contains(query);
                    }).toList();
                  }

                  return InboxConversationsListView(
                    conversations: conversations,
                    scrollController: _scrollController,
                    onRefresh: () => cubit.loadConversations(),
                    onLongPress: _showActionSheet,
                    isLoading: state.isLoading,
                    isLoadingMore: state.isLoadingMore,
                    errorMessage: state.errorMessage,
                    onRetry: () => cubit.loadConversations(),
                    isSearching: _isSearching,
                    searchQuery: _searchController.text.trim(),
                    isDark: isDark,
                    isArabic: isArabic,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
