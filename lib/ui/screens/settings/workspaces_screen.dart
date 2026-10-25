import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/conversation_provider.dart';

class WorkspacesScreen extends ConsumerWidget {
  const WorkspacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final accounts = user?.accounts ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('مساحات العمل (Workspaces)'),
      ),
      body: accounts.isEmpty
          ? const Center(child: Text('لا توجد مساحات عمل إضافية'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final account = accounts[index];
                final isActive = account.id == user?.accountId;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isActive
                          ? AppColors.primary
                          : Colors.grey.withValues(alpha: 0.2),
                      child: Icon(
                        Icons.business_rounded,
                        color: isActive ? Colors.white : Colors.grey,
                      ),
                    ),
                    title: Text(
                      account.name,
                      style: TextStyle(
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                    subtitle: Text('الدور: ${account.role} • #${account.id}'),
                    trailing: isActive
                        ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryLight)
                        : null,
                    onTap: () async {
                      if (!isActive) {
                        await ref.read(authProvider.notifier).switchAccount(account.id);
                        ref.read(conversationProvider.notifier).loadConversations();
                        if (context.mounted) {
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
            ),
    );
  }
}
