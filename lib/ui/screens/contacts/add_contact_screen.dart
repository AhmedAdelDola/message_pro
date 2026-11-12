import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection_container.dart';
import '../../../data/repositories/contact_repository.dart';
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
  String? _selectedTag;
  bool _isLoading = false;

  final List<String> _lifecycleStages = [
    '⭐ Prospect',
    '🆕 New Lead',
    '⭐ Outbound Lead',
    '🔥 Engaged Lead',
    '⭐ Call Booked',
    '⭐ Demo Booked',
    '⭐ Trial Active',
    '😇 Payment Pending',
    '💰 lead qualified',
    '🤩 sales assigned',
    '🫣 demo booked / trial started',
    '🙄 Negotiation',
    '🤩 Customer',
    '😔 LOST',
  ];

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
    if (_selectedTag != null && _selectedTag!.isNotEmpty) {
      customAttrs['tag'] = _selectedTag;
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
            fontFamily: 'Gontserrat',
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
                      fontFamily: 'Gontserrat',
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
                            fontFamily: 'Gontserrat',
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
                                fontFamily: 'Gontserrat',
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
                        style: TextStyle(color: textPrimary, fontSize: 14, fontFamily: 'Gontserrat'),
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
              _buildFieldLabel('Lifecycle', textSecondary: textSecondary),
              const SizedBox(height: 6),
              _buildDropdown(
                value: _selectedLifecycle,
                hintText: 'Add Lifecycle',
                items: _lifecycleStages,
                onChanged: (val) => setState(() => _selectedLifecycle = val),
                inputBg: inputBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),

              const SizedBox(height: 14),

              // Collaborators Dropdown
              _buildFieldLabel('Collaborators', textSecondary: textSecondary),
              const SizedBox(height: 6),
              _buildDropdown(
                value: _selectedCollaborator,
                hintText: 'Select collaborators',
                items: ['hanen', 'Amr Hamdy', 'Sales agent'],
                onChanged: (val) => setState(() => _selectedCollaborator = val),
                inputBg: inputBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),

              const SizedBox(height: 14),

              // Tags Dropdown
              _buildFieldLabel('Tags', textSecondary: textSecondary),
              const SizedBox(height: 6),
              _buildDropdown(
                value: _selectedTag,
                hintText: 'Select tags',
                items: ['VIP Client', 'Inquiry', 'Urgent', 'WhatsApp Campaign'],
                onChanged: (val) => setState(() => _selectedTag = val),
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
                        fontFamily: 'Gontserrat',
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
                                fontFamily: 'Gontserrat',
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
            fontFamily: 'Gontserrat',
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
      style: TextStyle(color: textPrimary, fontSize: 14, fontFamily: 'Gontserrat'),
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
            style: TextStyle(color: textSecondary.withValues(alpha: 0.7), fontSize: 14, fontFamily: 'Gontserrat'),
          ),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: textSecondary),
          style: TextStyle(color: textPrimary, fontSize: 14, fontFamily: 'Gontserrat'),
          items: items.map((it) => DropdownMenuItem(value: it, child: Text(it))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
