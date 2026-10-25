import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
        padding: EdgeInsets.all(20.r),
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
                  SizedBox(height: 12.h),
                  Text(
                    contact.name,
                    style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                  ),
                  if (contact.email != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      contact.email!,
                      style: TextStyle(fontSize: 14.sp, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 24.h),

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
                  SizedBox(width: 16.w),
                  _buildActionButton(
                    icon: Icons.chat_rounded,
                    label: 'واتساب',
                    onTap: () async {
                      final clean = contact.phoneNumber!.replaceAll(RegExp(r'[^0-9]'), '');
                      final uri = Uri.parse('https://wa.me/$clean');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                  ),
                  SizedBox(width: 16.w),
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
            SizedBox(height: 32.h),

            // Details List
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'المعلومات الأساسية',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
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
              SizedBox(height: 16.h),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'البيانات المخصصة (Custom Attributes)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
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
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryLight, size: 22.r),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
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
