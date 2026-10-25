import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/contact.dart';
import '../../widgets/avatar_widget.dart';

class ContactDetailsScreen extends StatelessWidget {
  final Contact contact;

  const ContactDetailsScreen({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل جهة الاتصال (Contact)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  AvatarWidget(
                    avatarUrl: contact.avatarUrl,
                    name: contact.name,
                    size: 80,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    contact.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (contact.email != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      contact.email!,
                      style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Quick Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (contact.phoneNumber != null) ...[
                  _buildActionButton(
                    icon: Icons.phone_rounded,
                    label: 'اتصال',
                    onTap: () async {
                      final uri = Uri.parse('tel:${contact.phoneNumber}');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    icon: Icons.chat_rounded,
                    label: 'واتساب',
                    onTap: () async {
                      final clean = contact.phoneNumber!.replaceAll(RegExp(r'[^0-9]'), '');
                      final uri = Uri.parse('https://wa.me/$clean');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                  ),
                  const SizedBox(width: 16),
                ],
                if (contact.email != null)
                  _buildActionButton(
                    icon: Icons.email_rounded,
                    label: 'إيميل',
                    onTap: () async {
                      final uri = Uri.parse('mailto:${contact.email}');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 32),

            // Details List
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'المعلومات الأساسية',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const Divider(),
                    _buildInfoRow('الاسم', contact.name),
                    _buildInfoRow('رقم الهاتف', contact.phoneNumber ?? 'غير متوفر'),
                    _buildInfoRow('البريد الإلكتروني', contact.email ?? 'غير متوفر'),
                    if (contact.identifier != null)
                      _buildInfoRow('المعرف', contact.identifier!),
                  ],
                ),
              ),
            ),

            if (contact.customAttributes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'البيانات المخصصة (Custom Attributes)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const Divider(),
                      ...contact.customAttributes.entries.map((entry) {
                        return _buildInfoRow(entry.key, entry.value.toString());
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryLight, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
