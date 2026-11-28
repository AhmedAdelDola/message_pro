import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'composer_channel_logo.dart';

class ComposerStandardInput extends StatelessWidget {
  final bool isDark;
  final bool isArabic;
  final bool isPrivateNote;
  final String channelName;
  final String channelType;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isRecording;
  final Widget recordingBar;
  final bool isSending;
  final bool hasContent;
  final VoidCallback onSmartReply;
  final VoidCallback onOpenCannedResponses;
  final VoidCallback onOpenEmojiPicker;
  final VoidCallback onOpenAttachmentMenu;
  final VoidCallback onStartRecording;
  final VoidCallback onSend;

  const ComposerStandardInput({
    super.key,
    required this.isDark,
    required this.isArabic,
    required this.isPrivateNote,
    required this.channelName,
    required this.channelType,
    required this.controller,
    required this.focusNode,
    required this.isRecording,
    required this.recordingBar,
    required this.isSending,
    required this.hasContent,
    required this.onSmartReply,
    required this.onOpenCannedResponses,
    required this.onOpenEmojiPicker,
    required this.onOpenAttachmentMenu,
    required this.onStartRecording,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final inputBg = isPrivateNote
        ? (isDark ? const Color(0xFF271904) : const Color(0xFFFFFBEB))
        : (isDark ? const Color(0xFF161616) : Colors.white);
    final inputBorder = isPrivateNote
        ? (isDark ? const Color(0xFF78350F) : const Color(0xFFFCD34D))
        : (isDark ? const Color(0xFF282A30) : const Color(0xFFE2E8F0));

    final textPrimary = isDark ? const Color(0xFFEDEEF0) : const Color(0xFF282E34);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF626F7F);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: inputBorder, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top row: Private note banner or Channel logo
          if (isPrivateNote)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: Row(
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedNote01,
                    color: Color(0xFFD97706),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isArabic
                        ? 'ملاحظة خاصة (مرئية لفريق العمل فقط)'
                        : 'Private Note (internal team only)',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
              child: Row(
                children: [
                  ComposerChannelLogo(channelType: channelType, channelName: channelName, size: 15),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      channelName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: textSecondary),
                ],
              ),
            ),

          if (isRecording)
            recordingBar
          else ...[
            // Text input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 110),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: TextStyle(fontSize: 14, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: isPrivateNote
                        ? (isArabic ? 'اكتب ملاحظة خاصة للفرق...' : 'Write a private note...')
                        : (isArabic ? 'اكتب رسالة...' : 'Type a message...'),
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: textSecondary.withValues(alpha: 0.75),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),

            // Action Icons Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
              child: Row(
                children: [
                  // Smart reply
                  InkWell(
                    onTap: onSmartReply,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(5.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedSparkles,
                        size: 17,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Canned Responses
                  IconButton(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedBubbleChatDelay,
                      size: 20,
                      color: textSecondary,
                    ),
                    padding: const EdgeInsets.all(5),
                    constraints: const BoxConstraints(),
                    tooltip: isArabic ? 'الردود الجاهزة' : 'Canned responses',
                    onPressed: onOpenCannedResponses,
                  ),
                  const SizedBox(width: 2),

                  // Emoji picker
                  IconButton(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedSmile,
                      size: 19,
                      color: textSecondary,
                    ),
                    padding: const EdgeInsets.all(5),
                    constraints: const BoxConstraints(),
                    tooltip: isArabic ? 'إيموجي' : 'Emoji',
                    onPressed: onOpenEmojiPicker,
                  ),
                  const SizedBox(width: 2),

                  // Attachment menu
                  IconButton(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedAttachment01,
                      size: 19,
                      color: textSecondary,
                    ),
                    padding: const EdgeInsets.all(5),
                    constraints: const BoxConstraints(),
                    tooltip: isArabic ? 'إرفاق ملف' : 'Attach file',
                    onPressed: onOpenAttachmentMenu,
                  ),
                  const SizedBox(width: 2),

                  // Voice Recording
                  IconButton(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedMic01,
                      size: 19,
                      color: textSecondary,
                    ),
                    padding: const EdgeInsets.all(5),
                    constraints: const BoxConstraints(),
                    tooltip: isArabic ? 'تسجيل رسالة صوتية' : 'Record voice note',
                    onPressed: onStartRecording,
                  ),
                  const Spacer(),

                  // Send button
                  InkWell(
                    onTap: onSend,
                    borderRadius: BorderRadius.circular(999),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isPrivateNote
                            ? const Color(0xFFF59E0B)
                            : (hasContent ? const Color(0xFF4162E3) : const Color(0xFF6366F1)),
                        shape: BoxShape.circle,
                      ),
                      child: isSending
                          ? const Center(
                              child: SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : const Center(
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedSent,
                                color: Colors.white,
                                size: 17,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
