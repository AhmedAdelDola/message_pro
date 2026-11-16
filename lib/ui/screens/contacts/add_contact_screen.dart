import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection_container.dart';
import '../../../data/models/contact.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/contact_repository.dart';
import '../../../data/repositories/conversation_repository.dart';
import '../../../logic/conversation/conversation_cubit.dart';
import '../../widgets/country_code_picker.dart';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  CountryInfo _selectedCountry = getCountryByCode('EG');
  String? _selectedLifecycle;
  String? _selectedCollaborator;
  final List<String> _selectedTags = [];
  List<User> _workspaceAgents = [];
  List<String> _workspaceLabels = [];
  List<LifecycleStage> _lifecycleStages = [];
  bool _isLoading = false;
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    _loadWorkspaceData();
  }

  Future<void> _loadWorkspaceData() async {
    setState(() => _isLoadingData = true);
    try {
      final convCubit = context.read<ConversationCubit>();
      if (convCubit.state.agents.isNotEmpty) {
        _workspaceAgents = List.from(convCubit.state.agents);
      } else {
        final res = await sl<IConversationRepository>().fetchAgents();
        res.fold((_) {}, (agents) => _workspaceAgents = agents);
      }

      if (convCubit.state.labels.isNotEmpty) {
        _workspaceLabels = convCubit.state.labels.map((l) => l.title).toList();
      } else {
        final res = await sl<IConversationRepository>().fetchLabels();
        res.fold((_) {}, (labels) => _workspaceLabels = labels.map((l) => l.title).toList());
      }

      if (convCubit.state.lifecycleStages.isNotEmpty) {
        _lifecycleStages = List.from(convCubit.state.lifecycleStages);
      } else {
        final res = await sl<IConversationRepository>().fetchLifecycleStages();
        res.fold((_) {}, (stages) => _lifecycleStages = stages);
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoadingData = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    setState(() => _isLoading = true);
    final fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim();

    String? phone = _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null;
    if (phone != null) {
      phone = normalizePhoneNumber(phone, _selectedCountry);
    }

    final customAttrs = <String, dynamic>{};
    if (_selectedLifecycle != null && _selectedLifecycle!.isNotEmpty) {
      customAttrs['lifecycle_stage'] = _selectedLifecycle;
      customAttrs['lead_status'] = _selectedLifecycle;
    }
    if (_selectedCollaborator != null && _selectedCollaborator!.isNotEmpty) {
      customAttrs['collaborator'] = _selectedCollaborator;
      final matching = _workspaceAgents.where((a) => a.name == _selectedCollaborator).firstOrNull;
      if (matching != null) {
        customAttrs['collaborator_id'] = matching.id;
      }
    }
    if (_selectedTags.isNotEmpty) {
      customAttrs['labels'] = _selectedTags;
      customAttrs['tags'] = _selectedTags;
      customAttrs['tag'] = _selectedTags.first;
    }

    final result = await sl<IContactRepository>().createContact(
      name: fullName,
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      phoneNumber: phone,
      customAttributes: customAttrs.isNotEmpty ? customAttrs : null,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: Colors.redAccent),
        );
      },
      (contact) async {
        if (_selectedTags.isNotEmpty) {
          await sl<IContactRepository>().updateContactLabels(contact.id, _selectedTags);
        }
        if (!mounted) return;
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic ? 'تم إنشاء جهة الاتصال بنجاح' : 'Contact created successfully'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      },
    );
  }

  void _showAddTagDialog(BuildContext context, bool isDark, bool isArabic) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        title: Text(
          isArabic ? 'إضافة وسم مخصص' : 'Add Custom Tag',
          style: TextStyle(
            color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: isArabic ? 'اكتب اسم الوسم...' : 'Enter tag name...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final tag = textController.text.trim();
              if (tag.isNotEmpty && !_selectedTags.contains(tag)) {
                setState(() => _selectedTags.add(tag));
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(isArabic ? 'إضافة' : 'Add', style: const TextStyle(color: Colors.white)),
          ),
        ],
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
    final inputBg = isDark ? AppColors.darkSurface : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(
          isArabic ? 'جهة اتصال جديدة' : 'New Contact',
          style: TextStyle(
            color: textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close_rounded, color: textPrimary, size: 22),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contact details header with Assignee badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isArabic ? 'تفاصيل جهة الاتصال' : 'Contact details',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE2E8F0),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.person, size: 14, color: AppColors.primary),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Amr Hamdy',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: textSecondary),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // First name *
              _buildFieldLabel('First name', isRequired: true, textSecondary: textSecondary),
              const SizedBox(height: 6),
              _buildTextInput(
                controller: _firstNameController,
                hintText: 'Add First Name',
                inputBg: inputBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter first name' : null,
              ),

              const SizedBox(height: 14),

              // Last name
              _buildFieldLabel('Last name', textSecondary: textSecondary),
              const SizedBox(height: 6),
              _buildTextInput(
                controller: _lastNameController,
                hintText: 'Add Last Name',
                inputBg: inputBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),

              const SizedBox(height: 14),

              // Phone number
              _buildFieldLabel('Phone number', textSecondary: textSecondary),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    InkWell(
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                      onTap: () async {
                        final picked = await showCountryPickerModal(context);
                        if (picked != null) {
                          setState(() => _selectedCountry = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(right: BorderSide(color: borderColor, width: 1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedCountry.flag,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _selectedCountry.dialCode,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: textSecondary),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Add Phone Number (or +966...)',
                          hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.7), fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Email address
              _buildFieldLabel('Email address', textSecondary: textSecondary),
              const SizedBox(height: 6),
              _buildTextInput(
                controller: _emailController,
                hintText: 'Add Email Address',
                keyboardType: TextInputType.emailAddress,
                inputBg: inputBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),

              const SizedBox(height: 14),

              // Lifecycle Dropdown
              _buildFieldLabel(isArabic ? 'مرحلة العميل' : 'Lifecycle Stage', textSecondary: textSecondary),
              const SizedBox(height: 6),
              _buildDropdown(
                value: _selectedLifecycle,
                hintText: _isLoadingData
                    ? (isArabic ? 'جاري التحميل...' : 'Loading...')
                    : (_lifecycleStages.isEmpty ? (isArabic ? 'لا توجد مراحل محددة في النظام' : 'No lifecycle stages on backend') : (isArabic ? 'اختر مرحلة العميل' : 'Select lifecycle stage')),
                items: _lifecycleStages.map((s) => s.icon != null ? '${s.icon} ${s.name}' : s.name).toList(),
                onChanged: (val) => setState(() => _selectedLifecycle = val),
                inputBg: inputBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),

              const SizedBox(height: 14),

              // Collaborators Dropdown (Dynamic from backend)
              _buildFieldLabel(isArabic ? 'المتعاونون' : 'Collaborators', textSecondary: textSecondary),
              const SizedBox(height: 6),
              _buildDropdown(
                value: _selectedCollaborator,
                hintText: _isLoadingData
                    ? (isArabic ? 'جاري التحميل...' : 'Loading...')
                    : (_workspaceAgents.isEmpty
                        ? (isArabic ? 'لا يوجد متعاونون في النظام' : 'No collaborators found on backend')
                        : (isArabic ? 'اختر متعاون من الفريق' : 'Select collaborator')),
                items: _workspaceAgents.map((a) => a.name).where((n) => n.trim().isNotEmpty).toSet().toList(),
                onChanged: (val) => setState(() => _selectedCollaborator = val),
                inputBg: inputBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),

              const SizedBox(height: 14),

              // Tags Section (Dynamic from backend)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFieldLabel(isArabic ? 'الوسوم والتصنيفات' : 'Tags & Labels', textSecondary: textSecondary),
                  InkWell(
                    onTap: () => _showAddTagDialog(context, isDark, isArabic),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.add_rounded, size: 15, color: AppColors.primary),
                          const SizedBox(width: 2),
                          Text(
                            isArabic ? 'إضافة وسم' : 'Add Tag',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (_selectedTags.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _selectedTags.map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.label_outline_rounded, size: 12, color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8)),
                        const SizedBox(width: 4),
                        Text(
                          t,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => setState(() => _selectedTags.remove(t)),
                          child: Icon(
                            Icons.close_rounded,
                            size: 13,
                            color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 8),
              ],
              _buildDropdown(
                value: null,
                hintText: _isLoadingData
                    ? (isArabic ? 'جاري التحميل...' : 'Loading tags...')
                    : (_workspaceLabels.isEmpty
                        ? (isArabic ? 'لا توجد وسوم في النظام، اضغط إضافة وسم' : 'No tags found, click + Add Tag')
                        : (isArabic ? 'اختر وسم من تصنيفات النظام' : 'Select tag from workspace')),
                items: _workspaceLabels.where((l) => !_selectedTags.contains(l)).toList(),
                onChanged: (val) {
                  if (val != null && !_selectedTags.contains(val)) {
                    setState(() => _selectedTags.add(val));
                  }
                },
                inputBg: inputBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),

              const SizedBox(height: 36),

              // Footer Buttons: Cancel & Create
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      isArabic ? 'إلغاء' : 'Cancel',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              isArabic ? 'إنشاء' : 'Create',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text, {bool isRequired = false, required Color textSecondary}) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 2),
          const Text('*', style: TextStyle(color: AppColors.danger, fontSize: 13)),
        ],
      ],
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    required Color inputBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.7), fontSize: 14),
        filled: true,
        fillColor: inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hintText,
    required List<String> items,
    required Function(String?) onChanged,
    required Color inputBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hintText,
            style: TextStyle(color: textSecondary.withValues(alpha: 0.7), fontSize: 14),
          ),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: textSecondary),
          style: TextStyle(color: textPrimary, fontSize: 14),
          items: items.map((it) => DropdownMenuItem(value: it, child: Text(it))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
