import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../data/models/message_template_registry.dart';
import 'send_template_modal.dart';

class ChatComposer extends StatefulWidget {
  final Function(String text, bool isPrivate, List<String>? attachments) onSend;
  final VoidCallback onOpenCannedResponses;
  final bool isSending;
  final String channelName;
  final String channelType;
  final bool canReply;
  final VoidCallback? onOpenTemplates;

  const ChatComposer({
    super.key,
    required this.onSend,
    required this.onOpenCannedResponses,
    this.isSending = false,
    this.channelName = 'WhatsApp',
    this.channelType = 'whatsapp',
    this.canReply = true,
    this.onOpenTemplates,
  });

  @override
  State<ChatComposer> createState() => ChatComposerState();
}

class ChatComposerState extends State<ChatComposer> {
  final _controller = TextEditingController();
  bool _isPrivateNote = false;
  final List<String> _attachedPaths = [];
  final ImagePicker _picker = ImagePicker();

  AudioRecorder? _audioRecorder;
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _recordTimer;
  String? _currentRecordingPath;
  int _smartReplyIndex = 0;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _audioRecorder?.dispose();
    _controller.dispose();
    super.dispose();
  }

  void insertText(String text) {
    final current = _controller.text;
    _controller.text = current.isEmpty ? text : '$current $text';
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
    setState(() {});
  }

  Future<void> insertSnippet({required String text, List<String> fileUrls = const []}) async {
    insertText(text);

    if (fileUrls.isEmpty) return;

    try {
      final tempDir = await getTemporaryDirectory();
      final authHeaders = await SecureStorageService().getAuthHeaders();
      final headers = <String, String>{};
      if (authHeaders != null) {
        if (authHeaders['access-token'] != null) headers['access-token'] = authHeaders['access-token']!;
        if (authHeaders['client'] != null) headers['client'] = authHeaders['client']!;
        if (authHeaders['uid'] != null) headers['uid'] = authHeaders['uid']!;
      }

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 25),
        receiveTimeout: const Duration(seconds: 35),
        headers: headers,
        followRedirects: true,
        validateStatus: (status) => status != null && status < 400,
      ));

      for (int i = 0; i < fileUrls.length; i++) {
        final url = fileUrls[i].trim();
        if (url.isEmpty) continue;

        try {
          final cleanUrl = url.split('?').first;
          final lastSegment = cleanUrl.split('/').last;
          String ext = lastSegment.contains('.') ? lastSegment.split('.').last.toLowerCase() : '';
          if (ext.length > 5 || ext.isEmpty) {
            ext = 'png';
          }

          final fileName = 'snippet_${DateTime.now().millisecondsSinceEpoch}_$i.$ext';
          final file = File('${tempDir.path}/$fileName');

          final response = await dio.get<List<int>>(
            url,
            options: Options(responseType: ResponseType.bytes),
          );

          if (response.data != null && response.data!.isNotEmpty) {
            await file.writeAsBytes(response.data!);
            if (mounted) {
              setState(() {
                if (!_attachedPaths.contains(file.path)) {
                  _attachedPaths.add(file.path);
                }
              });
            }
          }
        } catch (e) {
          debugPrint('Error downloading snippet file ($url): $e');
        }
      }
    } catch (e) {
      debugPrint('Error in insertSnippet: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() => _attachedPaths.add(picked.path));
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() => _attachedPaths.add(result.files.single.path!));
    }
  }

  void _showAttachmentMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF161616) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF31343A) : const Color(0xFFEAEAEA),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4162E3).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedImage01,
                    color: Color(0xFF4162E3),
                    size: 20,
                  ),
                ),
                title: Text(
                  isArabic ? 'معرض الصور' : 'Photo Gallery',
                  style: const TextStyle(fontFamily: 'Gontserrat', fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4162E3).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCamera01,
                    color: Color(0xFF4162E3),
                    size: 20,
                  ),
                ),
                title: Text(
                  isArabic ? 'الكاميرا' : 'Camera',
                  style: const TextStyle(fontFamily: 'Gontserrat', fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4162E3).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedFile01,
                    color: Color(0xFF4162E3),
                    size: 20,
                  ),
                ),
                title: Text(
                  isArabic ? 'ملف / مستند' : 'Document / File',
                  style: const TextStyle(fontFamily: 'Gontserrat', fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEmojiPicker() {
    final emojis = [
      '👍', '👋', '❤️', '😊', '🙏', '🔥', '🎉', '👏', '✅', '✨',
      '🤝', '😃', '💯', '👌', '🎯', '🙌', '⭐', '💐', '💪', '🚀'
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return SafeArea(
          child: Container(
            color: isDark ? const Color(0xFF161616) : Colors.white,
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              alignment: WrapAlignment.center,
              children: emojis.map((e) {
                return InkWell(
                  onTap: () {
                    insertText(e);
                    Navigator.pop(ctx);
                  },
                  child: Text(e, style: const TextStyle(fontSize: 28)),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChannelLogo({double size = 16}) {
    final lower = widget.channelType.toLowerCase();

    // 1. WhatsApp
    if (lower.contains('whatsapp') ||
        lower.contains('twilio') ||
        lower.contains('message-pro') ||
        widget.channelName.toLowerCase().contains('message-pro') ||
        widget.channelName.toLowerCase().contains('whatsapp')) {
      return Image.asset(
        'assets/images/channels/whatsapp.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Color(0xFF25D366),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.chat_bubble, size: size * 0.55, color: Colors.white),
        ),
      );
    }

    // 2. Facebook / Messenger
    if (lower.contains('facebook') || lower.contains('messenger')) {
      return Image.asset(
        'assets/images/channels/messenger.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Color(0xFF0084FF),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.bolt_rounded, size: size * 0.65, color: Colors.white),
        ),
      );
    }

    // 3. Instagram
    if (lower.contains('instagram')) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
          ),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.camera_alt_rounded, size: size * 0.6, color: Colors.white),
      );
    }

    // 4. Telegram
    if (lower.contains('telegram')) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFF2AABEE),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.send_rounded, size: size * 0.55, color: Colors.white),
      );
    }

    // 5. Email
    if (lower.contains('email')) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFFEA4335),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.mail_rounded, size: size * 0.6, color: Colors.white),
      );
    }

    // 6. Website / Web Widget
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF4162E3),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.language_rounded, size: size * 0.6, color: Colors.white),
    );
  }

  void _handleSmartReplyPrediction() {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final suggestions = isArabic
        ? [
            'أهلاً بحضرتك، يسعدنا تواصلك مع مسج برو! كيف يمكنني مساعدتك اليوم؟',
            'تمام يا فندم، متاح لحضرتك توضيح أي تفاصيل بخصوص باقاتنا وتفعيل الأرقام.',
            'تم استلام استفسارك وجاري مراجعته والرد على حضرتك فوراً.',
            'يسعدنا تقديم الدعم، هل تحب نحدد موعد اتصال لشرح المنصة وتجربتها؟',
          ]
        : [
            'Hello! Glad to connect with you. How can I assist you today?',
            'Sure thing! I can explain all details about our packages and setup.',
            'Your request has been received and we are looking into it right away.',
            'Would you like to schedule a quick call to walk you through the platform?',
          ];

    final text = suggestions[_smartReplyIndex % suggestions.length];
    _smartReplyIndex++;

    _controller.text = text;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
    setState(() {});

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isArabic
                    ? 'تم وضع الرد المتوقع في خانة الكتابة، يمكنك تعديله وإرساله'
                    : 'Suggested reply placed in input field. You can review and send.',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _startRecording() async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    try {
      _audioRecorder ??= AudioRecorder();

      final hasPermission = await _audioRecorder!.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic
                    ? 'يرجى منح إذن استخدام الميكروفون لتسجيل الصوت'
                    : 'Microphone permission required to record audio',
              ),
            ),
          );
        }
        return;
      }

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder!.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );

      setState(() {
        _isRecording = true;
        _recordDuration = 0;
        _currentRecordingPath = path;
      });

      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && _isRecording) {
          setState(() => _recordDuration++);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic ? 'فشل بدء التسجيل: $e' : 'Failed to start recording: $e'),
          ),
        );
      }
    }
  }

  Future<void> _cancelRecording() async {
    try {
      _recordTimer?.cancel();
      if (_isRecording && _audioRecorder != null) {
        await _audioRecorder!.stop();
      }
      if (_currentRecordingPath != null) {
        final f = File(_currentRecordingPath!);
        if (await f.exists()) {
          await f.delete();
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isRecording = false;
        _recordDuration = 0;
        _currentRecordingPath = null;
      });
    }
  }

  Future<void> _stopAndSendRecording() async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    try {
      _recordTimer?.cancel();
      String? finalPath;
      if (_audioRecorder != null) {
        finalPath = await _audioRecorder!.stop();
      }
      finalPath ??= _currentRecordingPath;

      if (finalPath != null && await File(finalPath).exists()) {
        if (_recordDuration < 1) {
          await File(finalPath).delete();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isArabic ? 'التسجيل قصير جداً' : 'Recording too short'),
                duration: const Duration(seconds: 1),
              ),
            );
          }
        } else {
          widget.onSend('', _isPrivateNote, [finalPath]);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic ? 'فشل حفظ التسجيل: $e' : 'Failed to save recording: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordDuration = 0;
          _currentRecordingPath = null;
        });
      }
    }
  }

  Widget _buildRecordingBar(bool isDark, bool isArabic) {
    final minutes = (_recordDuration ~/ 60).toString().padLeft(2, '0');
    final seconds = (_recordDuration % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$minutes:$seconds',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Gontserrat',
              color: Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isArabic ? 'جاري تسجيل صوتي...' : 'Recording voice note...',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontFamily: 'Gontserrat',
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 22),
            tooltip: isArabic ? 'إلغاء' : 'Cancel',
            onPressed: _cancelRecording,
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: _stopAndSendRecording,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.send_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTemplatesSheet() {
    SendTemplateModal.show(
      context: context,
      templates: MessageTemplateRegistry.approvedTemplates,
      onSend: (template) {
        widget.onSend(template.fullText, false, null);
      },
    );
  }

  void _handleSummarize() {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return SafeArea(
          child: Container(
            color: isDark ? const Color(0xFF161616) : Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedSparkles,
                      color: Color(0xFF7C3AED),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isArabic ? 'ملخص المحادثة بالذكاء الاصطناعي' : 'AI Conversation Summary',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Gontserrat'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF212121) : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E7EB)),
                  ),
                  child: Text(
                    isArabic
                        ? 'العميل مهتم بمعرفة أسعار وباقات Message Pro وميزات الربط مع واتساب وكول سنتر السحابي. تم إرسال العرض المبدئي ومطلوب متابعة للتأكيد.'
                        : 'Customer inquired about Message Pro pricing plans and integrations with WhatsApp & Cloud Call Center. Initial proposal shared; awaiting confirmation follow-up.',
                    style: const TextStyle(fontSize: 13, height: 1.45, fontFamily: 'Gontserrat'),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    final summary = isArabic
                        ? 'ملخص: العميل مهتم بباقات Message Pro وميزات الربط مع واتساب.'
                        : 'Summary: Customer inquired about Message Pro pricing & WhatsApp integration.';
                    setState(() => _isPrivateNote = true);
                    insertText(summary);
                    Navigator.pop(ctx);
                  },
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedNote01,
                    color: Colors.white,
                    size: 16,
                  ),
                  label: Text(isArabic ? 'إضافة كملاحظة خاصة' : 'Add as Private Note'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4162E3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty && _attachedPaths.isEmpty) {
      if (!widget.canReply && !_isPrivateNote) {
        if (widget.onOpenTemplates != null) {
          widget.onOpenTemplates!();
        } else {
          _showTemplatesSheet();
        }
      }
      return;
    }

    widget.onSend(
      text,
      _isPrivateNote,
      _attachedPaths.isNotEmpty ? List.from(_attachedPaths) : null,
    );

    _controller.clear();
    setState(() {
      _attachedPaths.clear();
      _isPrivateNote = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final bool isRestricted = !widget.canReply && !_isPrivateNote;

    final containerBg = isDark ? const Color(0xFF0F1012) : const Color(0xFFF9FAFB);
    final borderColor = isDark ? const Color(0xFF23252A) : const Color(0xFFE5E7EB);

    final inputBg = _isPrivateNote
        ? (isDark ? const Color(0xFF271904) : const Color(0xFFFFFBEB))
        : (isDark ? const Color(0xFF161616) : Colors.white);
    final inputBorder = _isPrivateNote
        ? (isDark ? const Color(0xFF78350F) : const Color(0xFFFCD34D))
        : (isDark ? const Color(0xFF282A30) : const Color(0xFFE2E8F0));

    final textPrimary = isDark ? const Color(0xFFEDEEF0) : const Color(0xFF282E34);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF626F7F);

    final hasContent = _controller.text.trim().isNotEmpty || _attachedPaths.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: containerBg,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Attached files preview bar
            if (_attachedPaths.isNotEmpty)
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _attachedPaths.length,
                  itemBuilder: (context, index) {
                    final path = _attachedPaths[index];
                    final isImage = path.endsWith('.png') ||
                        path.endsWith('.jpg') ||
                        path.endsWith('.jpeg') ||
                        path.endsWith('.webp');

                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF212121) : const Color(0xFFEAEAEA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isImage)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.file(File(path), width: 36, height: 36, fit: BoxFit.cover),
                            )
                          else
                            const HugeIcon(
                              icon: HugeIcons.strokeRoundedFile01,
                              color: Color(0xFF4162E3),
                              size: 24,
                            ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => setState(() => _attachedPaths.removeAt(index)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            // Main Input Box: 24h Pink Card (matching Web Image 1) OR Standard / Private Note Box
            if (isRestricted)
              _buildRestrictedComposer(isDark, isArabic, textPrimary, textSecondary)
            else
              _buildStandardComposer(isDark, isArabic, textPrimary, textSecondary, inputBg, inputBorder, hasContent),

            // Bottom Footer Bar (Add note & Summarize - outside the box)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: [
                  // Add note toggle
                  InkWell(
                    onTap: () => setState(() => _isPrivateNote = !_isPrivateNote),
                    borderRadius: BorderRadius.circular(6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedNote01,
                          size: 15,
                          color: _isPrivateNote ? const Color(0xFFD97706) : textPrimary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isPrivateNote
                              ? (isArabic ? 'إلغاء الملاحظة' : 'Cancel note')
                              : (isArabic ? 'إضافة ملاحظة خاصة' : 'Add private note'),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _isPrivateNote ? const Color(0xFFD97706) : textPrimary,
                            fontFamily: 'Gontserrat',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Summarize button
                  InkWell(
                    onTap: _handleSummarize,
                    borderRadius: BorderRadius.circular(6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedSparkles,
                          size: 14,
                          color: Color(0xFF7C3AED),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isArabic ? 'تلخيص AI' : 'AI Summary',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7C3AED),
                            fontFamily: 'Gontserrat',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Exact 24-hour restriction pink card matching Web CRM (Image 1: media_1793706051855_1ecc4df9.png)
  Widget _buildRestrictedComposer(
    bool isDark,
    bool isArabic,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C1519) : const Color(0xFFFFF0F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF501C24) : const Color(0xFFFECDD3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Channel Logo + Name + Dropdown
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                _buildChannelLogo(size: 16),
                const SizedBox(width: 6),
                Text(
                  widget.channelName,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                    fontFamily: 'Gontserrat',
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: textSecondary,
                ),
              ],
            ),
          ),

          // Middle Row: 24h Restriction warning with clickable underline
          InkWell(
            onTap: widget.onOpenTemplates ?? _showTemplatesSheet,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(Icons.info_rounded, size: 16, color: Color(0xFFE11D48)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFBE123C),
                          fontFamily: 'Gontserrat',
                        ),
                        children: [
                          TextSpan(
                            text: isArabic
                                ? 'يمكنك الرد على هذه المحادثة فقط باستخدام قالب رسالة نظراً لـ '
                                : 'You can only reply to this conversation using a template message due to ',
                          ),
                          TextSpan(
                            text: isArabic
                                ? 'قيد نافذة الـ 24 ساعة للرسائل'
                                : '24 hour message window restriction',
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Row inside pink box: (B) on left, disabled send airplane on right
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Row(
              children: [
                // (B Templates) WhatsApp Business Template Button (matching Crop 1 exactly)
                InkWell(
                  onTap: widget.onOpenTemplates ?? _showTemplatesSheet,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF132A1C) : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark ? const Color(0xFF166534) : const Color(0xFF86EFAC),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'B Templates',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF22C55E) : const Color(0xFF15803D),
                        fontFamily: 'Gontserrat',
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Inactive send airplane (matching web CRM)
                InkWell(
                  onTap: widget.onOpenTemplates ?? _showTemplatesSheet,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF242238) : const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedSent,
                      color: isDark ? const Color(0xFF818CF8) : const Color(0xFFA5B4FC),
                      size: 16,
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

  /// Standard composer for open 24h window OR private internal team note
  Widget _buildStandardComposer(
    bool isDark,
    bool isArabic,
    Color textPrimary,
    Color textSecondary,
    Color inputBg,
    Color inputBorder,
    bool hasContent,
  ) {
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
          // Private note top banner
          if (_isPrivateNote)
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
                      fontFamily: 'Gontserrat',
                    ),
                  ),
                ],
              ),
            )
          else
            // Top Channel Row
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
              child: Row(
                children: [
                  _buildChannelLogo(size: 15),
                  const SizedBox(width: 6),
                  Text(
                    widget.channelName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                      fontFamily: 'Gontserrat',
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 15,
                    color: textSecondary,
                  ),
                ],
              ),
            ),

          if (_isRecording)
            _buildRecordingBar(isDark, isArabic)
          else ...[
            // Text input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 110),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    fontSize: 14,
                    color: textPrimary,
                    fontFamily: 'Gontserrat',
                  ),
                  decoration: InputDecoration(
                    hintText: _isPrivateNote
                        ? (isArabic ? 'اكتب ملاحظة خاصة للفرق...' : 'Write a private note...')
                        : (isArabic ? 'اكتب رسالة...' : 'Type a message...'),
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: textSecondary.withValues(alpha: 0.75),
                      fontFamily: 'Gontserrat',
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
                  // Suggest reply button (icon-only with purple accent)
                  InkWell(
                    onTap: _handleSmartReplyPrediction,
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

                  // Canned Responses / Snippets (with official bubble chat delay icon)
                  IconButton(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedBubbleChatDelay,
                      size: 20,
                      color: textSecondary,
                    ),
                    padding: const EdgeInsets.all(5),
                    constraints: const BoxConstraints(),
                    tooltip: isArabic ? 'الردود الجاهزة' : 'Canned responses',
                    onPressed: widget.onOpenCannedResponses,
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
                    onPressed: _showEmojiPicker,
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
                    onPressed: _showAttachmentMenu,
                  ),
                  const SizedBox(width: 2),

                  // Microphone Voice Note (matching Crop 5)
                  IconButton(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedMic01,
                      size: 19,
                      color: textSecondary,
                    ),
                    padding: const EdgeInsets.all(5),
                    constraints: const BoxConstraints(),
                    tooltip: isArabic ? 'تسجيل رسالة صوتية' : 'Record voice note',
                    onPressed: _startRecording,
                  ),
                  const Spacer(),

                  // Send Button
                InkWell(
                  onTap: _handleSend,
                  borderRadius: BorderRadius.circular(999),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _isPrivateNote
                          ? const Color(0xFFF59E0B)
                          : (hasContent
                              ? const Color(0xFF4162E3)
                              : const Color(0xFF6366F1)),
                      shape: BoxShape.circle,
                    ),
                    child: widget.isSending
                        ? const Center(
                            child: SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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
