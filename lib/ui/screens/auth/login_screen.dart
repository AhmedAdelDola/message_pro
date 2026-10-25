import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../logic/auth/auth_cubit.dart';
import '../../../logic/auth/auth_state.dart';
import '../../widgets/custom_button.dart';
import '../main_layout.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _serverUrlController = TextEditingController();
  bool _obscurePassword = true;
  bool _showCustomServer = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _serverUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await context.read<AuthCubit>().login(
      email: _emailController.text,
      password: _passwordController.text,
      baseUrl: _showCustomServer && _serverUrlController.text.isNotEmpty
          ? _serverUrlController.text
          : null,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainLayout()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
            child: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, authState) {
                final isLoading = authState is AuthLoading;
                final errorMessage = authState is AuthError ? authState.message : null;

                return Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 76.r,
                          height: 76.r,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(18.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 15.r,
                                offset: Offset(0, 6.h),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.chat_bubble_rounded,
                            size: 40.r,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        'تسجيل الدخول',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textDarkPrimary,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'أهلاً بك مجدداً في Message Pro',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 32.h),

                      if (errorMessage != null) ...[
                        Container(
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: AppColors.danger, size: 20.r),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Text(
                                  errorMessage,
                                  style: TextStyle(color: AppColors.danger, fontSize: 13.sp),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20.h),
                      ],

                      Text('البريد الإلكتروني (Email)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp)),
                      SizedBox(height: 6.h),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: 'name@company.com',
                          prefixIcon: Icon(Icons.email_outlined, size: 20.r),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'يرجى إدخال البريد الإلكتروني';
                          if (!val.contains('@')) return 'يرجى إدخال بريد إلكتروني صالح';
                          return null;
                        },
                      ),
                      SizedBox(height: 18.h),

                      Text('كلمة المرور (Password)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp)),
                      SizedBox(height: 6.h),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleLogin(),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: Icon(Icons.lock_outline, size: 20.r),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 20.r,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'يرجى إدخال كلمة المرور';
                          return null;
                        },
                      ),
                      SizedBox(height: 8.h),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                            );
                          },
                          child: Text('نسيت كلمة المرور؟', style: TextStyle(fontSize: 13.sp)),
                        ),
                      ),

                      Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: Text(
                            'إعدادات السيرفر المتقدمة (Advanced)',
                            style: TextStyle(fontSize: 13.sp, color: Colors.grey),
                          ),
                          onExpansionChanged: (exp) => setState(() => _showCustomServer = exp),
                          children: [
                            TextFormField(
                              controller: _serverUrlController,
                              decoration: InputDecoration(
                                hintText: 'https://omni.message-pro.com',
                                labelText: 'عنوان الخادم (Server URL)',
                                prefixIcon: Icon(Icons.dns_outlined, size: 20.r),
                              ),
                            ),
                            SizedBox(height: 12.h),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),

                      CustomButton(
                        text: 'تسجيل الدخول',
                        isLoading: isLoading,
                        onPressed: _handleLogin,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
