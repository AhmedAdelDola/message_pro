import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../data/models/user.dart';
import '../../../logic/auth/auth_cubit.dart';
import '../../../logic/auth/auth_state.dart';
import '../../../logic/conversation/conversation_cubit.dart';

class WorkspacesScreen extends StatelessWidget {
  const WorkspacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final cardBg = isDark ? const Color(0xFF161616) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF0D0D0D);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB);

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'مساحات العمل' : 'Workspaces'),
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final user = authState is Authenticated ? authState.user : null;
          final accounts = user?.accounts ?? [];
          final currentAccountId = user?.accountId;

          if (accounts.isEmpty) {
            return Center(
              child: Text(
                isArabic ? 'لا توجد مساحات عمل إضافية' : 'No workspaces available',
                style: TextStyle(fontSize: 14.sp, color: textSecondary),
              ),
            );
          }

          final hasExplicitOrg = accounts.any((a) =>
              (a.organizationName != null && a.organizationName!.trim().isNotEmpty) ||
              [' - ', ' | ', ' / ', ' : ', ' — '].any((sep) => a.name.contains(sep)));

          final defaultOrgName = hasExplicitOrg
              ? (isArabic ? 'مساحات عمل أخرى' : 'Other Workspaces')
              : (isArabic ? 'المؤسسة الرئيسية' : 'Main Organization');

          final Map<String, List<Account>> groupedAccounts = {};
          for (final account in accounts) {
            final org = account.getEffectiveOrgName(defaultOrgName);
            groupedAccounts.putIfAbsent(org, () => []).add(account);
          }

          return ListView(
            padding: EdgeInsets.all(16.r),
            children: [
              for (final entry in groupedAccounts.entries) ...[
                Padding(
                  padding: EdgeInsets.only(top: 12.h, bottom: 8.h),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(4.r),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4162E3).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Icon(
                          Icons.domain_rounded,
                          size: 16.r,
                          color: const Color(0xFF4162E3),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF262626) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          '${entry.value.length} ${isArabic ? (entry.value.length == 1 ? 'مساحة' : 'مساحات') : (entry.value.length == 1 ? 'workspace' : 'workspaces')}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                for (final account in entry.value) ...[
                  Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: InkWell(
                      onTap: () async {
                        final isActive = account.id == currentAccountId;
                        if (!isActive) {
                          await context.read<AuthCubit>().switchAccount(account.id);
                          if (!context.mounted) return;
                          await context.read<ConversationCubit>().onWorkspaceSwitched(account.id);
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isArabic
                                    ? 'تم التبديل إلى ${account.name}'
                                    : 'Switched to ${account.name}',
                              ),
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: (account.id == currentAccountId)
                              ? (isDark
                                  ? const Color(0xFF131D2D)
                                  : const Color(0xFFEFF6FF))
                              : (isDark
                                  ? const Color(0xFF1E1F24)
                                  : cardBg),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: (account.id == currentAccountId)
                                ? const Color(0xFF4162E3)
                                : borderColor,
                            width: (account.id == currentAccountId) ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40.r,
                              height: 40.r,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF131D2D)
                                    : ((account.id == currentAccountId)
                                        ? Colors.white
                                        : const Color(0xFFEFF6FF)),
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: const Color(0xFF4162E3),
                                  width: 1.5,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                account.name.trim().isNotEmpty
                                    ? account.name.trim()[0].toUpperCase()
                                    : 'E',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF4162E3),
                                ),
                              ),
                            ),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    account.name,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: (account.id == currentAccountId)
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: (account.id == currentAccountId)
                                          ? const Color(0xFF4162E3)
                                          : textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 3.h),
                                  Row(
                                    children: [
                                      Text(
                                        '#${account.id}',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: textSecondary,
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 6.w, vertical: 2.h),
                                        decoration: BoxDecoration(
                                          color: (isDark
                                              ? Colors.white10
                                              : Colors.black.withValues(alpha: 0.05)),
                                          borderRadius: BorderRadius.circular(4.r),
                                        ),
                                        child: Text(
                                          account.role.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.w600,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (account.id == currentAccountId)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4162E3)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 14.r,
                                      color: const Color(0xFF4162E3),
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      isArabic ? 'الحالية' : 'Active',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF4162E3),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Icon(
                                isArabic
                                    ? Icons.keyboard_arrow_left_rounded
                                    : Icons.keyboard_arrow_right_rounded,
                                color: textSecondary,
                                size: 20.r,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}
