import 'package:intl/intl.dart' hide TextDirection;

class BubbleHelpers {
  static String formatTime(DateTime dt, [bool isArabic = false]) {
    final hourMin = DateFormat('h:mm').format(dt);
    final amPm = dt.hour >= 12 ? (isArabic ? 'م' : 'PM') : (isArabic ? 'ص' : 'AM');
    return '$hourMin $amPm';
  }

  static String formatDate(DateTime dt, bool isArabic) {
    final now = DateTime.now();
    if (now.day == dt.day && now.month == dt.month && now.year == dt.year) {
      return isArabic ? 'اليوم' : 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (yesterday.day == dt.day && yesterday.month == dt.month && yesterday.year == dt.year) {
      return isArabic ? 'أمس' : 'Yesterday';
    }
    return DateFormat('MMM d, yyyy').format(dt);
  }

  static bool isArabicText(String text) {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return false;
    final arabicRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]');
    for (int i = 0; i < cleanText.length; i++) {
      final char = cleanText[i];
      if (RegExp(r'[a-zA-Z]').hasMatch(char)) {
        return false;
      }
      if (arabicRegex.hasMatch(char)) {
        return true;
      }
    }
    return false;
  }
}
