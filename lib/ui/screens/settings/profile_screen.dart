import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user.dart';
import '../../../logic/auth/auth_cubit.dart';
import '../../../logic/auth/auth_state.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/custom_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _displayNameController;
  late TextEditingController _emailController;

  String _selectedAvailability = 'online';
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _displayNameController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final user = context.read<AuthCubit>().currentUser;
      if (user != null) {
        _nameController.text = user.name;
        _displayNameController.text = user.displayName ?? '';
        _emailController.text = user.email;
        _selectedAvailability = user.availabilityStatus;
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
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
    final displayName = _displayNameController.text.trim();
    final email = _emailController.text.trim();
    final cubit = context.read<AuthCubit>();

    // 1. Update Profile (name, display_name, email)
    final profileResult = await cubit.updateProfile(
      name: name,
      displayName: displayName.isNotEmpty ? displayName : null,
      email: email,
    );

    if (!mounted) return;

    String? errorMessage;
    profileResult.fold(
      (failure) => errorMessage = failure.message,
      (_) {},
    );

    // 2. If availability changed, update it too
    if (errorMessage == null && _selectedAvailability != currentUser.availabilityStatus) {
      final availResult = await cubit.updateAvailability(_selectedAvailability);
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
          content: Text(
            errorMessage!,
            style: const TextStyle(fontFamily: 'Gontserrat', color: Colors.white),
          ),
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
                style: const TextStyle(fontFamily: 'Gontserrat', color: Colors.white),
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
        title: Text(
          isArabic ? 'الملف الشخصي' : 'Edit Profile',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: textPrimary,
            fontFamily: 'Gontserrat',
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
            // Keep controllers up to date if user state changes externally
            if (_nameController.text != authState.user.name) {
              _nameController.text = authState.user.name;
            }
            if (_displayNameController.text != (authState.user.displayName ?? '')) {
              _displayNameController.text = authState.user.displayName ?? '';
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
            return const Center(child: CircularProgressIndicator());
          }

          final statusColor = _getStatusColor(_selectedAvailability);

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Avatar Header with Status Ring
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 88.r,
                          height: 88.r,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: statusColor, width: 2.5),
                          ),
                          child: AvatarWidget(
                            avatarUrl: user.avatarUrl,
                            name: user.name,
                            size: 80,
                            showStatus: true,
                            availabilityStatus: _selectedAvailability,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          user.name,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                            fontFamily: 'Gontserrat',
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: textSecondary,
                            fontFamily: 'Gontserrat',
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 28.h),

                  // 2. Section: Availability Status
                  _buildSectionTitle(isArabic ? 'حالة التواجد' : 'AVAILABILITY STATUS'),
                  SizedBox(height: 8.h),
                  _buildAvailabilitySelector(cardBg, borderColor, textPrimary, textSecondary, isArabic),

                  SizedBox(height: 24.h),

                  // 3. Section: Personal Information
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
                        // Name
                        _buildLabel(isArabic ? 'الاسم الكامل *' : 'Full Name *', textPrimary),
                        SizedBox(height: 6.h),
                        TextFormField(
                          controller: _nameController,
                          style: TextStyle(fontSize: 14.sp, color: textPrimary, fontFamily: 'Gontserrat'),
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

                        // Display Name
                        _buildLabel(isArabic ? 'اسم العرض (اختياري)' : 'Display Name (Optional)', textPrimary),
                        SizedBox(height: 4.h),
                        Text(
                          isArabic
                              ? 'الاسم الذي يظهر للعملاء والمستخدمين في المحادثات'
                              : 'The name shown to customers and teammates in chat',
                          style: TextStyle(fontSize: 11.5.sp, color: textSecondary, fontFamily: 'Gontserrat'),
                        ),
                        SizedBox(height: 6.h),
                        TextFormField(
                          controller: _displayNameController,
                          style: TextStyle(fontSize: 14.sp, color: textPrimary, fontFamily: 'Gontserrat'),
                          decoration: _inputDecoration(
                            hint: isArabic ? 'أدخل اسم العرض' : 'e.g. John D.',
                            icon: Icons.badge_outlined,
                            inputBg: inputBg,
                            borderColor: borderColor,
                            textSecondary: textSecondary,
                          ),
                        ),

                        SizedBox(height: 16.h),

                        // Email
                        _buildLabel(isArabic ? 'البريد الإلكتروني *' : 'Email Address *', textPrimary),
                        SizedBox(height: 6.h),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(fontSize: 14.sp, color: textPrimary, fontFamily: 'Gontserrat'),
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

                  // 4. Section: Account Info (Read-only)
                  _buildSectionTitle(isArabic ? 'معلومات الحساب' : 'ACCOUNT DETAILS'),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        _buildReadOnlyRow(
                          label: isArabic ? 'الدور الوظيفي' : 'Role',
                          value: user.role.toUpperCase(),
                          icon: Icons.security_rounded,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        Divider(color: borderColor, height: 16.h),
                        _buildReadOnlyRow(
                          label: isArabic ? 'معرّف الحساب النشط' : 'Active Account ID',
                          value: '#${user.accountId}',
                          icon: Icons.tag_rounded,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        Divider(color: borderColor, height: 16.h),
                        _buildReadOnlyRow(
                          label: isArabic ? 'عدد مساحات العمل' : 'Workspaces',
                          value: '${user.accounts.length}',
                          icon: Icons.business_rounded,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32.h),

                  // 5. Submit Button
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
          fontFamily: 'Gontserrat',
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
        fontFamily: 'Gontserrat',
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
      hintStyle: TextStyle(
        fontSize: 13.5.sp,
        color: textSecondary.withValues(alpha: 0.7),
        fontFamily: 'Gontserrat',
      ),
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

  Widget _buildAvailabilitySelector(
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    bool isArabic,
  ) {
    final options = [
      {
        'key': 'online',
        'label': isArabic ? 'متصل' : 'Online',
        'color': const Color(0xFF2CA54A),
      },
      {
        'key': 'busy',
        'label': isArabic ? 'مشغول' : 'Busy',
        'color': const Color(0xFFFA8900),
      },
      {
        'key': 'offline',
        'label': isArabic ? 'غير متصل' : 'Offline',
        'color': const Color(0xFF80838D),
      },
    ];

    return Container(
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = _selectedAvailability == opt['key'];
          final color = opt['color'] as Color;

          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedAvailability = opt['key'] as String;
                });
              },
              borderRadius: BorderRadius.circular(10.r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: isSelected ? color : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8.r,
                      height: 8.r,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      opt['label'] as String,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? color : textSecondary,
                        fontFamily: 'Gontserrat',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReadOnlyRow({
    required String label,
    required String value,
    required IconData icon,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: textSecondary),
          SizedBox(width: 10.w),
          Text(
            label,
            style: TextStyle(
              color: textSecondary,
              fontSize: 13.sp,
              fontFamily: 'Gontserrat',
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13.sp,
              color: textPrimary,
              fontFamily: 'Gontserrat',
            ),
          ),
        ],
      ),
    );
  }
}
