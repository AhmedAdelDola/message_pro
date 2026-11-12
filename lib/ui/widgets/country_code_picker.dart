import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CountryInfo {
  final String name;
  final String nameAr;
  final String code; // e.g. "EG"
  final String dialCode; // e.g. "+20"
  final String flag; // Emoji flag

  const CountryInfo({
    required this.name,
    required this.nameAr,
    required this.code,
    required this.dialCode,
    required this.flag,
  });
}

const List<CountryInfo> allCountries = [
  CountryInfo(name: 'Egypt', nameAr: 'مصر', code: 'EG', dialCode: '+20', flag: '🇪🇬'),
  CountryInfo(name: 'Saudi Arabia', nameAr: 'المملكة العربية السعودية', code: 'SA', dialCode: '+966', flag: '🇸🇦'),
  CountryInfo(name: 'United Arab Emirates', nameAr: 'الإمارات العربية المتحدة', code: 'AE', dialCode: '+971', flag: '🇦🇪'),
  CountryInfo(name: 'Kuwait', nameAr: 'الكويت', code: 'KW', dialCode: '+965', flag: '🇰🇼'),
  CountryInfo(name: 'Qatar', nameAr: 'قطر', code: 'QA', dialCode: '+974', flag: '🇶🇦'),
  CountryInfo(name: 'Oman', nameAr: 'عمان', code: 'OM', dialCode: '+968', flag: '🇴🇲'),
  CountryInfo(name: 'Bahrain', nameAr: 'البحرين', code: 'BH', dialCode: '+973', flag: '🇧🇭'),
  CountryInfo(name: 'Jordan', nameAr: 'الأردن', code: 'JO', dialCode: '+962', flag: '🇯🇴'),
  CountryInfo(name: 'Iraq', nameAr: 'العراق', code: 'IQ', dialCode: '+964', flag: '🇮🇶'),
  CountryInfo(name: 'Lebanon', nameAr: 'لبنان', code: 'LB', dialCode: '+961', flag: '🇱🇧'),
  CountryInfo(name: 'Palestine', nameAr: 'فلسطين', code: 'PS', dialCode: '+970', flag: '🇵🇸'),
  CountryInfo(name: 'Syria', nameAr: 'سوريا', code: 'SY', dialCode: '+963', flag: '🇸🇾'),
  CountryInfo(name: 'Yemen', nameAr: 'اليمن', code: 'YE', dialCode: '+967', flag: '🇾🇪'),
  CountryInfo(name: 'Libya', nameAr: 'ليبيا', code: 'LY', dialCode: '+218', flag: '🇱🇾'),
  CountryInfo(name: 'Sudan', nameAr: 'السودان', code: 'SD', dialCode: '+249', flag: '🇸🇩'),
  CountryInfo(name: 'Morocco', nameAr: 'المغرب', code: 'MA', dialCode: '+212', flag: '🇲🇦'),
  CountryInfo(name: 'Algeria', nameAr: 'الجزائر', code: 'DZ', dialCode: '+213', flag: '🇩🇿'),
  CountryInfo(name: 'Tunisia', nameAr: 'تونس', code: 'TN', dialCode: '+216', flag: '🇹🇳'),
  CountryInfo(name: 'United States', nameAr: 'الولايات المتحدة', code: 'US', dialCode: '+1', flag: '🇺🇸'),
  CountryInfo(name: 'United Kingdom', nameAr: 'المملكة المتحدة', code: 'GB', dialCode: '+44', flag: '🇬🇧'),
  CountryInfo(name: 'Canada', nameAr: 'كندا', code: 'CA', dialCode: '+1', flag: '🇨🇦'),
  CountryInfo(name: 'Germany', nameAr: 'ألمانيا', code: 'DE', dialCode: '+49', flag: '🇩🇪'),
  CountryInfo(name: 'France', nameAr: 'فرنسا', code: 'FR', dialCode: '+33', flag: '🇫🇷'),
  CountryInfo(name: 'Italy', nameAr: 'إيطاليا', code: 'IT', dialCode: '+39', flag: '🇮🇹'),
  CountryInfo(name: 'Spain', nameAr: 'إسبانيا', code: 'ES', dialCode: '+34', flag: '🇪🇸'),
  CountryInfo(name: 'Turkey', nameAr: 'تركيا', code: 'TR', dialCode: '+90', flag: '🇹🇷'),
  CountryInfo(name: 'India', nameAr: 'الهند', code: 'IN', dialCode: '+91', flag: '🇮🇳'),
  CountryInfo(name: 'Pakistan', nameAr: 'باكستان', code: 'PK', dialCode: '+92', flag: '🇵🇰'),
  CountryInfo(name: 'China', nameAr: 'الصين', code: 'CN', dialCode: '+86', flag: '🇨🇳'),
  CountryInfo(name: 'Russia', nameAr: 'روسيا', code: 'RU', dialCode: '+7', flag: '🇷🇺'),
  CountryInfo(name: 'Australia', nameAr: 'أستراليا', code: 'AU', dialCode: '+61', flag: '🇦🇺'),
  CountryInfo(name: 'Brazil', nameAr: 'البرازيل', code: 'BR', dialCode: '+55', flag: '🇧🇷'),
  CountryInfo(name: 'Netherlands', nameAr: 'هولندا', code: 'NL', dialCode: '+31', flag: '🇳🇱'),
  CountryInfo(name: 'Sweden', nameAr: 'السويد', code: 'SE', dialCode: '+46', flag: '🇸🇪'),
  CountryInfo(name: 'Switzerland', nameAr: 'سويسرا', code: 'CH', dialCode: '+41', flag: '🇨🇭'),
  CountryInfo(name: 'Malaysia', nameAr: 'ماليزيا', code: 'MY', dialCode: '+60', flag: '🇲🇾'),
  CountryInfo(name: 'Indonesia', nameAr: 'إندونيسيا', code: 'ID', dialCode: '+62', flag: '🇮🇩'),
  CountryInfo(name: 'South Africa', nameAr: 'جنوب أفريقيا', code: 'ZA', dialCode: '+27', flag: '🇿🇦'),
  CountryInfo(name: 'Nigeria', nameAr: 'نيجيريا', code: 'NG', dialCode: '+234', flag: '🇳🇬'),
];

