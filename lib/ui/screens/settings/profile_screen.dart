import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/avatar_widget.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي (Profile)'),
      ),
      body: user == null
          ? const SizedBox()
          : ListView(
              padding: const EdgeInsets.all(20),
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
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
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
            ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
