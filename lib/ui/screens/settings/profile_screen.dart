import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../logic/auth/auth_cubit.dart';
import '../../../logic/auth/auth_state.dart';
import '../../widgets/avatar_widget.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي (Profile)'),
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final user = authState is Authenticated ? authState.user : null;
          if (user == null) return const SizedBox();

          return ListView(
            padding: EdgeInsets.all(20.r),
            children: [
              Center(
                child: AvatarWidget(
                  avatarUrl: user.avatarUrl,
                  name: user.name,
                  size: 80,
                  showStatus: true,
                  isOnline: user.availabilityStatus == 'online',
                ),
              ),
              SizedBox(height: 24.h),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0.r),
                  child: Column(
                    children: [
                      _buildRow('الاسم', user.name),
                      const Divider(),
                      _buildRow('البريد الإلكتروني', user.email),
                      const Divider(),
                      _buildRow('الدور الوظيفي', user.role),
                      const Divider(),
                      _buildRow('حالة التواجد', user.availabilityStatus),
                      const Divider(),
                      _buildRow('رقم الحساب النشط', '#${user.accountId}'),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey, fontSize: 13.sp)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp)),
        ],
      ),
    );
  }
}
