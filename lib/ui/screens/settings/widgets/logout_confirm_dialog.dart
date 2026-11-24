import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:message_pro/logic/auth/auth_cubit.dart';
import 'package:message_pro/ui/screens/auth/login_screen.dart';

class LogoutConfirmDialog {
  static void show(BuildContext context, bool isArabic) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isArabic ? 'تسجيل الخروج' : 'Log Out'),
        content: Text(
          isArabic ? 'هل أنت متأكد أنك تريد تسجيل الخروج؟' : 'Are you sure you want to log out?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthCubit>().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: Text(
              isArabic ? 'تسجيل الخروج' : 'Log Out',
              style: const TextStyle(color: Color(0xFFFF382E), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
