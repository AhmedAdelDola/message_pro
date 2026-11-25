import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class ContactDetailsIconBar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTabSelected;
  final bool isDark;

  const ContactDetailsIconBar({
    super.key,
    required this.activeIndex,
    required this.onTabSelected,
    required this.isDark,
  });

  static final List<List<List<dynamic>>> _icons = [
    HugeIcons.strokeRoundedUserAccount, // 0: Contact details
    HugeIcons.strokeRoundedCall02,      // 1: Calls
    HugeIcons.strokeRoundedAiChat02,    // 2: AI activity
    HugeIcons.strokeRoundedTag01,       // 3: Attachments
    HugeIcons.strokeRoundedTimer02,     // 4: Activities
    HugeIcons.strokeRoundedNote02,      // 5: Notes
    HugeIcons.strokeRoundedCalendar03,  // 6: Calendar
    HugeIcons.strokeRoundedStore01,     // 7: Commerce
  ];

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark
        ? const Color(0xFF2C2D32)
        : const Color(0xFF353C45).withValues(alpha: 0.16);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141518) : const Color(0xFFFEFEFE),
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_icons.length, (index) {
          final isActive = index == activeIndex;
          return InkWell(
            onTap: () => onTabSelected(index),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF4162E3)
                    : (isDark ? const Color(0xFF1C1D22) : Colors.white),
                borderRadius: BorderRadius.circular(8),
                border: isActive
                    ? null
                    : Border.all(color: borderColor, width: 1),
              ),
              child: HugeIcon(
                icon: _icons[index],
                size: 18,
                color: isActive
                    ? Colors.white
                    : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF282E34)),
              ),
            ),
          );
        }),
      ),
    );
  }
}
