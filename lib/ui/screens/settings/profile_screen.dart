import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:message_pro/core/constants/app_colors.dart';
import 'package:message_pro/data/models/user.dart';
import 'package:message_pro/logic/auth/auth_cubit.dart';
import 'package:message_pro/logic/auth/auth_state.dart';
import 'package:message_pro/ui/widgets/custom_button.dart';
import 'package:message_pro/ui/widgets/app_bar_progress_bar.dart';
import 'widgets/profile/profile_avatar_header.dart';
import 'widgets/profile/profile_availability_selector.dart';
import 'widgets/profile/profile_account_details_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;

  String _selectedAvailability = 'online';
  int? _breakDuration;
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final user = context.read<AuthCubit>().currentUser;
      if (user != null) {
        _nameController.text = user.name;
        _emailController.text = user.email;
        _selectedAvailability = user.availabilityStatus;
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'busy':
        return const Color(0xFFFA8900);
      case 'offline':
        return const Color(0xFF80838D);
      case 'online':
      default:
        return const Color(0xFF2CA54A);
    }
  }

  Future<void> _handleSave(User currentUser, bool isArabic) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final cubit = context.read<AuthCubit>();

    final profileResult = await cubit.updateProfile(name: name, email: email);
    if (!mounted) return;

    String? errorMessage;
    profileResult.fold(
      (failure) => errorMessage = failure.message,
      (_) {},
    );

    if (errorMessage == null && _selectedAvailability != currentUser.availabilityStatus) {
      final availResult = await cubit.updateAvailability(
        _selectedAvailability,
        breakDurationMinutes: _breakDuration,
      );
      availResult.fold(
        (failure) => errorMessage = failure.message,
        (_) {},
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage!, style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                isArabic ? 'تم حفظ التغييرات بنجاح' : 'Profile updated successfully',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2CA54A),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final bgColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFFAFAFA);
    final cardBg = isDark ? const Color(0xFF161616) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF0D0D0D);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB);
    final inputBg = isDark ? const Color(0xFF1E2024) : const Color(0xFFF9FAFB);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        bottom: AppBarProgressBar(isLoading: _isSaving),
        title: Text(
          isArabic ? 'الملف الشخصي' : 'Edit Profile',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            isArabic ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
            color: textPrimary,
            size: 28,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, authState) {
          if (authState is Authenticated && !_isSaving) {
            if (_nameController.text != authState.user.name) {
              _nameController.text = authState.user.name;
            }
            if (_emailController.text != authState.user.email) {
              _emailController.text = authState.user.email;
            }
            if (_selectedAvailability != authState.user.availabilityStatus) {
              setState(() {
                _selectedAvailability = authState.user.availabilityStatus;
              });
            }
          }
        },
        builder: (context, authState) {
          final user = authState is Authenticated ? authState.user : context.read<AuthCubit>().currentUser;
          if (user == null) {
            return const SizedBox.shrink();
          }

          final statusColor = _getStatusColor(_selectedAvailability);

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProfileAvatarHeader(
                    user: user,
                    availabilityStatus: _selectedAvailability,
                    statusColor: statusColor,
                  ),
                  SizedBox(height: 28.h),
                  _buildSectionTitle(isArabic ? 'حالة التواجد' : 'AVAILABILITY STATUS'),
                  SizedBox(height: 8.h),
                  ProfileAvailabilitySelector(
                    selectedAvailability: _selectedAvailability,
                    onSelected: (key, duration) {
                      setState(() {
                        _selectedAvailability = key;
                        _breakDuration = duration;
                      });
                    },
                  ),
                  SizedBox(height: 24.h),
                  _buildSectionTitle(isArabic ? 'البيانات الشخصية' : 'PERSONAL INFORMATION'),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(isArabic ? 'الاسم الكامل *' : 'Full Name *', textPrimary),
                        SizedBox(height: 6.h),
                        TextFormField(
                          controller: _nameController,
                          style: TextStyle(fontSize: 14.sp, color: textPrimary),
                          decoration: _inputDecoration(
                            hint: isArabic ? 'أدخل اسمك الكامل' : 'Enter full name',
                            icon: Icons.person_outline_rounded,
                            inputBg: inputBg,
                            borderColor: borderColor,
                            textSecondary: textSecondary,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return isArabic ? 'يرجى إدخال الاسم الكامل' : 'Name is required';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),
                        _buildLabel(isArabic ? 'البريد الإلكتروني *' : 'Email Address *', textPrimary),
                        SizedBox(height: 6.h),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(fontSize: 14.sp, color: textPrimary),
                          decoration: _inputDecoration(
                            hint: isArabic ? 'أدخل البريد الإلكتروني' : 'Enter email address',
                            icon: Icons.email_outlined,
                            inputBg: inputBg,
                            borderColor: borderColor,
                            textSecondary: textSecondary,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return isArabic ? 'يرجى إدخال البريد الإلكتروني' : 'Email is required';
                            }
                            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(val.trim())) {
                              return isArabic ? 'يرجى إدخال بريد إلكتروني صالح' : 'Invalid email format';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  _buildSectionTitle(isArabic ? 'معلومات الحساب' : 'ACCOUNT DETAILS'),
                  SizedBox(height: 8.h),
                  ProfileAccountDetailsCard(user: user),
                  SizedBox(height: 32.h),
                  CustomButton(
                    text: isArabic ? 'حفظ التغييرات' : 'Save Changes',
                    isLoading: _isSaving,
                    icon: Icons.save_rounded,
                    onPressed: () => _handleSave(user, isArabic),
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, right: 4.w),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF80838D),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildLabel(String label, Color textPrimary) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13.5.sp,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required Color inputBg,
    required Color borderColor,
    required Color textSecondary,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13.5.sp, color: textSecondary.withValues(alpha: 0.7)),
      prefixIcon: Icon(icon, size: 20.sp, color: textSecondary),
      filled: true,
      fillColor: inputBg,
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
    );
  }
}
