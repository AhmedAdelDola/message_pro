import 'package:flutter/material.dart';
import 'package:message_pro/core/constants/app_colors.dart';
import 'package:message_pro/ui/widgets/country_code_picker.dart';

class ContactPhoneInputField extends StatelessWidget {
  final TextEditingController controller;
  final CountryInfo selectedCountry;
  final ValueChanged<CountryInfo> onCountryChanged;
  final String label;

  const ContactPhoneInputField({
    super.key,
    required this.controller,
    required this.selectedCountry,
    required this.onCountryChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final inputBg = isDark ? AppColors.darkSurface : AppColors.lightBackground;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                InkWell(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                  onTap: () async {
                    final picked = await showCountryPickerModal(context);
                    if (picked != null) {
                      onCountryChanged(picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: borderColor, width: 1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selectedCountry.flag,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          selectedCountry.dialCode,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: textSecondary),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '1012345678',
                      hintStyle: TextStyle(
                        color: textSecondary.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
