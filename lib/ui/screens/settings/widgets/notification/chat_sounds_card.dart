import 'package:flutter/material.dart';
import 'package:message_pro/core/constants/app_colors.dart';
import 'package:message_pro/core/services/sound_service.dart';

class ChatSoundsCard extends StatefulWidget {
  const ChatSoundsCard({super.key});

  @override
  State<ChatSoundsCard> createState() => _ChatSoundsCardState();
}

class _ChatSoundsCardState extends State<ChatSoundsCard> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final textSecondary = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'أصوات المحادثات المباشرة' : 'In-App Chat Sounds',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeTrackColor: AppColors.primary,
            activeThumbColor: Colors.white,
            title: Text(
              isArabic ? 'نغمات الرسائل الواردة والمرسلة' : 'Message Sent & Received Tones',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            subtitle: Text(
              isArabic
                  ? 'تشغيل مؤثر صوتي عند استقبال أو إرسال أي رسالة داخل التطبيق.'
                  : 'Play sound effects for incoming and outgoing messages while using the app.',
              style: TextStyle(
                fontSize: 12.5,
                color: textSecondary,
              ),
            ),
            value: SoundService().isSoundEnabled,
            onChanged: (val) async {
              await SoundService().setSoundEnabled(val);
              setState(() {});
              if (val) {
                SoundService().playIncomingSound();
              }
            },
          ),
          if (SoundService().isSoundEnabled) ...[
            const SizedBox(height: 12),
            Divider(color: borderColor, height: 1),
            const SizedBox(height: 14),
            Text(
              isArabic ? 'نغمة الرسائل الواردة' : 'Incoming Message Tone',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isArabic
                  ? 'اضغط على أي نغمة لاختيارها وسماعها فوراً:'
                  : 'Tap any sound to select and preview it:',
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            ...SoundService.availableSounds.map((sound) {
              final isSelected = SoundService().selectedSound == sound.id;
              return InkWell(
                onTap: () async {
                  await SoundService().setSound(sound.id);
                  await SoundService().playPreview(sound.id);
                  setState(() {});
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : (isDark ? const Color(0xFF1E2024) : const Color(0xFFF7F8FA)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : borderColor,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? const Color(0xFF282A2E) : const Color(0xFFE9EBEF)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          sound.icon,
                          size: 16,
                          color: isSelected ? Colors.white : textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isArabic ? sound.nameAr : sound.nameEn,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppColors.primary : textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.play_circle_fill_rounded,
                          color: isSelected ? AppColors.primary : textSecondary,
                          size: 22,
                        ),
                        tooltip: isArabic ? 'استماع' : 'Listen',
                        onPressed: () {
                          SoundService().playPreview(sound.id);
                        },
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : textSecondary.withValues(alpha: 0.5),
                            width: 2,
                          ),
                          color: isSelected ? AppColors.primary : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 12, color: Colors.white)
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
