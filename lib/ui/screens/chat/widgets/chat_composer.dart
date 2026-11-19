import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/constants/app_lottie.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../data/models/message_template_registry.dart';
import '../../../../data/models/user.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../data/models/message.dart';
import 'send_template_modal.dart';

class ChatComposer extends StatefulWidget {
  final Function(String text, bool isPrivate, List<String>? attachments, [int? inReplyToId]) onSend;
  final VoidCallback onOpenCannedResponses;
  final bool isSending;
  final String channelName;
  final String channelType;
  final bool canReply;
  final VoidCallback? onOpenTemplates;
  final List<Map<String, String>> cannedResponses;
  final List<User> agents;
  final Message? replyingToMessage;
  final VoidCallback? onCancelReply;

  const ChatComposer({
    super.key,
    required this.onSend,
    required this.onOpenCannedResponses,
    this.isSending = false,
    this.channelName = 'WhatsApp',
    this.channelType = 'whatsapp',
    this.canReply = true,
    this.onOpenTemplates,
    this.cannedResponses = const [],
    this.agents = const [],
    this.replyingToMessage,
    this.onCancelReply,
  });

  @override
  State<ChatComposer> createState() => ChatComposerState();
}

class ChatComposerState extends State<ChatComposer> {
  final _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isPrivateNote = false;
  final List<String> _attachedPaths = [];
  final ImagePicker _picker = ImagePicker();

  AudioRecorder? _audioRecorder;
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _recordTimer;
  String? _currentRecordingPath;
  int _smartReplyIndex = 0;

  bool _isAttachingSnippet = false;
  String? _suggestionTrigger; // '/' or '@'
  String _suggestionQuery = '';
  int _triggerStartPos = -1;

  void focusInput() {
    _focusNode.requestFocus();
  }

