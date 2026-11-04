import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/contact.dart';
import '../../../logic/conversation/conversation_cubit.dart';
import '../../../logic/conversation/conversation_state.dart';
import '../../widgets/avatar_widget.dart';
import '../chat/chat_screen.dart';

class ContactDetailsScreen extends StatefulWidget {
  final Contact contact;

  const ContactDetailsScreen({super.key, required this.contact});

  @override
  State<ContactDetailsScreen> createState() => _ContactDetailsScreenState();
}

class _ContactDetailsScreenState extends State<ContactDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _lifecycleStage = 'Engaged Lead';
  final TextEditingController _noteController = TextEditingController();
  final List<Map<String, dynamic>> _notes = [];

  final List<String> _lifecycleStages = [
    'Prospect',
    'New Lead',
    'Outbound Lead',
    'Engaged Lead',
    'Call Booked',
    'Demo Booked',
    'Trial Active',
    'Payment Pending',
    'Lead Qualified',
    'Sales Assigned',
    'Negotiation',
    'Customer',
    'Lost',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Add sample initial note for realism if none
    _notes.add({
      'content': 'تم تسجيل العميل بنجاح في النظام ومتابعة متطلباته.',
      'author': 'فريق العمل',
      'createdAt': DateTime.now().subtract(const Duration(hours: 3)),
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _makePhoneCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _copyToClipboard(phone, 'Phone number');
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _copyToClipboard(phone, 'WhatsApp number');
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _copyToClipboard(email, 'Email address');
    }
  }

  void _showLifecyclePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Select Lifecycle Stage',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Gontserrat'),
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: _lifecycleStages.length,
                  itemBuilder: (context, index) {
                    final stage = _lifecycleStages[index];
                    final isSelected = stage == _lifecycleStage;
                    return ListTile(
                      title: Text(
                        stage,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.primary : null,
                          fontFamily: 'Gontserrat',
                        ),
                      ),
                      trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                      onTap: () {
                        setState(() => _lifecycleStage = stage);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addNote() {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _notes.insert(0, {
        'content': text,
        'author': 'أنت',
        'createdAt': DateTime.now(),
      });
      _noteController.clear();
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;

    final contact = widget.contact;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: textPrimary, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isArabic ? 'تفاصيل جهة الاتصال' : 'Contact details',
          style: TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Gontserrat',
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined, color: textSecondary, size: 20),
            tooltip: isArabic ? 'مشاركة' : 'Share',
            onPressed: () {
              final summary = '${contact.name}\n${contact.phoneNumber ?? ''}\n${contact.email ?? ''}';
              _copyToClipboard(summary, 'Contact info');
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      children: [
                        AvatarWidget(
                          avatarUrl: contact.avatarUrl,
                          name: contact.name,
                          size: 58,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contact.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                  fontFamily: 'Gontserrat',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'ID: #${contact.id > 0 ? contact.id : 10990}',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: textSecondary,
                                      fontFamily: 'Gontserrat',
                                    ),
                                  ),
                                  if (contact.identifier != null && contact.identifier!.isNotEmpty) ...[
                                    Text(' • ', style: TextStyle(color: textSecondary)),
                                    Flexible(
                                      child: Text(
                                        contact.identifier!,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: textSecondary,
                                          fontFamily: 'Gontserrat',
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Quick Action Buttons Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        if (contact.phoneNumber != null && contact.phoneNumber!.isNotEmpty) ...[
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.phone_rounded,
                              label: isArabic ? 'اتصال' : 'Call',
                              color: const Color(0xFF10B981),
                              onTap: () => _makePhoneCall(contact.phoneNumber!),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.chat_bubble_rounded,
                              label: 'WhatsApp',
                              color: const Color(0xFF25D366),
                              onTap: () => _openWhatsApp(contact.phoneNumber!),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (contact.email != null && contact.email!.isNotEmpty) ...[
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.email_rounded,
                              label: isArabic ? 'بريد' : 'Email',
                              color: const Color(0xFF4162E3),
                              onTap: () => _sendEmail(contact.email!),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.copy_rounded,
                            label: isArabic ? 'نسخ' : 'Copy',
                            color: const Color(0xFF64748B),
                            onTap: () {
                              final text = contact.phoneNumber ?? contact.email ?? contact.name;
                              _copyToClipboard(text, 'Contact details');
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                  Divider(color: borderColor, height: 1),

                  // Functional Tabs Bar
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 2.5,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: textSecondary,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Gontserrat'),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13, fontFamily: 'Gontserrat'),
                      tabAlignment: TabAlignment.start,
                      tabs: [
                        Tab(
                          icon: const Icon(Icons.person_outline_rounded, size: 18),
                          text: isArabic ? 'المعلومات' : 'Details',
                        ),
                        Tab(
                          icon: const Icon(Icons.tune_rounded, size: 18),
                          text: isArabic ? 'السمات الإضافية' : 'Attributes',
                        ),
                        Tab(
                          icon: const Icon(Icons.note_alt_outlined, size: 18),
                          text: isArabic ? 'الملاحظات' : 'Notes',
                        ),
                        Tab(
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                          text: isArabic ? 'المحادثات' : 'Chats',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildDetailsTab(isArabic, textPrimary, textSecondary, borderColor, cardBg),
            _buildAttributesTab(isArabic, textPrimary, textSecondary, borderColor, cardBg),
            _buildNotesTab(isArabic, textPrimary, textSecondary, borderColor, cardBg),
            _buildConversationsTab(isArabic, textPrimary, textSecondary, borderColor, cardBg),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
                fontFamily: 'Gontserrat',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Details Tab
  Widget _buildDetailsTab(
    bool isArabic,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
    Color cardBg,
  ) {
    final contact = widget.contact;
    final phone = contact.phoneNumber;
    final email = contact.email;
    final identifier = contact.identifier;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        // Lifecycle Stage Selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'مرحلة العميل' : 'Lifecycle Stage',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                  fontFamily: 'Gontserrat',
                ),
              ),
              InkWell(
                onTap: _showLifecyclePicker,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _lifecycleStage,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                          fontFamily: 'Gontserrat',
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, size: 16, color: textSecondary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        Divider(color: borderColor, height: 1),

        // Contact Fields
        _buildFieldTile(
          label: isArabic ? 'رقم الهاتف' : 'Phone Number',
          value: phone != null && phone.isNotEmpty ? phone : (isArabic ? 'غير متوفر' : 'Not available'),
          isPlaceholder: phone == null || phone.isEmpty,
          onCopy: phone != null && phone.isNotEmpty ? () => _copyToClipboard(phone, 'Phone number') : null,
          actionIcon: phone != null && phone.isNotEmpty ? Icons.phone_rounded : null,
          onAction: phone != null && phone.isNotEmpty ? () => _makePhoneCall(phone) : null,
        ),
        _buildFieldTile(
          label: isArabic ? 'البريد الإلكتروني' : 'Email Address',
          value: email != null && email.isNotEmpty ? email : (isArabic ? 'غير متوفر' : 'Not available'),
          isPlaceholder: email == null || email.isEmpty,
          onCopy: email != null && email.isNotEmpty ? () => _copyToClipboard(email, 'Email') : null,
          actionIcon: email != null && email.isNotEmpty ? Icons.email_rounded : null,
          onAction: email != null && email.isNotEmpty ? () => _sendEmail(email) : null,
        ),
        _buildFieldTile(
          label: isArabic ? 'المعرف الفريد' : 'Identifier',
          value: identifier != null && identifier.isNotEmpty ? identifier : (isArabic ? 'غير محدد' : 'Not specified'),
          isPlaceholder: identifier == null || identifier.isEmpty,
          onCopy: identifier != null && identifier.isNotEmpty ? () => _copyToClipboard(identifier, 'Identifier') : null,
        ),
        _buildFieldTile(
          label: isArabic ? 'رقم العميل' : 'Contact ID',
          value: '#${contact.id}',
          onCopy: () => _copyToClipboard('${contact.id}', 'Contact ID'),
        ),
      ],
    );
  }

  // 2. Custom Attributes Tab
  Widget _buildAttributesTab(
    bool isArabic,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
    Color cardBg,
  ) {
    final attributes = widget.contact.customAttributes;

    if (attributes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.tune_rounded, size: 48, color: textSecondary.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text(
                isArabic ? 'لا توجد سمات إضافية' : 'No Custom Attributes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                  fontFamily: 'Gontserrat',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isArabic
                    ? 'الحقول المخصصة التي يتم إضافتها في النظام ستظهر هنا.'
                    : 'Custom fields configured for this contact in Chatwoot will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: textSecondary,
                  fontFamily: 'Gontserrat',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: attributes.entries.map((entry) {
        final keyName = entry.key.replaceAll('_', ' ').split(' ').map((w) {
          if (w.isEmpty) return '';
          return '${w[0].toUpperCase()}${w.substring(1)}';
        }).join(' ');

        final val = entry.value?.toString() ?? '';

        return _buildFieldTile(
          label: keyName,
          value: val.isNotEmpty ? val : '-',
          isPlaceholder: val.isEmpty,
          onCopy: val.isNotEmpty ? () => _copyToClipboard(val, keyName) : null,
        );
      }).toList(),
    );
  }

  // 3. Notes Tab
  Widget _buildNotesTab(
    bool isArabic,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
    Color cardBg,
  ) {
    return Column(
      children: [
        // Note Input
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _noteController,
                  maxLines: 3,
                  minLines: 1,
                  style: TextStyle(fontSize: 13.5, color: textPrimary, fontFamily: 'Gontserrat'),
                  decoration: InputDecoration(
                    hintText: isArabic ? 'أضف ملاحظة خاصة حول هذا العميل...' : 'Add a private note about this contact...',
                    hintStyle: TextStyle(fontSize: 13, color: textSecondary, fontFamily: 'Gontserrat'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                tooltip: isArabic ? 'إرسال' : 'Send',
                onPressed: _addNote,
              ),
            ],
          ),
        ),

        // Notes List
        Expanded(
          child: _notes.isEmpty
              ? Center(
                  child: Text(
                    isArabic ? 'لا توجد ملاحظات بعد' : 'No notes yet',
                    style: TextStyle(color: textSecondary, fontFamily: 'Gontserrat'),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    final date = note['createdAt'] as DateTime;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                note['author'] ?? 'أنت',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontFamily: 'Gontserrat',
                                ),
                              ),
                              Text(
                                DateFormat('d MMM, h:mm a').format(date),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textSecondary,
                                  fontFamily: 'Gontserrat',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            note['content'] ?? '',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: textPrimary,
                              height: 1.35,
                              fontFamily: 'Gontserrat',
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // 4. Conversations Tab
  Widget _buildConversationsTab(
    bool isArabic,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
    Color cardBg,
  ) {
    return BlocBuilder<ConversationCubit, ConversationState>(
      builder: (context, state) {
        final contactConversations = state.conversations.where((c) {
          return c.contact.id == widget.contact.id ||
              (c.contact.phoneNumber != null &&
                  c.contact.phoneNumber == widget.contact.phoneNumber &&
                  c.contact.phoneNumber!.isNotEmpty);
        }).toList();

        if (contactConversations.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 48, color: textSecondary.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text(
                    isArabic ? 'لا توجد محادثات سابقة' : 'No prior conversations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                      fontFamily: 'Gontserrat',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isArabic
                        ? 'محادثات هذا العميل ستظهر هنا عند التواصل معه.'
                        : 'Conversations with this contact will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                      fontFamily: 'Gontserrat',
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: contactConversations.length,
          itemBuilder: (context, index) {
            final conv = contactConversations[index];
            final isOpen = conv.status == 'open';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: ListTile(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(conversation: conv),
                    ),
                  );
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                title: Row(
                  children: [
                    Text(
                      '#${conv.id} - ${conv.inboxName ?? 'Chat'}',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                        fontFamily: 'Gontserrat',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOpen ? Colors.green.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isOpen ? (isArabic ? 'مفتوحة' : 'Open') : (isArabic ? 'مغلقة' : 'Resolved'),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: isOpen ? Colors.green : Colors.grey,
                          fontFamily: 'Gontserrat',
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: conv.lastMessage?.content != null
                    ? Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          conv.lastMessage!.content!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, color: textSecondary, fontFamily: 'Gontserrat'),
                        ),
                      )
                    : null,
                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFieldTile({
    required String label,
    required String value,
    bool isPlaceholder = false,
    VoidCallback? onCopy,
    IconData? actionIcon,
    VoidCallback? onAction,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor, width: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textSecondary,
              fontFamily: 'Gontserrat',
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isPlaceholder ? FontWeight.normal : FontWeight.w500,
                    color: isPlaceholder ? textSecondary.withValues(alpha: 0.7) : textPrimary,
                    fontFamily: 'Gontserrat',
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (actionIcon != null && onAction != null)
                    InkWell(
                      onTap: onAction,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(actionIcon, size: 16, color: AppColors.primary),
                      ),
                    ),
                  if (onCopy != null) ...[
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: onCopy,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.copy_rounded, size: 15, color: textSecondary),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
