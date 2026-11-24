import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:message_pro/core/constants/app_colors.dart';
import 'package:message_pro/data/models/contact.dart';
import 'package:message_pro/logic/contacts/contacts_cubit.dart';
import 'package:message_pro/ui/widgets/country_code_picker.dart';
import 'widgets/contact_form_text_field.dart';
import 'widgets/contact_phone_input_field.dart';

/// Clean screen for updating existing contact basic info.
/// Reuses shared modular form field components.
class EditContactScreen extends StatefulWidget {
  final Contact contact;

  const EditContactScreen({super.key, required this.contact});

  @override
  State<EditContactScreen> createState() => _EditContactScreenState();
}

class _EditContactScreenState extends State<EditContactScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  CountryInfo _selectedCountry = getCountryByCode('EG');
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact.name);
    _emailController = TextEditingController(text: widget.contact.email ?? '');

    String phone = widget.contact.phoneNumber ?? '';
    for (final c in allCountries) {
      if (phone.startsWith(c.dialCode)) {
        _selectedCountry = c;
        phone = phone.substring(c.dialCode.length);
        break;
      }
    }
    _phoneController = TextEditingController(text: phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    setState(() => _isLoading = true);
    final fullName = _nameController.text.trim();

    String? phone = _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null;
    if (phone != null) {
      phone = normalizePhoneNumber(phone, _selectedCountry);
    }

    final contactsCubit = context.read<ContactsCubit>();
    final result = await contactsCubit.updateContact(
      widget.contact.id,
      name: fullName,
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      phoneNumber: phone,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: Colors.redAccent),
        );
      },
      (updatedContact) {
        Navigator.pop(context, updatedContact);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic ? 'تم تحديث بيانات العميل بنجاح' : 'Contact updated successfully'),
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
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(
          isArabic ? 'تعديل بيانات جهة الاتصال' : 'Edit Contact',
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
                label: isArabic ? 'الاسم الكامل' : 'Full Name',
                controller: _nameController,
                isRequired: true,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return isArabic ? 'الرجاء إدخال الاسم' : 'Please enter name';
                  }
                  return null;
                },
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
                          isArabic ? 'حفظ التعديلات' : 'Save Changes',
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
