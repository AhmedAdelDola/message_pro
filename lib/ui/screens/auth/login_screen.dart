import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:message_pro/core/constants/app_colors.dart';
import 'package:message_pro/logic/auth/auth_cubit.dart';
import 'package:message_pro/logic/auth/auth_state.dart';
import 'package:message_pro/logic/settings/settings_cubit.dart';
import 'package:message_pro/ui/screens/main_layout.dart';
import 'forgot_password_screen.dart';
import 'widgets/login_header.dart';
import 'widgets/google_sign_in_button.dart';
import 'widgets/auth_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isGoogleLoading = false;
  static bool _isGoogleInitialized = false;

  static const String _googleWebClientId =
      '547711081497-r275qot546as6q3b86km8p594mfejhmg.apps.googleusercontent.com';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await context.read<AuthCubit>().login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainLayout()),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      if (!_isGoogleInitialized) {
        await GoogleSignIn.instance.initialize(
          serverClientId: _googleWebClientId,
          clientId: kIsWeb ? _googleWebClientId : null,
        );
        _isGoogleInitialized = true;
      }

      final GoogleSignInAccount account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not retrieve Google ID token / تعذر الحصول على رمز Google'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (mounted) {
        final success = await context.read<AuthCubit>().loginWithGoogle(idToken);
        if (success && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainLayout()),
          );
        }
      }
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In (${e.code}): ${e.description ?? ""}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = context.watch<SettingsCubit>().state.locale;
    final isArabic = locale.languageCode == 'ar';

    final backgroundColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;
    final textTertiary = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final inputBg = isDark ? AppColors.darkInputBg : AppColors.lightInputBg;
    const accentColor = AppColors.primary;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 460.w),
              child: BlocBuilder<AuthCubit, AuthState>(
                builder: (context, authState) {
                  final isLoading = authState is AuthLoading;
                  final errorMessage = authState is AuthError ? authState.message : null;

                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LoginHeader(
                          isArabic: isArabic,
                          isDark: isDark,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          onLanguageToggle: () {
                            final next = isArabic ? const Locale('en') : const Locale('ar');
                            context.read<SettingsCubit>().setLocale(next);
                          },
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          isArabic ? 'تسجيل الدخول إلى Message Pro' : 'Sign in to Message Pro',
                          textAlign: isArabic ? TextAlign.right : TextAlign.left,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        if (errorMessage != null) ...[
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                            margin: EdgeInsets.only(bottom: 16.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF382E).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(7.r),
                              border: Border.all(color: const Color(0xFFFF382E).withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: const Color(0xFFFF382E), size: 18.r),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    errorMessage,
                                    style: TextStyle(
                                      color: const Color(0xFFFF382E),
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        AuthTextField(
                          label: isArabic ? 'البريد الإلكتروني' : 'Email',
                          controller: _emailController,
                          hintText: isArabic ? 'name@company.com' : 'Email',
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return isArabic ? 'يرجى إدخال البريد الإلكتروني' : 'Email is required';
                            }
                            if (!val.contains('@')) {
                              return isArabic ? 'يرجى إدخال بريد إلكتروني صالح' : 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 14.h),
                        AuthTextField(
                          label: isArabic ? 'كلمة المرور' : 'Password',
                          controller: _passwordController,
                          hintText: '••••••••',
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleLogin(),
                          suffixIcon: IconButton(
                            icon: _buildEyeIcon(textTertiary),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            splashRadius: 18.r,
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return isArabic ? 'يرجى إدخال كلمة المرور' : 'Password is required';
                            }
                            if (val.length < 6) {
                              return isArabic
                                  ? 'يجب أن لا تقل كلمة المرور عن 6 أحرف'
                                  : 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 7.h),
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                                );
                              },
                              borderRadius: BorderRadius.circular(4.r),
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 2.h),
                                child: Text(
                                  isArabic ? 'نسيت كلمة المرور؟' : 'Forgot password?',
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 9.h),
                        SizedBox(
                          height: 45.h,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: accentColor.withValues(alpha: 0.6),
                              disabledForegroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7.r),
                              ),
                            ),
                            child: isLoading
                                ? SizedBox(
                                    width: 20.r,
                                    height: 20.r,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    isArabic ? 'تسجيل الدخول' : 'Login',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          child: Row(
                            children: [
                              Expanded(child: Divider(color: borderColor, height: 1)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12.w),
                                child: Text(
                                  isArabic ? 'أو' : 'or',
                                  style: TextStyle(
                                    color: textTertiary,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: borderColor, height: 1)),
                            ],
                          ),
                        ),
                        GoogleSignInButton(
                          isLoading: _isGoogleLoading,
                          isArabic: isArabic,
                          borderColor: borderColor,
                          inputBg: inputBg,
                          textPrimary: textPrimary,
                          onPressed: (_isGoogleLoading || isLoading) ? null : _handleGoogleSignIn,
                        ),
                        SizedBox(height: 36.h),
                        Text(
                          isArabic
                              ? 'ليس لديك حساب؟ سجل عبر جهاز الكمبيوتر.'
                              : 'No account? Sign up on your desktop.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textTertiary,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEyeIcon(Color color) {
    final assetName = _obscurePassword
        ? 'assets/icons/eye-closed-stroke-rounded.svg'
        : 'assets/icons/eye-stroke-rounded.svg';

    return SvgPicture.asset(
      assetName,
      width: 20.r,
      height: 20.r,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      errorBuilder: (_, __, ___) => Icon(
        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: color,
        size: 20.r,
      ),
    );
  }
}
