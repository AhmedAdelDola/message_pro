import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../data/repositories/conversation_repository.dart';
import '../../../../logic/conversation/conversation_cubit.dart';
import '../chat_screen.dart';

class StartDirectChatSheet extends StatefulWidget {
  final String? initialPhone;

  const StartDirectChatSheet({super.key, this.initialPhone});

  static Future<void> show(BuildContext context, {String? initialPhone}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: StartDirectChatSheet(initialPhone: initialPhone),
      ),
    );
  }

  @override
  State<StartDirectChatSheet> createState() => _StartDirectChatSheetState();
}

class _StartDirectChatSheetState extends State<StartDirectChatSheet> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final IConversationRepository _repo = sl<IConversationRepository>();

  List<Map<String, dynamic>> _destinations = [];
  Map<String, dynamic>? _selectedDestination;
  bool _isLoadingDestinations = false;
  bool _isStartingChat = false;
  String? _errorMessage;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialPhone != null && widget.initialPhone!.isNotEmpty) {
      _phoneController.text = widget.initialPhone!;
    }
    _phoneController.addListener(_onPhoneChanged);
    _loadDestinations();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _phoneController.removeListener(_onPhoneChanged);
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String _cleanPhone(String raw) {
    var p = raw.trim().replaceAll(' ', '').replaceAll('-', '');
    if (p.startsWith('00')) {
      p = '+${p.substring(2)}';
    } else if (p.startsWith('01') && p.length == 11) {
      p = '+2$p';
    } else if (p.startsWith('201') && p.length == 12) {
      p = '+$p';
    }
    return p;
  }

  void _onPhoneChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      final phone = _cleanPhone(_phoneController.text);
      if (phone.length >= 8) {
        _loadDestinations(phoneNumber: phone);
      }
    });
  }

  Future<void> _loadDestinations({String? phoneNumber}) async {
    if (!mounted) return;
    setState(() {
      _isLoadingDestinations = true;
      _errorMessage = null;
    });

    final phone = phoneNumber ?? _cleanPhone(_phoneController.text);
    final result = await _repo.getPhoneDestinations(
      phoneNumber: phone.isNotEmpty ? phone : null,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isLoadingDestinations = false;
          _errorMessage = failure.message;
        });
      },
      (list) {
        setState(() {
          _destinations = list;
          _isLoadingDestinations = false;
          if (_destinations.isNotEmpty && _selectedDestination == null) {
            _selectedDestination = _destinations.first;
          }
        });
      },
    );
  }

  Future<void> _startChat() async {
    final phone = _cleanPhone(_phoneController.text);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    if (phone.isEmpty || phone.length < 9) {
      setState(() => _errorMessage = isArabic ? 'يرجى إدخال رقم هاتف صحيح' : 'Please enter a valid phone number');
      return;
    }

    if (_selectedDestination == null) {
      setState(() => _errorMessage = isArabic ? 'يرجى اختيار قناة المراسلة' : 'Please select a messaging channel');
      return;
    }

    final rawInbox = _selectedDestination!['inbox'];
    final rawInboxId = (rawInbox is Map) ? rawInbox['id'] : _selectedDestination!['inbox_id'];
    final inboxId = rawInboxId is int ? rawInboxId : int.tryParse(rawInboxId?.toString() ?? '') ?? 0;
    final sourceId = _selectedDestination!['source_id']?.toString() ?? phone;

    if (inboxId <= 0) {
      setState(() => _errorMessage = isArabic ? 'القناة المختارة غير صالحة' : 'Invalid channel selected');
      return;
    }

    setState(() {
      _isStartingChat = true;
      _errorMessage = null;
    });

    final result = await _repo.startDirectChat(
      phoneNumber: phone,
      inboxId: inboxId,
      sourceId: sourceId,
      contactName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isStartingChat = false;
          _errorMessage = failure.message;
        });
      },
      (conversation) {
        Navigator.pop(context); // Close sheet
        context.read<ConversationCubit>().loadConversations(refresh: true);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(conversation: conversation),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final cardBg = isDark ? const Color(0xFF161616) : Colors.white;
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final inputBg = isDark ? const Color(0xFF1E2024) : const Color(0xFFF1F5F9);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF333333) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),

          // Title & Icon
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedBubbleChatAdd,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'بدء محادثة برقم جديد' : 'Start Chat With Number',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      isArabic
                          ? 'تواصل مباشرة عبر قنوات WhatsApp و SMS المتاحة'
                          : 'Connect directly via available WhatsApp & SMS channels',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Phone Number Input
          Text(
            isArabic ? 'رقم الهاتف' : 'Phone Number',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.phone_outlined, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: isArabic ? '+201000000000 أو 010...' : '+201000000000',
                      hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.6), fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                if (_isLoadingDestinations)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Contact Name (Optional)
          Text(
            isArabic ? 'اسم العميل (اختياري)' : 'Contact Name (Optional)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _nameController,
              style: TextStyle(
                fontSize: 14,
                color: textPrimary,
              ),
              decoration: InputDecoration(
                hintText: isArabic ? 'مثال: أحمد محمد' : 'e.g. John Doe',
                hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.6), fontSize: 13.5),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Available Destinations / Channels List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'القنوات المتاحة للرقم' : 'Available Channels for Number',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              if (_destinations.isNotEmpty)
                Text(
                  '${_destinations.length} ${isArabic ? 'قنوات' : 'channels'}',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (_destinations.isEmpty && !_isLoadingDestinations)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                isArabic
                    ? 'لم يتم العثور على قنوات هاتفية متاحة لهذا الرقم. تأكد من إدخال كود الدولة.'
                    : 'No phone channels available. Ensure valid international format with country code.',
                style: TextStyle(fontSize: 12.5, color: textSecondary),
                textAlign: TextAlign.center,
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _destinations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, index) {
                  final dest = _destinations[index];
                  final isSelected = _selectedDestination == dest;
                  final rawInbox = dest['inbox'];
                  final inboxName = (rawInbox is Map ? rawInbox['name'] : dest['inbox_name'])?.toString() ?? 'Inbox';
                  final channelType = (rawInbox is Map ? rawInbox['channel_type'] : dest['channel_type'])?.toString().toLowerCase() ?? '';
                  final isWhatsApp = channelType.contains('whatsapp') || inboxName.toLowerCase().contains('whatsapp');

                  return InkWell(
                    onTap: () => setState(() => _selectedDestination = dest),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : inputBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : borderColor,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isWhatsApp
                                  ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                                  : const Color(0xFF10B981).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: isWhatsApp
                                  ? Image.asset(
                                      'assets/images/channels/whatsapp.png',
                                      width: 18,
                                      height: 18,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.chat_bubble, size: 16, color: Color(0xFF22C55E)),
                                    )
                                  : const Icon(Icons.sms_rounded, size: 17, color: Color(0xFF10B981)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  inboxName,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  dest['source_id']?.toString() ?? (isWhatsApp ? 'WhatsApp' : 'SMS'),
                                  style: TextStyle(fontSize: 11.5, color: textSecondary),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                          else
                            Icon(Icons.radio_button_unchecked_rounded, color: textSecondary.withValues(alpha: 0.4), size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Start Chat Button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isStartingChat ? null : _startChat,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isStartingChat
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          isArabic ? 'بدء المحادثة الآن' : 'Start Conversation Now',
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
