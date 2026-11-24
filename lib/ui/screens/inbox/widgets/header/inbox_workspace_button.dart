import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../logic/auth/auth_cubit.dart';
import '../../../../../logic/auth/auth_state.dart';

class InboxWorkspaceButton extends StatelessWidget {
  final VoidCallback onTap;

  const InboxWorkspaceButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final user = authState is Authenticated ? authState.user : null;
        final activeAccount = user != null && user.accounts.isNotEmpty
            ? user.accounts.firstWhere(
                (a) => a.id == user.accountId,
                orElse: () => user.accounts.first,
              )
            : null;
        final initial = (activeAccount?.name.trim().isNotEmpty == true)
            ? activeAccount!.name.trim()[0].toUpperCase()
            : 'E';

        return Tooltip(
          message: activeAccount?.name ?? (isArabic ? 'مساحة العمل' : 'Workspace'),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1F24) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF3B82F6), width: 1.6),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