  @override
  void didUpdateWidget(ChatComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.replyingToMessage != null &&
        oldWidget.replyingToMessage?.id != widget.replyingToMessage?.id) {
      _focusNode.requestFocus();
    }
  }

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _audioRecorder?.dispose();
    _focusNode.dispose();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;
    final selection = _controller.selection;

    if (!selection.isValid || selection.baseOffset < 0) {
      if (_suggestionTrigger != null) {
        setState(() => _suggestionTrigger = null);
      }
      return;
    }

    final cursor = selection.baseOffset;
    final textBefore = text.substring(0, cursor);

    final lastWhitespace = textBefore.lastIndexOf(RegExp(r'\s'));
    final startOfToken = lastWhitespace == -1 ? 0 : lastWhitespace + 1;
    final currentToken = textBefore.substring(startOfToken);

    if (currentToken.startsWith('/') && !_isPrivateNote) {
      final q = currentToken.substring(1).toLowerCase().trim();
      setState(() {
        _suggestionTrigger = '/';
        _suggestionQuery = q;
        _triggerStartPos = startOfToken;
      });
    } else if (currentToken.startsWith('@')) {
      final q = currentToken.substring(1).toLowerCase().trim();
      setState(() {
        _suggestionTrigger = '@';
        _suggestionQuery = q;
        _triggerStartPos = startOfToken;
      });
    } else {
      if (_suggestionTrigger != null) {
        setState(() {
          _suggestionTrigger = null;
          _suggestionQuery = '';
          _triggerStartPos = -1;
        });
      }
    }
  }

  void _selectCannedResponse(Map<String, String> item) {
    final content = item['content'] ?? '';
    final rawFiles = item['files'] ?? '';
    final imageUrl = item['image_url'];
    final fileUrls = rawFiles.isNotEmpty
        ? rawFiles.split('|||').where((u) => u.trim().isNotEmpty).toList()
        : (imageUrl != null && imageUrl.isNotEmpty ? [imageUrl] : <String>[]);

    final text = _controller.text;
    final cursor = _controller.selection.baseOffset;
    final prefix = _triggerStartPos >= 0 ? text.substring(0, _triggerStartPos) : '';
    final suffix = (cursor >= 0 && cursor <= text.length) ? text.substring(cursor) : '';

    final newText = '$prefix$content $suffix'.trim();
    _controller.text = newText;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: (prefix.length + content.length + 1).clamp(0, newText.length)),
    );

    setState(() {
      _suggestionTrigger = null;
      _suggestionQuery = '';
      _triggerStartPos = -1;
    });

    if (fileUrls.isNotEmpty) {
      insertSnippet(text: '', fileUrls: fileUrls);
    }
  }

  void _selectAgentMention(User agent) {
    final mentionText = '@${agent.name} ';
    final text = _controller.text;
    final cursor = _controller.selection.baseOffset;
    final prefix = _triggerStartPos >= 0 ? text.substring(0, _triggerStartPos) : '';
    final suffix = (cursor >= 0 && cursor <= text.length) ? text.substring(cursor) : '';

    final newText = '$prefix$mentionText$suffix';
    _controller.text = newText;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: (prefix.length + mentionText.length).clamp(0, newText.length)),
    );

    setState(() {
      _suggestionTrigger = null;
      _suggestionQuery = '';
      _triggerStartPos = -1;
    });
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
    if (text.isNotEmpty) {
      insertText(text);
    }

    if (fileUrls.isEmpty) return;

    setState(() => _isAttachingSnippet = true);

    try {
      final tempDir = await getTemporaryDirectory();
      final base = await SecureStorageService().getBaseUrl();
      final uri = Uri.tryParse(base.isNotEmpty ? base : AppConfig.defaultBaseUrl);
      final domainRoot = uri != null ? '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}' : AppConfig.defaultBaseUrl;

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
        if (_attachedPaths.length >= maxAttachmentsLimit) {
          _showLimitReachedNotice();
          break;
        }
        var url = fileUrls[i].trim();
        if (url.isEmpty) continue;
        if (url.startsWith('/')) {
          url = '$domainRoot$url';
        }

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
    } finally {
      if (mounted) {
        setState(() => _isAttachingSnippet = false);
      }
    }
  }

  static const int maxAttachmentsLimit = 5;

  void _showLimitReachedNotice() {
    if (!mounted) return;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic
              ? 'الحد الأقصى للإرسال هو 5 ملفات أو صور في المرة الواحدة'
              : 'Maximum 5 files or images allowed per message',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLimitExceededWarning(int selectedCount, int addedCount) {
    if (!mounted) return;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic
              ? 'تم إضافة أول $addedCount فقط للوصول للحد الأقصى (5 ملفات)'
              : 'Only first $addedCount items added to reach limit (5 max)',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickMedia() async {
    final remaining = maxAttachmentsLimit - _attachedPaths.length;
    if (remaining <= 0) {
      _showLimitReachedNotice();
      return;
    }

    try {
      final pickedList = await _picker.pickMultipleMedia(
        imageQuality: 80,
        limit: remaining,
      );

      if (pickedList.isNotEmpty) {
        final toAdd = pickedList.take(remaining).map((f) => f.path).toList();
        if (pickedList.length > remaining) {
          _showLimitExceededWarning(pickedList.length, toAdd.length);
        }
        setState(() {
          for (final path in toAdd) {
            if (!_attachedPaths.contains(path)) {
              _attachedPaths.add(path);
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking multiple media: $e');
      try {
        final images = await _picker.pickMultiImage(
          imageQuality: 80,
          limit: remaining,
        );
        if (images.isNotEmpty) {
          final toAdd = images.take(remaining).map((f) => f.path).toList();
          setState(() {
            for (final path in toAdd) {
              if (!_attachedPaths.contains(path)) {
                _attachedPaths.add(path);
              }
            }
          });
        }
      } catch (e2) {
        debugPrint('Fallback pickMultiImage error: $e2');
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final remaining = maxAttachmentsLimit - _attachedPaths.length;
    if (remaining <= 0) {
      _showLimitReachedNotice();
      return;
    }
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() {
        if (!_attachedPaths.contains(picked.path)) {
          _attachedPaths.add(picked.path);
        }
      });
    }
  }

  Future<void> _pickFile() async {
    final remaining = maxAttachmentsLimit - _attachedPaths.length;
    if (remaining <= 0) {
      _showLimitReachedNotice();
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final validPaths = result.files.map((f) => f.path).whereType<String>().toList();
        final toAdd = validPaths.take(remaining).toList();
        if (validPaths.length > remaining) {
          _showLimitExceededWarning(validPaths.length, toAdd.length);
        }
        setState(() {
          for (final path in toAdd) {
            if (!_attachedPaths.contains(path)) {
              _attachedPaths.add(path);
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking files: $e');
    }
  }

  void _showAttachmentMenu() {
    if (_attachedPaths.length >= maxAttachmentsLimit) {
      _showLimitReachedNotice();
      return;
    }

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
                  isArabic ? 'الصور والفيديوهات' : 'Photos & Videos',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  isArabic ? 'اختيار من المعرض (حتى 5 عناصر)' : 'Select from gallery (up to 5)',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickMedia();
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
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  isArabic ? 'التقاط صورة مباشرة' : 'Take a photo directly',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
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
                  isArabic ? 'المستندات والملفات' : 'Documents & Files',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  isArabic ? 'PDF، Word، Excel والمستندات الأخرى' : 'PDF, Word, Excel, and other files',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
              const SizedBox(height: 8),
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
          widget.onSend('', _isPrivateNote, [finalPath], widget.replyingToMessage?.id);
          widget.onCancelReply?.call();
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          AppLottie.voiceRecording(
            width: 26,
            height: 26,
          ),
          const SizedBox(width: 8),
          Text(
            '$minutes:$seconds',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
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
        widget.onSend(template.fullText, false, null, null);
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
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
                    style: const TextStyle(fontSize: 13, height: 1.45),
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
      _attachedPaths.isNotEmpty ? List<String>.from(_attachedPaths.take(maxAttachmentsLimit)) : null,
      widget.replyingToMessage?.id,
    );

    widget.onCancelReply?.call();

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
            // Autocomplete Popup for '/' (Canned responses) and '@' (Mentions)
            _buildSuggestionsPopup(isDark, isArabic, textPrimary, textSecondary),

            // Quoted Reply Banner
            if (widget.replyingToMessage != null)
              _buildReplyBanner(isDark, isArabic),

            // Attached files preview bar & loading indicator
            if (_attachedPaths.isNotEmpty || _isAttachingSnippet)
              Container(
                height: 58,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (_attachedPaths.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Center(
                          child: Text(
                            '${_attachedPaths.length}/$maxAttachmentsLimit',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    if (_isAttachingSnippet)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isArabic ? 'جاري إرفاق صورة الرد الجاهز...' : 'Attaching snippet image...',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ...List.generate(_attachedPaths.length, (index) {
                      final path = _attachedPaths[index];
                      final name = path.split(Platform.pathSeparator).last.split('/').last;
                      final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
                      final isImage = ['png', 'jpg', 'jpeg', 'webp', 'gif'].contains(ext);
                      final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'].contains(ext);
                      final isAudio = ['mp3', 'wav', 'ogg', 'm4a', 'aac'].contains(ext);

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
                                child: Image.file(File(path), width: 38, height: 38, fit: BoxFit.cover),
                              )
                            else if (isVideo)
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5CF6),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 20),
                              )
                            else if (isAudio)
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF06B6D4),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(Icons.audiotrack_rounded, color: Colors.white, size: 20),
                              )
                            else
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(Icons.insert_drive_file_rounded, color: Colors.white, size: 20),
                              ),
                            const SizedBox(width: 4),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 80),
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
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
                    }),
                  ],
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
                  focusNode: _focusNode,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    fontSize: 14,
                    color: textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: _isPrivateNote
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

  Widget _buildReplyBanner(bool isDark, bool isArabic) {
    final msg = widget.replyingToMessage;
    if (msg == null) return const SizedBox.shrink();

    final isSenderMe = msg.isOutgoing;
    final senderName = isSenderMe
        ? (isArabic ? 'أنت' : 'You')
        : (msg.senderName ?? (isArabic ? 'العميل' : 'Customer'));

    String contentPreview = '';
    if (msg.content != null && msg.content!.trim().isNotEmpty) {
      contentPreview = msg.content!.trim();
    } else if (msg.attachments.isNotEmpty) {
      final type = msg.attachments.first.fileType.toLowerCase();
      if (type == 'image') {
        contentPreview = isArabic ? '📷 صورة' : '📷 Photo';
      } else if (type == 'video') {
        contentPreview = isArabic ? '🎥 فيديو' : '🎥 Video';
      } else if (type == 'audio') {
        contentPreview = isArabic ? '🎵 تسجيل صوتي' : '🎵 Audio';
      } else {
        contentPreview = isArabic ? '📎 ملف مرفق' : '📎 Attachment';
      }
    } else {
      contentPreview = isArabic ? 'رسالة' : 'Message';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2128) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          right: isArabic
              ? const BorderSide(color: Color(0xFF4162E3), width: 3.5)
              : BorderSide.none,
          left: !isArabic
              ? const BorderSide(color: Color(0xFF4162E3), width: 3.5)
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.reply_rounded,
            size: 18,
            color: Color(0xFF4162E3),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${isArabic ? 'الرد على' : 'Replying to'} $senderName',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4162E3),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  contentPreview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: isArabic ? 'إلغاء الرد' : 'Cancel reply',
            onPressed: widget.onCancelReply,
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsPopup(bool isDark, bool isArabic, Color textPrimary, Color textSecondary) {
    if (_suggestionTrigger == null) return const SizedBox.shrink();

    final isSlash = _suggestionTrigger == '/';

    if (isSlash) {
      final filtered = widget.cannedResponses.where((c) {
        if (_suggestionQuery.isEmpty) return true;
        final code = (c['short_code'] ?? '').toLowerCase();
        final content = (c['content'] ?? '').toLowerCase();
        return code.contains(_suggestionQuery) || content.contains(_suggestionQuery);
      }).toList();

      if (filtered.isEmpty) return const SizedBox.shrink();

      return Container(
        constraints: const BoxConstraints(maxHeight: 220),
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2128) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF2E333D) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF282C35) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF4162E3)),
                  const SizedBox(width: 6),
                  Text(
                    isArabic ? 'الردود الجاهزة (${filtered.length})' : 'Canned Responses (${filtered.length})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    isArabic ? 'اضغط للإدراج' : 'Tap to insert',
                    style: TextStyle(fontSize: 10.5, color: textSecondary),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: filtered.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: isDark ? const Color(0xFF2E333D) : const Color(0xFFF1F5F9),
                ),
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  final code = item['short_code'] ?? '';
                  final content = item['content'] ?? '';
                  final rawFiles = item['files'] ?? '';
                  final imageUrl = item['image_url'];
                  final hasImage = (imageUrl != null && imageUrl.isNotEmpty) || rawFiles.isNotEmpty;

                  return InkWell(
                    onTap: () => _selectCannedResponse(item),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4162E3).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '/$code',
                              style: const TextStyle(
                                color: Color(0xFF4162E3),
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              content,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          if (hasImage) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.image_outlined, size: 16, color: Color(0xFF4162E3)),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    } else {
      // Agent Mentions (@)
      final filtered = widget.agents.where((a) {
        if (_suggestionQuery.isEmpty) return true;
        final name = a.name.toLowerCase();
        final email = a.email.toLowerCase();
        return name.contains(_suggestionQuery) || email.contains(_suggestionQuery);
      }).toList();

      if (filtered.isEmpty) return const SizedBox.shrink();

      return Container(
        constraints: const BoxConstraints(maxHeight: 220),
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2128) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF2E333D) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF282C35) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.alternate_email_rounded, size: 16, color: Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  Text(
                    isArabic ? 'منشن أعضاء الفريق (${filtered.length})' : 'Mention Team Member (${filtered.length})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: filtered.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: isDark ? const Color(0xFF2E333D) : const Color(0xFFF1F5F9),
                ),
                itemBuilder: (context, index) {
                  final agent = filtered[index];
                  return InkWell(
                    onTap: () => _selectAgentMention(agent),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: const Color(0xFF4162E3).withValues(alpha: 0.15),
                            backgroundImage: agent.avatarUrl != null && agent.avatarUrl!.isNotEmpty
                                ? CachedNetworkImageProvider(agent.avatarUrl!)
                                : null,
                            child: agent.avatarUrl == null || agent.avatarUrl!.isEmpty
                                ? Text(
                                    agent.name.isNotEmpty ? agent.name[0].toUpperCase() : '?',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4162E3)),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  agent.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                                if (agent.email.isNotEmpty)
                                  Text(
                                    agent.email,
                                    style: TextStyle(fontSize: 11, color: textSecondary),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }
  }
}
