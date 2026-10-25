import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../logic/auth/auth_cubit.dart';
import '../../../logic/auth/auth_state.dart';
import '../../../logic/conversation/conversation_cubit.dart';

class WorkspacesScreen extends StatelessWidget {
  const WorkspacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مساحات العمل (Workspaces)'),
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final user = authState is Authenticated ? authState.user : null;
          final accounts = user?.accounts ?? [];

          if (accounts.isEmpty) {
            return Center(child: Text('لا توجد مساحات عمل إضافية', style: TextStyle(fontSize: 14.sp)));
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.r),
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              final isActive = account.id == user?.accountId;

              return Card(
                margin: EdgeInsets.only(bottom: 10.h),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 20.r,
                    backgroundColor: isActive
                        ? AppColors.primary
                        : Colors.grey.withValues(alpha: 0.2),
                    child: Icon(
                      Icons.business_rounded,
                      color: isActive ? Colors.white : Colors.grey,
                      size: 20.r,
                    ),
                  ),
                  title: Text(
                    account.name,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                  subtitle: Text('الدور: ${account.role} • #${account.id}', style: TextStyle(fontSize: 12.sp)),
                  trailing: isActive
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryLight)
                      : null,
                  onTap: () async {
                    if (!isActive) {
                      await context.read<AuthCubit>().switchAccount(account.id);
                      if (context.mounted) {
                        context.read<ConversationCubit>().loadConversations();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('تم التبديل إلى ${account.name}')),
                        );
                      }
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
