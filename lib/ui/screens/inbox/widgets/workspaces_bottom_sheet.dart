import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/user.dart';
import '../../../../logic/auth/auth_cubit.dart';
import '../../../../logic/auth/auth_state.dart';
import '../../../../logic/conversation/conversation_cubit.dart';
import 'workspace/workspace_group_header.dart';
import 'workspace/workspace_account_tile.dart';

/// Clean bottom sheet for switching active workspace/account.
/// Follows Single Responsibility Principle by orchestrating WorkspaceGroupHeader and WorkspaceAccountTile.
class WorkspacesBottomSheet extends StatelessWidget {
  final VoidCallback onWorkspaceSwitched;

  const WorkspacesBottomSheet({super.key, required this.onWorkspaceSwitched});

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onWorkspaceSwitched,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF161616) : Colors.white;

    return showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          WorkspacesBottomSheet(onWorkspaceSwitched: onWorkspaceSwitched),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final textPrimary = isDark
        ? const Color(0xFFFAFAFA)
        : const Color(0xFF0D0D0D);
    final textSecondary = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final borderColor = isDark
        ? const Color(0xFF262626)
        : const Color(0xFFE5E7EB);

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final user = authState is Authenticated ? authState.user : null;
        final accounts = user?.accounts ?? [];
        final currentAccountId = user?.accountId;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF333333)
                          : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4162E3).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.business_rounded,
                        color: Color(0xFF4162E3),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic ? 'مساحات العمل' : 'Workspaces',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isArabic
                                ? 'اختر مساحة العمل التي ترغب بالتبديل إليها'
                                : 'Select the workspace you want to switch to',
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: textSecondary,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (accounts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        isArabic
                            ? 'لا توجد مساحات عمل إضافية'
                            : 'No workspaces available',
                        style: TextStyle(color: textSecondary, fontSize: 13.5),
                      ),
                    ),
                  )
                else
                  _buildGroupedWorkspaces(
                    context,
                    accounts,
                    currentAccountId,
                    isDark,
                    isArabic,
                    borderColor,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupedWorkspaces(
    BuildContext context,
    List<Account> accounts,
    int? currentAccountId,
    bool isDark,
    bool isArabic,
    Color borderColor,
  ) {
    final hasExplicitOrg = accounts.any(
      (a) =>
          (a.organizationName != null &&
              a.organizationName!.trim().isNotEmpty) ||
          [
            ' - ',
            ' | ',
            ' / ',
            ' : ',
            ' — ',
          ].any((sep) => a.name.contains(sep)),
    );

    final defaultOrgName = hasExplicitOrg
        ? (isArabic ? 'مساحات عمل أخرى' : 'Other Workspaces')
        : (isArabic ? 'المؤسسة الرئيسية' : 'Main Organization');

    final Map<String, List<Account>> groupedAccounts = {};
    for (final account in accounts) {
      final org = account.getEffectiveOrgName(defaultOrgName);
      groupedAccounts.putIfAbsent(org, () => []).add(account);
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final entry in groupedAccounts.entries) ...[
            WorkspaceGroupHeader(
              title: entry.key,
              count: entry.value.length,
              isDark: isDark,
              isArabic: isArabic,
            ),
            for (final account in entry.value)
              WorkspaceAccountTile(
                account: account,
                isActive: account.id == currentAccountId,
                isDark: isDark,
                isArabic: isArabic,
                borderColor: borderColor,
                onTap: () async {
                  if (account.id != currentAccountId) {
                    Navigator.pop(context);
                    onWorkspaceSwitched();
                    await context.read<AuthCubit>().switchAccount(account.id);
                    if (!context.mounted) return;
                    await context.read<ConversationCubit>().onWorkspaceSwitched(
                      account.id,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isArabic
                              ? 'تم التبديل إلى ${account.name}'
                              : 'Switched to ${account.name}',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
          ],
        ],
      ),
    );
  }
}
