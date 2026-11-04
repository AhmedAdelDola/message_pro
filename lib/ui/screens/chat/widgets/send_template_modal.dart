import 'package:flutter/material.dart';
import '../../../../data/models/message_template.dart';

class SendTemplateModal extends StatefulWidget {
  final List<MessageTemplate> templates;
  final Function(MessageTemplate template) onSend;

  const SendTemplateModal({
    super.key,
    required this.templates,
    required this.onSend,
  });

  static Future<void> show({
    required BuildContext context,
    required List<MessageTemplate> templates,
    required Function(MessageTemplate template) onSend,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161616) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SendTemplateModal(
          templates: templates,
          onSend: onSend,
        ),
      ),
    );
  }

  @override
  State<SendTemplateModal> createState() => _SendTemplateModalState();
}

class _SendTemplateModalState extends State<SendTemplateModal> {
  int _selectedTab = 1; // 0 = Recently used, 1 = All templates
  String _searchQuery = '';
  String? _selectedLanguage;
  String? _selectedCategory;
  MessageTemplate? _selectedTemplate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final filteredTemplates = widget.templates.where((t) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = t.name.toLowerCase().contains(q);
        final matchesBody = t.body.toLowerCase().contains(q);
        if (!matchesName && !matchesBody) return false;
      }
      if (_selectedLanguage != null && t.languageDisplay != _selectedLanguage) {
        return false;
      }
      if (_selectedCategory != null && t.categoryDisplay != _selectedCategory) {
        return false;
      }
      return true;
    }).toList();

    final languages = widget.templates.map((t) => t.languageDisplay).toSet().toList();
    final categories = widget.templates.map((t) => t.categoryDisplay).toSet().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Header (matching Web CRM)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF25D366),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_bubble, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'إرسال رسالة قالب' : 'Send message template',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Gontserrat',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isArabic
                          ? 'يتم إرسال رسائل قوالب واتساب المعتمدة فقط إلى جهات اتصالك.'
                          : 'Only approved WhatsApp message templates are sent to your Contacts.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        fontFamily: 'Gontserrat',
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // 2. Tabs Row (Recently used / All templates)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              _buildTabPill(
                label: isArabic ? 'الأخيرة' : 'Recently used',
                isSelected: _selectedTab == 0,
                onTap: () => setState(() => _selectedTab = 0),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildTabPill(
                label: isArabic ? 'جميع القوالب' : 'All templates',
                isSelected: _selectedTab == 1,
                onTap: () => setState(() => _selectedTab = 1),
                isDark: isDark,
              ),
            ],
          ),
        ),

        // 3. Search & Filter Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Container(
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF212124) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? const Color(0xFF32353B) : const Color(0xFFE5E7EB),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, size: 18, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: const TextStyle(fontSize: 13, fontFamily: 'Gontserrat'),
                        decoration: InputDecoration(
                          hintText: isArabic ? 'بحث في القوالب...' : 'Search',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                            fontFamily: 'Gontserrat',
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      hint: isArabic ? 'اللغة' : 'Language',
                      value: _selectedLanguage,
                      items: languages,
                      onChanged: (val) => setState(() => _selectedLanguage = val),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDropdown(
                      hint: isArabic ? 'التصنيف' : 'Label',
                      value: _selectedCategory,
                      items: categories,
                      onChanged: (val) => setState(() => _selectedCategory = val),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // 4. Templates List
        Expanded(
          child: filteredTemplates.isEmpty
              ? Center(
                  child: Text(
                    isArabic ? 'لا توجد قوالب مطابقة' : 'No matching templates found',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      fontFamily: 'Gontserrat',
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredTemplates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final tpl = filteredTemplates[index];
                    final isSelected = _selectedTemplate?.name == tpl.name;

                    return InkWell(
                      onTap: () => setState(() => _selectedTemplate = tpl),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF4162E3).withValues(alpha: isDark ? 0.2 : 0.08)
                              : (isDark ? const Color(0xFF1E1F24) : const Color(0xFFFAFAFA)),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF4162E3)
                                : (isDark ? const Color(0xFF2C2F36) : const Color(0xFFE5E7EB)),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    tpl.name,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? const Color(0xFF4162E3) : null,
                                      fontFamily: 'Gontserrat',
                                    ),
                                  ),
                                ),
                                Text(
                                  '${tpl.languageDisplay} · ${tpl.categoryDisplay}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                    fontFamily: 'Gontserrat',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              tpl.body,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.35,
                                color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
                                fontFamily: 'Gontserrat',
                              ),
                            ),
                            if (tpl.buttons.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: tpl.buttons.map((b) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4162E3).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          b.isUrl ? Icons.open_in_new_rounded : Icons.reply_rounded,
                                          size: 11,
                                          color: const Color(0xFF4162E3),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          b.text,
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF4162E3),
                                            fontFamily: 'Gontserrat',
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // 5. Footer (Learn more / Cancel / Send)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161616) : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? const Color(0xFF2C2F36) : const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                TextButton(
                  onPressed: () {},
                  child: Text(
                    isArabic ? 'معرفة المزيد' : 'Learn more',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF4162E3),
                      fontFamily: 'Gontserrat',
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    isArabic ? 'إلغاء' : 'Cancel',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      fontFamily: 'Gontserrat',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectedTemplate == null
                      ? null
                      : () {
                          final tpl = _selectedTemplate!;
                          Navigator.pop(context);
                          widget.onSend(tpl);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4162E3),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: isDark ? const Color(0xFF2C2F36) : const Color(0xFFE5E7EB),
                    disabledForegroundColor: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(
                    isArabic ? 'إرسال' : 'Send',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Gontserrat'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFEEF2FF)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6366F1)
                : (isDark ? const Color(0xFF32353B) : const Color(0xFFE5E7EB)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? const Color(0xFF4338CA)
                : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563)),
            fontFamily: 'Gontserrat',
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF212124) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF32353B) : const Color(0xFFE5E7EB),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              fontFamily: 'Gontserrat',
            ),
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                'الكل ($hint)',
                style: const TextStyle(fontSize: 12, fontFamily: 'Gontserrat'),
              ),
            ),
            ...items.map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 12, fontFamily: 'Gontserrat'),
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
