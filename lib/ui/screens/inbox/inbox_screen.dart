import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/conversation.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/conversation_repository.dart';
import '../../../core/di/injection_container.dart';
import '../../../logic/auth/auth_cubit.dart';
import '../../../logic/auth/auth_state.dart';
import '../../../logic/conversation/conversation_cubit.dart';
import '../../../logic/conversation/conversation_state.dart';
import '../chat/chat_screen.dart';
import '../contacts/add_contact_screen.dart';
import 'widgets/conversation_tile.dart';
import '../../widgets/app_bar_progress_bar.dart';
import '../../widgets/break_countdown_banner.dart';
import '../chat/widgets/start_direct_chat_sheet.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  // Primary Segment: 'all', 'mine', 'collaborating', 'unassigned'
  String _activeSegment = 'all';

  // Status Filter: 'all', 'open', 'closed', 'snoozed'
  String _selectedStatus = 'all';

  // Sort: 'newest', 'oldest'
  String _sortBy = 'newest';

  // Unreplied toggle
  bool _unrepliedOnly = false;

  // Search state
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  List<Conversation> _searchResults = [];
  bool _isSearchingServer = false;

  // Drawer selected key
  String _activeKey = 'all';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<ConversationCubit>();
      cubit.loadAuxiliaryData();
      cubit.setAssigneeType('all');
      cubit.setStatus('all');
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
      final res = await sl<IConversationRepository>().searchConversations(trimmed);
      if (mounted) {
        res.fold(
          (_) => setState(() => _isSearchingServer = false),
          (list) => setState(() {
            _searchResults = list;
            _isSearchingServer = false;
          }),
        );
      }
    });
  }

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

  String _formatFilterDropdownLabel() {
    String statusStr = 'All';
    if (_selectedStatus == 'open') statusStr = 'Open';
    if (_selectedStatus == 'closed' || _selectedStatus == 'resolved') statusStr = 'Closed';
    if (_selectedStatus == 'snoozed') statusStr = 'Snoozed';

    String sortStr = _sortBy == 'newest' ? 'Newest' : 'Oldest';
    return '$statusStr, $sortStr';
  }

  // Status & Sort Modal matching browser screenshot 85
  void _showFilterDropdownModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return Dialog(
              backgroundColor: cardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Show
                    Text(
                      'Show',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textSecondary,
                        fontFamily: 'Gontserrat',
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildRadioRow(
                      label: 'All conversations',
                      value: 'all',
                      groupValue: _selectedStatus,
                      onChanged: (val) {
                        setDialogState(() => _selectedStatus = val!);
                        setState(() {
                          _selectedStatus = val!;
                          context.read<ConversationCubit>().setStatus('all');
                        });
                      },
                      textPrimary: textPrimary,
                    ),
                    _buildRadioRow(
                      label: 'Open conversations',
                      value: 'open',
                      groupValue: _selectedStatus,
                      onChanged: (val) {
                        setDialogState(() => _selectedStatus = val!);
                        setState(() {
                          _selectedStatus = val!;
                          context.read<ConversationCubit>().setStatus('open');
                        });
                      },
                      textPrimary: textPrimary,
                    ),
                    _buildRadioRow(
                      label: 'Closed conversations',
                      value: 'closed',
                      groupValue: _selectedStatus,
                      onChanged: (val) {
                        setDialogState(() => _selectedStatus = val!);
                        setState(() {
                          _selectedStatus = val!;
                          context.read<ConversationCubit>().setStatus('resolved');
                        });
                      },
                      textPrimary: textPrimary,
                    ),
                    _buildRadioRow(
                      label: 'Snoozed conversations',
                      value: 'snoozed',
                      groupValue: _selectedStatus,
                      onChanged: (val) {
                        setDialogState(() => _selectedStatus = val!);
                        setState(() {
                          _selectedStatus = val!;
                          context.read<ConversationCubit>().setStatus('snoozed');
                        });
                      },
                      textPrimary: textPrimary,
                    ),

                    const SizedBox(height: 14),

                    // Section 2: Sort by
                    Text(
                      'Sort by',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textSecondary,
                        fontFamily: 'Gontserrat',
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildRadioRow(
                      label: 'Newest',
                      value: 'newest',
                      groupValue: _sortBy,
                      onChanged: (val) {
                        setDialogState(() => _sortBy = val!);
                        setState(() => _sortBy = val!);
                      },
                      textPrimary: textPrimary,
                    ),
                    _buildRadioRow(
                      label: 'Oldest',
                      value: 'oldest',
                      groupValue: _sortBy,
                      onChanged: (val) {
                        setDialogState(() => _sortBy = val!);
                        setState(() => _sortBy = val!);
                      },
                      textPrimary: textPrimary,
                    ),

                    const SizedBox(height: 14),

                    // Section 3: Advanced filters link
                    InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _showAdvancedFiltersBottomSheet();
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Advanced filters',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Gontserrat',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRadioRow({
    required String label,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
    required Color textPrimary,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFF94A3B8),
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontFamily: 'Gontserrat',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActionSheet(Conversation conv) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              // Resolve / Reopen
              _buildActionRow(
                icon: Icon(
                  Icons.check_circle_outline_rounded,
                  color: conv.status == 'resolved' ? AppColors.success : textPrimary,
                ),
                label: conv.status == 'resolved'
                    ? (isArabic ? 'إعادة فتح المحادثة' : 'Reopen Conversation')
                    : (isArabic ? 'إغلاق المحادثة' : 'Close Conversation'),
                textColor: conv.status == 'resolved' ? AppColors.success : textPrimary,
                borderColor: borderColor,
                onTap: () async {
                  Navigator.pop(ctx);
                  final nextStatus = conv.status == 'resolved' ? 'open' : 'resolved';
                  await sl<IConversationRepository>().toggleStatus(conv.id, nextStatus);
                  if (mounted) context.read<ConversationCubit>().loadConversations();
                },
              ),
              // Snooze
              _buildActionRow(
                icon: Icon(Icons.access_time_rounded, color: textPrimary),
                label: isArabic ? 'تأجيل المحادثة' : 'Snooze Conversation',
                textColor: textPrimary,
                borderColor: borderColor,
                onTap: () async {
                  Navigator.pop(ctx);
                  await sl<IConversationRepository>().toggleStatus(conv.id, 'snoozed');
                  if (mounted) context.read<ConversationCubit>().loadConversations();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionRow({
    required Widget icon,
    required String label,
    required Color textColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: borderColor, width: 1)),
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gontserrat',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final segmentContainerBg = isDark ? const Color(0xFF1E2024) : const Color(0xFFF1F2F4);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header or Active Search Bar
            if (_isSearching)
              _buildSearchHeader(isDark, isArabic, textPrimary, textSecondary, borderColor)
            else
              _buildMainHeader(isDark, textPrimary),

            // Global sleek blue linear progress indicator
            const BreakCountdownBanner(),
            LinearHeaderLoader(
              isLoading: context.watch<ConversationCubit>().state.isLoading,
            ),

            // Segmented Primary Filter Tabs: All | Mine | Collaborating | Unassigned
            if (!_isSearching)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: segmentContainerBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildSegmentTab('all', 'All', isDark),
                    _buildSegmentTab('mine', 'Mine', isDark),
                    _buildSegmentTab('collaborating', 'Collaborating', isDark),
                    _buildSegmentTab('unassigned', 'Unassigned', isDark),
                  ],
                ),
              ),

            // Secondary Filter Row: "Open, Newest ⌄" & "Unreplied" Toggle
            if (!_isSearching)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status & Sort Dropdown Button
                    InkWell(
                      onTap: _showFilterDropdownModal,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                        child: Row(
                          children: [
                            Text(
                              _formatFilterDropdownLabel(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                                fontFamily: 'Gontserrat',
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: textSecondary),
                          ],
                        ),
                      ),
                    ),

                    // Unreplied Toggle Switch
                    Row(
                      children: [
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: _unrepliedOnly,
                            activeThumbColor: AppColors.primary,
                            onChanged: (val) => setState(() => _unrepliedOnly = val),
                          ),
                        ),
                        Text(
                          'Unreplied',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                            fontFamily: 'Gontserrat',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Conversation List
            Expanded(
              child: BlocBuilder<ConversationCubit, ConversationState>(
                builder: (context, state) {
                  final cubit = context.read<ConversationCubit>();
                  var conversations = cubit.filteredConversations;

                  // Filter by Unreplied toggle
                  if (_unrepliedOnly) {
                    conversations = conversations.where((c) => c.unreadCount > 0).toList();
                  }

                  // Sort
                  if (_sortBy == 'oldest') {
                    conversations = List<Conversation>.from(conversations);
                    conversations.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
                  }

                  // Apply search filter if searching
                  if (_isSearching && _searchController.text.trim().isNotEmpty) {
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
                      final snippet = (c.lastMessage?.content ?? '').toLowerCase();
                      final email = (c.contact.email ?? '').toLowerCase();
                      final phone = (c.contact.phoneNumber ?? '').toLowerCase();
                      return name.contains(query) || snippet.contains(query) || email.contains(query) || phone.contains(query);
                    }).toList();
                  }

                  if (state.isLoading && conversations.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    );
                  }

                  if (state.errorMessage != null && conversations.isEmpty) {
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
                              isArabic ? 'حدث خطأ أثناء تحميل المحادثات' : 'Error loading conversations',
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                fontFamily: 'Gontserrat',
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => cubit.loadConversations(),
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
                    final searchQuery = _searchController.text.trim();
                    final isPhoneQuery = _isSearching && _looksLikePhoneNumber(searchQuery);

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
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
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
                                  isArabic ? 'لا توجد محادثة سابقة مع هذا الرقم' : 'No existing chat with this number',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 13,
                                    fontFamily: 'Gontserrat',
                                  ),
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
                                      fontFamily: 'Gontserrat',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      StartDirectChatSheet.show(context, initialPhone: cleanNumber);
                                    },
                                    icon: const Icon(Icons.add_comment_rounded, size: 18),
                                    label: Text(
                                      isArabic ? 'بدء محادثة جديدة مع الرقم' : 'Start chat with this number',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 52,
                              color: isDark ? const Color(0xFF80838D) : const Color(0xFFB0B4BA),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isArabic ? 'لا توجد محادثات لعرضها' : 'No conversations to show',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                fontFamily: 'Gontserrat',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final searchQuery = _searchController.text.trim();
                  final isPhoneQuery = _isSearching && _looksLikePhoneNumber(searchQuery);
                  final cleanSearchNumber = isPhoneQuery ? _cleanSearchPhoneNumber(searchQuery) : '';
                  final hasExactMatch = isPhoneQuery && conversations.any((c) {
                    final cPhone = (c.contact.phoneNumber ?? '').replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
                    final sPhone = cleanSearchNumber.replaceAll('+', '');
                    return cPhone.isNotEmpty && (cPhone.endsWith(sPhone) || sPhone.endsWith(cPhone));
                  });
                  final showStartChatBanner = isPhoneQuery && !hasExactMatch;

                  final extraBannerCount = showStartChatBanner ? 1 : 0;
                  final totalItemCount = conversations.length + extraBannerCount + (state.isLoadingMore ? 1 : 0);

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => cubit.loadConversations(),
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: totalItemCount,
                      itemBuilder: (context, index) {
                        if (showStartChatBanner && index == 0) {
                          return InkWell(
                            onTap: () {
                              StartDirectChatSheet.show(context, initialPhone: cleanSearchNumber);
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
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
                                    child: const Icon(Icons.add_comment_rounded, color: Colors.white, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isArabic ? 'بدء محادثة جديدة' : 'Start new conversation',
                                          style: TextStyle(
                                            color: textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            fontFamily: 'Gontserrat',
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Directionality(
                                          textDirection: TextDirection.ltr,
                                          child: Text(
                                            isArabic ? 'فتح محادثة مع $searchQuery' : 'Open chat with $searchQuery',
                                            style: TextStyle(
                                              color: textSecondary,
                                              fontSize: 12,
                                              fontFamily: 'Gontserrat',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    isArabic ? Icons.arrow_back_ios_new_rounded : Icons.arrow_forward_ios_rounded,
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
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                ),
                              ),
                            ),
                          );
                        }
                        final conv = conversations[effectiveIndex];
                        return ConversationTile(
                          key: ValueKey(conv.id),
                          conversation: conv,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(conversation: conv),
                              ),
                            );
                          },
                          onLongPress: () => _showActionSheet(conv),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Chats Tab Header matching browser Tab 1
  Widget _buildMainHeader(bool isDark, Color textPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Workspace Square Button (matching Image 3 & web navbar exactly)
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, authState) {
                  final user = authState is Authenticated ? authState.user : null;
                  final activeAccount = user != null && user.accounts.isNotEmpty
                      ? user.accounts.firstWhere(
                          (a) => a.id == user.accountId,
                          orElse: () => user.accounts.first,
                        )
                      : null;
                  final initial = (activeAccount?.name.trim().isNotEmpty == true)
                      ? activeAccount!.name.trim()[0].toUpperCase()
                      : 'E';

                  return Tooltip(
                    message: activeAccount?.name ?? 'Workspace',
                    child: InkWell(
                      onTap: () => _showWorkspacesBottomSheet(context),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1F24) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF3B82F6), width: 1.6),
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3B82F6),
                            fontFamily: 'Gontserrat',
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              // "Chats" tab with active blue underline indicator
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chats',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                      fontFamily: 'Gontserrat',
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    width: 44,
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: HugeIcon(icon: HugeIcons.strokeRoundedUserAdd01, color: textPrimary, size: 21),
                tooltip: 'New Contact',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddContactScreen()),
                  );
                },
              ),
              IconButton(
                icon: HugeIcon(icon: HugeIcons.strokeRoundedSearch01, color: textPrimary, size: 21),
                tooltip: 'Search',
                onPressed: () => setState(() => _isSearching = true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Search input header matching browser screenshot 309
  Widget _buildSearchHeader(
    bool isDark,
    bool isArabic,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
  ) {
    final inputBg = isDark ? AppColors.darkSurface : const Color(0xFFF1F2F4);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  HugeIcon(icon: HugeIcons.strokeRoundedSearch01, color: textSecondary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontFamily: 'Gontserrat',
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search conversations...',
                        hintStyle: TextStyle(
                          color: textSecondary.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontFamily: 'Gontserrat',
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  if (_isSearchingServer) ...[
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (_searchController.text.isNotEmpty)
                    InkWell(
                      onTap: () {
                        _searchController.clear();
                        _searchDebounce?.cancel();
                        setState(() {
                          _searchResults = [];
                          _isSearchingServer = false;
                        });
                      },
                      child: Icon(Icons.close_rounded, size: 18, color: textSecondary),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.close_rounded, color: textPrimary, size: 22),
            onPressed: () {
              _searchDebounce?.cancel();
              setState(() {
                _isSearching = false;
                _searchController.clear();
                _searchResults = [];
                _isSearchingServer = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentTab(String key, String label, bool isDark) {
    final isSelected = _activeSegment == key;
    return Expanded(
      child: InkWell(
        onTap: () => _onSegmentChanged(key),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF2C2E33) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontFamily: 'Gontserrat',
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary),
            ),
          ),
        ),
      ),
    );
  }

  void _showWorkspacesBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final cardBg = isDark ? const Color(0xFF161616) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF0D0D0D);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB);

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            final user = authState is Authenticated ? authState.user : null;
            final accounts = user?.accounts ?? [];
            final currentAccountId = user?.accountId;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag Handle Pill
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),

                    // Header row: Title + Subtitle + Close icon
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4162E3).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.business_rounded,
                            color: Color(0xFF4162E3),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isArabic ? 'مساحات العمل' : 'Workspaces',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                  fontFamily: 'Gontserrat',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isArabic
                                    ? 'اختر مساحة العمل التي ترغب بالتبديل إليها'
                                    : 'Select the workspace you want to switch to',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                  fontFamily: 'Gontserrat',
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          color: textSecondary,
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    if (accounts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            isArabic ? 'لا توجد مساحات عمل إضافية' : 'No workspaces available',
                            style: TextStyle(color: textSecondary, fontSize: 13.5),
                          ),
                        ),
                      )
                    else
                      Builder(
                        builder: (_) {
                          final hasExplicitOrg = accounts.any((a) =>
                              (a.organizationName != null && a.organizationName!.trim().isNotEmpty) ||
                              [' - ', ' | ', ' / ', ' : ', ' — '].any((sep) => a.name.contains(sep)));

                          final defaultOrgName = hasExplicitOrg
                              ? (isArabic ? 'مساحات عمل أخرى' : 'Other Workspaces')
                              : (isArabic ? 'المؤسسة الرئيسية' : 'Main Organization');

                          final Map<String, List<Account>> groupedAccounts = {};
                          for (final account in accounts) {
                            final org = account.getEffectiveOrgName(defaultOrgName);
                            groupedAccounts.putIfAbsent(org, () => []).add(account);
                          }

                          return ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: MediaQuery.of(context).size.height * 0.6,
                            ),
                            child: ListView(
                              shrinkWrap: true,
                              children: [
                                for (final entry in groupedAccounts.entries) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10, bottom: 8),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF4162E3).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Icon(
                                            Icons.domain_rounded,
                                            size: 14,
                                            color: Color(0xFF4162E3),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            entry.key,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: textPrimary,
                                              fontFamily: 'Gontserrat',
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF262626) : const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${entry.value.length} ${isArabic ? (entry.value.length == 1 ? 'مساحة' : 'مساحات') : (entry.value.length == 1 ? 'workspace' : 'workspaces')}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: textSecondary,
                                              fontFamily: 'Gontserrat',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  for (final account in entry.value) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: InkWell(
                                        onTap: () async {
                                          final isActive = account.id == currentAccountId;
                                          if (!isActive) {
                                            Navigator.pop(sheetCtx);
                                            setState(() {
                                              _activeSegment = 'all';
                                              _activeKey = 'all';
                                              _selectedStatus = 'all';
                                            });
                                            await context.read<AuthCubit>().switchAccount(account.id);
                                            if (!context.mounted) return;
                                            await context.read<ConversationCubit>().onWorkspaceSwitched(account.id);
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  isArabic
                                                      ? 'تم التبديل إلى ${account.name}'
                                                      : 'Switched to ${account.name}',
                                                ),
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                          } else {
                                            Navigator.pop(sheetCtx);
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: (account.id == currentAccountId)
                                                ? (isDark
                                                    ? const Color(0xFF131D2D)
                                                    : const Color(0xFFEFF6FF))
                                                : (isDark
                                                    ? const Color(0xFF1E1F24)
                                                    : const Color(0xFFF9FAFB)),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: (account.id == currentAccountId)
                                                  ? const Color(0xFF4162E3)
                                                  : borderColor,
                                              width: (account.id == currentAccountId) ? 1.5 : 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              // Workspace Square with border matching image
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? const Color(0xFF131D2D)
                                                      : ((account.id == currentAccountId)
                                                          ? Colors.white
                                                          : const Color(0xFFEFF6FF)),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: const Color(0xFF4162E3),
                                                    width: 1.5,
                                                  ),
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  account.name.trim().isNotEmpty
                                                      ? account.name.trim()[0].toUpperCase()
                                                      : 'E',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF4162E3),
                                                    fontFamily: 'Gontserrat',
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      account.name,
                                                      style: TextStyle(
                                                        fontSize: 14.5,
                                                        fontWeight: (account.id == currentAccountId)
                                                            ? FontWeight.bold
                                                            : FontWeight.w600,
                                                        color: (account.id == currentAccountId)
                                                            ? const Color(0xFF4162E3)
                                                            : textPrimary,
                                                        fontFamily: 'Gontserrat',
                                                      ),
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          '#${account.id}',
                                                          style: TextStyle(
                                                            fontSize: 11.5,
                                                            color: textSecondary,
                                                            fontFamily: 'Gontserrat',
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                              horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: (isDark
                                                                ? Colors.white10
                                                                : Colors.black.withValues(alpha: 0.05)),
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: Text(
                                                            account.role.toUpperCase(),
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.w600,
                                                              color: textSecondary,
                                                              fontFamily: 'Gontserrat',
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (account.id == currentAccountId)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF4162E3)
                                                        .withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.check_circle_rounded,
                                                        size: 14,
                                                        color: Color(0xFF4162E3),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        isArabic ? 'الحالية' : 'Active',
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                          color: Color(0xFF4162E3),
                                                          fontFamily: 'Gontserrat',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              else
                                                Icon(
                                                  isArabic
                                                      ? Icons.keyboard_arrow_left_rounded
                                                      : Icons.keyboard_arrow_right_rounded,
                                                  color: textSecondary,
                                                  size: 20,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAdvancedFiltersBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final cardBg = isDark ? const Color(0xFF161616) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF0D0D0D);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final dividerColor = isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB);

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: BlocBuilder<ConversationCubit, ConversationState>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          isArabic ? 'تصفية متقدمة' : 'Advanced Filters',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                            fontFamily: 'Gontserrat',
                          ),
                        ),
                        const Spacer(),
                        if (_activeKey != 'all')
                          TextButton(
                            onPressed: () {
                              _onSelectDrawerItem('all', 'All');
                              Navigator.pop(sheetCtx);
                            },
                            child: Text(
                              isArabic ? 'إعادة ضبط' : 'Reset',
                              style: const TextStyle(color: AppColors.primary),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          color: textSecondary,
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.55,
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          if (state.lifecycleStages.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              child: Text(
                                isArabic ? 'مراحل العميل' : 'Lifecycle Stages',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: textSecondary,
                                  fontFamily: 'Gontserrat',
                                ),
                              ),
                            ),
                            ...state.lifecycleStages.map((stage) {
                              final sKey = 'stage_${stage.id}';
                              final isSelected = _activeKey == sKey;
                              return ListTile(
                                dense: true,
                                leading: Text(stage.icon ?? '🌱', style: const TextStyle(fontSize: 16)),
                                title: Text(stage.name, style: TextStyle(color: textPrimary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                trailing: isSelected ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 18) : null,
                                onTap: () {
                                  _onSelectDrawerItem(sKey, stage.name);
                                  Navigator.pop(sheetCtx);
                                },
                              );
                            }),
                            Divider(color: dividerColor, height: 20),
                          ],
                          if (state.labels.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              child: Text(
                                isArabic ? 'التصنيفات' : 'Labels',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: textSecondary,
                                  fontFamily: 'Gontserrat',
                                ),
                              ),
                            ),
                            ...state.labels.map((lbl) {
                              final lKey = 'label_${lbl.title}';
                              final isSelected = _activeKey == lKey;
                              return ListTile(
                                dense: true,
                                leading: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Color(int.parse(lbl.color.replaceAll('#', '0xFF'))),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                title: Text(lbl.title, style: TextStyle(color: textPrimary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                trailing: isSelected ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 18) : null,
                                onTap: () {
                                  _onSelectDrawerItem(lKey, lbl.title);
                                  Navigator.pop(sheetCtx);
                                },
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
