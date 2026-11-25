import 'package:flutter/material.dart';

class ContactCallsTabView extends StatelessWidget {
  final bool isDark;
  final bool isArabic;

  const ContactCallsTabView({
    super.key,
    required this.isDark,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark
        ? const Color(0xFF2C2D32)
        : const Color(0xFF353C45).withValues(alpha: 0.16);
    final primaryText = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF282E34);
    final secondaryText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF626F7F);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1D22) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.phone_outlined, size: 28, color: secondaryText),
              const SizedBox(height: 10),
              Text(
                isArabic ? 'المكالمات' : 'Call',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: primaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isArabic ? 'قريباً' : 'Coming soon',
                style: TextStyle(fontSize: 13, color: secondaryText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
