import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:message_pro/core/constants/app_colors.dart';
import 'package:message_pro/data/models/contact.dart';
import 'package:message_pro/data/models/user.dart';
import 'package:message_pro/logic/contacts/contacts_cubit.dart';
import 'package:message_pro/logic/conversation/conversation_cubit.dart';
import 'package:message_pro/ui/widgets/country_code_picker.dart';
import 'widgets/contact_form_text_field.dart';
import 'widgets/contact_phone_input_field.dart';
import 'widgets/contact_dropdown_selector.dart';
import 'widgets/contact_tags_selector.dart';

/// Clean screen for creating new contacts.
/// Follows SOLID principles by composing modular form field widgets.
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

  @override
  void initState() {
    super.initState();
    _loadWorkspaceData();
  }

  Future<void> _loadWorkspaceData() async {
    try {
      final convCubit = context.read<ConversationCubit>();
      if (convCubit.state.agents.isEmpty ||
          convCubit.state.labels.isEmpty ||
          convCubit.state.lifecycleStages.isEmpty) {
        await convCubit.loadAuxiliaryData();
      }

      if (mounted) {
        setState(() {
          _workspaceAgents = List.from(convCubit.state.agents);
          _workspaceLabels = convCubit.state.labels.map((l) => l.title).toList();
          _lifecycleStages = List.from(convCubit.state.lifecycleStages);
        });
      }
    } catch (_) {}
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

    final contactsCubit = context.read<ContactsCubit>();
    final result = await contactsCubit.createContact(
      name: fullName,
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      phoneNumber: phone,
      tags: _selectedTags.isNotEmpty ? _selectedTags : null,
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
      (contact) {
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
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(
          isArabic ? 'جهة اتصال جديدة' : 'New Contact',
          style: TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
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
              ContactFormTextField(
                label: isArabic ? 'الاسم الأول' : 'First Name',
                controller: _firstNameController,
                hintText: isArabic ? 'أدخل الاسم الأول' : 'Enter first name',
                isRequired: true,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return isArabic ? 'الرجاء إدخال الاسم الأول' : 'Please enter first name';
                  }
                  return null;
                },
              ),
              ContactFormTextField(
                label: isArabic ? 'الاسم الأخير' : 'Last Name',
                controller: _lastNameController,
                hintText: isArabic ? 'أدخل الاسم الأخير' : 'Enter last name',
              ),
              ContactPhoneInputField(
                controller: _phoneController,
                selectedCountry: _selectedCountry,
                onCountryChanged: (c) => setState(() => _selectedCountry = c),
                label: isArabic ? 'رقم الهاتف' : 'Phone Number',
              ),
              ContactFormTextField(
                label: isArabic ? 'البريد الإلكتروني' : 'Email Address',
                controller: _emailController,
                hintText: 'name@example.com',
                keyboardType: TextInputType.emailAddress,
              ),
              if (_lifecycleStages.isNotEmpty)
                ContactDropdownSelector<String>(
                  label: isArabic ? 'مرحلة العميل (Lifecycle Stage)' : 'Lifecycle Stage',
                  value: _selectedLifecycle,
                  hintText: isArabic ? 'اختر المرحلة' : 'Select stage',
                  items: _lifecycleStages.map((s) {
                    return DropdownMenuItem<String>(
                      value: s.name,
                      child: Row(
                        children: [
                          Text(s.icon ?? '🌱', style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 8),
                          Text(s.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedLifecycle = val),
                ),
              if (_workspaceAgents.isNotEmpty)
                ContactDropdownSelector<String>(
                  label: isArabic ? 'المتعاون / الموظف المعين' : 'Collaborator / Assignee',
                  value: _selectedCollaborator,
                  hintText: isArabic ? 'اختر موظفاً' : 'Select agent',
                  items: _workspaceAgents.map((a) {
                    return DropdownMenuItem<String>(
                      value: a.name,
                      child: Text(a.name),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCollaborator = val),
                ),
              ContactTagsSelector(
                availableTags: _workspaceLabels,
                selectedTags: _selectedTags,
                onTagToggled: (tag) {
                  setState(() {
                    if (_selectedTags.contains(tag)) {
                      _selectedTags.remove(tag);
                    } else {
                      _selectedTags.add(tag);
                    }
                  });
                },
                onAddCustomTagTap: () => _showAddTagDialog(context, isDark, isArabic),
                label: isArabic ? 'الوسوم والتصنيفات (Tags)' : 'Tags & Labels',
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          isArabic ? 'حفظ جهة الاتصال' : 'Save Contact',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
