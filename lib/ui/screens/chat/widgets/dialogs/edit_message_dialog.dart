import 'package:flutter/material.dart';
import '../../../../../data/models/message.dart';

class EditMessageDialog extends StatefulWidget {
  final Message message;
  final Future<String?> Function(int messageId, String newText) onSave;

  const EditMessageDialog({
    super.key,
    required this.message,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required Message message,
    required Future<String?> Function(int messageId, String newText) onSave,
  }) {
    return showDialog(
      context: context,
      builder: (_) => EditMessageDialog(
        message: message,
        onSave: onSave,
      ),
    );
  }

  @override
  State<EditMessageDialog> createState() => _EditMessageDialogState();
}

class _EditMessageDialogState extends State<EditMessageDialog> {
  late final TextEditingController _textController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.message.content ?? '');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remaining = widget.message.messageActions.remainingEditTime;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF161616) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.edit_rounded, color: Color(0xFF4162E3), size: 22),
          const SizedBox(width: 8),
          Text(
            isArabic ? 'تعديل الرسالة' : 'Edit Message',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (remaining != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isArabic
                          ? 'متاح للتعديل خلال ${remaining.inMinutes} دقيقة'
                          : 'Editable for ${remaining.inMinutes} minutes',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFFF59E0B), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          TextField(
            controller: _textController,
            maxLines: 4,
            minLines: 2,
            autofocus: true,
            decoration: InputDecoration(
              hintText: isArabic ? 'اكتب النص الجديد هنا...' : 'Enter new message text...',
              filled: true,
              fillColor: isDark ? const Color(0xFF262626) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isDark ? const Color(0xFF383838) : const Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF4162E3), width: 1.5),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text(isArabic ? 'إلغاء' : 'Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4162E3),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(isArabic ? 'حفظ التعديل' : 'Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final newText = _textController.text.trim();
    if (newText.isEmpty) return;
    setState(() => _isSaving = true);

    final error = await widget.onSave(widget.message.id, newText);

    if (mounted) {
      if (error != null) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        Navigator.pop(context);
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic ? 'تم تعديل الرسالة بنجاح' : 'Message edited successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