CountryInfo getCountryByCode(String code) {
  return allCountries.firstWhere(
    (c) => c.code.toUpperCase() == code.toUpperCase(),
    orElse: () => allCountries.first,
  );
}

String normalizePhoneNumber(String rawPhone, CountryInfo selectedCountry) {
  final clean = rawPhone.replaceAll(RegExp(r'[\s\-\(\)]'), '').trim();
  if (clean.isEmpty) return '';

  // If user explicitly typed full international format with +
  if (clean.startsWith('+')) {
    return clean;
  }
  // If user typed 00... international format
  if (clean.startsWith('00')) {
    return '+${clean.substring(2)}';
  }

  final dial = selectedCountry.dialCode; // e.g. +20
  final dialDigits = dial.replaceAll('+', ''); // e.g. 20

  // If already starts with the country dial digits
  if (clean.startsWith(dialDigits)) {
    return '+$clean';
  }

  // If starts with leading 0 (like 010... or 050...), strip the leading 0
  if (clean.startsWith('0')) {
    return '$dial${clean.substring(1)}';
  }

  return '$dial$clean';
}

Future<CountryInfo?> showCountryPickerModal(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final bg = isDark ? AppColors.darkSurface : Colors.white;
  final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
  final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;
  final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

  return showModalBottomSheet<CountryInfo>(
    context: context,
    isScrollControlled: true,
    backgroundColor: bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final queryController = TextEditingController();
          List<CountryInfo> filtered = List.from(allCountries);

          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            expand: false,
            builder: (_, scrollController) {
              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isArabic ? 'اختر الدولة' : 'Select Country',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                            fontFamily: 'Gontserrat',
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, size: 20, color: textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextField(
                      controller: queryController,
                      style: TextStyle(color: textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: isArabic ? 'بحث بالاسم أو الكود (+966, Egypt...)' : 'Search country or code...',
                        hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.6), fontSize: 13),
                        prefixIcon: Icon(Icons.search_rounded, size: 20, color: textSecondary),
                        isDense: true,
                        filled: true,
                        fillColor: isDark ? const Color(0xFF161616) : const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor),
                        ),
                      ),
                      onChanged: (q) {
                        final term = q.trim().toLowerCase();
                        setModalState(() {
                          if (term.isEmpty) {
                            filtered = List.from(allCountries);
                          } else {
                            filtered = allCountries.where((c) {
                              return c.name.toLowerCase().contains(term) ||
                                  c.nameAr.contains(term) ||
                                  c.code.toLowerCase().contains(term) ||
                                  c.dialCode.contains(term);
                            }).toList();
                          }
                        });
                      },
                    ),
                  ),
                  const Divider(height: 16),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: borderColor.withValues(alpha: 0.5)),
                      itemBuilder: (context, index) {
                        final c = filtered[index];
                        return ListTile(
                          leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
                          title: Text(
                            isArabic ? c.nameAr : c.name,
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              fontFamily: 'Gontserrat',
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              c.dialCode,
                              style: const TextStyle(
                                color: AppColors.primaryLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          onTap: () => Navigator.pop(ctx, c),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    },
  );
}
