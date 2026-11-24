import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../data/models/message_template_registry.dart';
import '../../../../data/models/user.dart';
import '../../../../data/models/message.dart';
import 'send_template_modal.dart';
import 'composer/composer_recording_bar.dart';
import 'composer/composer_reply_banner.dart';
import 'composer/composer_restricted_banner.dart';
import 'composer/composer_suggestions_popup.dart';
import 'composer/composer_attachment_menu.dart';
import 'composer/composer_emoji_picker.dart';
import 'composer/composer_attachment_preview_bar.dart';
import 'composer/composer_snippet_service.dart';
import 'composer/composer_ai_summary_modal.dart';
import 'composer/composer_standard_input.dart';

class ChatComposer extends StatefulWidget {
  final Function(
    String text,
    bool isPrivate,
    List<String>? attachments, [
    int? inReplyToId,
  ]) onSend;
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
  final List<String> _attachedPaths = [];
  final ImagePicker _picker = ImagePicker();
  final ComposerSnippetService _snippetService = ComposerSnippetService();

  bool _isPrivateNote = false;
  bool _isSubmitting = false;
  AudioRecorder? _audioRecorder;
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _recordTimer;
  String? _currentRecordingPath;
  int _smartReplyIndex = 0;
  bool _isAttachingSnippet = false;

  String? _suggestionTrigger;
  String _suggestionQuery = '';
  int _triggerStartPos = -1;

  static const int maxAttachmentsLimit = 5;

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
      setState(() {
        _suggestionTrigger = '/';
        _suggestionQuery = currentToken.substring(1).toLowerCase().trim();
        _triggerStartPos = startOfToken;
      });
    } else if (currentToken.startsWith('@')) {
      setState(() {
        _suggestionTrigger = '@';
        _suggestionQuery = currentToken.substring(1).toLowerCase().trim();
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

  Future<void> insertSnippet({
    required String text,
    List<String> fileUrls = const [],
  }) async {
    if (text.isNotEmpty) {
      insertText(text);
    }
    if (fileUrls.isEmpty) return;

    setState(() => _isAttachingSnippet = true);

    final paths = await _snippetService.downloadSnippetFiles(
      fileUrls: fileUrls,
      currentAttachedCount: _attachedPaths.length,
      maxLimit: maxAttachmentsLimit,
    );

    if (mounted) {
      setState(() {
        for (final p in paths) {
          if (!_attachedPaths.contains(p) && _attachedPaths.length < maxAttachmentsLimit) {
            _attachedPaths.add(p);
          }
        }
        _isAttachingSnippet = false;
      });
      if (_attachedPaths.length >= maxAttachmentsLimit) {
        _showLimitReachedNotice();
      }
    }
  }

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
            if (!_attachedPaths.contains(path)) _attachedPaths.add(path);
          }
        });
      }
    } catch (_) {
      try {
        final images = await _picker.pickMultiImage(imageQuality: 80, limit: remaining);
        if (images.isNotEmpty) {
          final toAdd = images.take(remaining).map((f) => f.path).toList();
          setState(() {
            for (final path in toAdd) {
              if (!_attachedPaths.contains(path)) _attachedPaths.add(path);
            }
          });
        }
      } catch (_) {}
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
        if (!_attachedPaths.contains(picked.path)) _attachedPaths.add(picked.path);
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
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result != null && result.files.isNotEmpty) {
        final validPaths = result.files.map((f) => f.path).whereType<String>().toList();
        final toAdd = validPaths.take(remaining).toList();
        if (validPaths.length > remaining) {
          _showLimitExceededWarning(validPaths.length, toAdd.length);
        }
        setState(() {
          for (final path in toAdd) {
            if (!_attachedPaths.contains(path)) _attachedPaths.add(path);
          }
        });
      }
    } catch (_) {}
  }

  void _showAttachmentMenu() {
    if (_attachedPaths.length >= maxAttachmentsLimit) {
      _showLimitReachedNotice();
      return;
    }
    ComposerAttachmentMenu.show(
      context: context,
      onPickMedia: _pickMedia,
      onPickCamera: () => _pickImage(ImageSource.camera),
      onPickFile: _pickFile,
    );
  }

  void _showEmojiPicker() {
    ComposerEmojiPicker.show(
      context: context,
      onSelectEmoji: insertText,
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
    _controller.selection = TextPosition(offset: _controller.text.length) as TextSelection;
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
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && _isRecording) {
          setState(() => _recordDuration++);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic ? 'فشل بدء التسجيل: $e' : 'Failed to start recording: $e',
            ),
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
        if (await f.exists()) await f.delete();
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
    ComposerAiSummaryModal.show(
      context: context,
      onAddPrivateNote: (summary) {
        setState(() => _isPrivateNote = true);
        insertText(summary);
      },
    );
  }

  void _handleSend() {
    if (_isSubmitting) return;

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

    _isSubmitting = true;
    final pathsToSend = _attachedPaths.isNotEmpty
        ? List<String>.from(_attachedPaths.take(maxAttachmentsLimit))
        : null;
    final inReplyTo = widget.replyingToMessage?.id;
    final isPrivate = _isPrivateNote;

    _controller.clear();
    setState(() {
      _attachedPaths.clear();
      _isPrivateNote = false;
    });

    widget.onSend(text, isPrivate, pathsToSend, inReplyTo);
    widget.onCancelReply?.call();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final bool isRestricted = !widget.canReply && !_isPrivateNote;

    final containerBg = isDark ? const Color(0xFF0F1012) : const Color(0xFFF9FAFB);
    final borderColor = isDark ? const Color(0xFF23252A) : const Color(0xFFE5E7EB);
    final textPrimary = isDark ? const Color(0xFFEDEEF0) : const Color(0xFF282E34);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF626F7F);

    final hasContent = _controller.text.trim().isNotEmpty || _attachedPaths.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: containerBg,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ComposerSuggestionsPopup(
              suggestionTrigger: _suggestionTrigger,
              suggestionQuery: _suggestionQuery,
              cannedResponses: widget.cannedResponses,
              agents: widget.agents,
              isDark: isDark,
              isArabic: isArabic,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              onSelectCannedResponse: _selectCannedResponse,
              onSelectAgentMention: _selectAgentMention,
            ),
            if (widget.replyingToMessage != null)
              ComposerReplyBanner(
                replyingToMessage: widget.replyingToMessage,
                isDark: isDark,
                isArabic: isArabic,
                onCancelReply: widget.onCancelReply,
              ),
            ComposerAttachmentPreviewBar(
              attachedPaths: _attachedPaths,
              maxAttachmentsLimit: maxAttachmentsLimit,
              isAttachingSnippet: _isAttachingSnippet,
              onRemove: (index) => setState(() => _attachedPaths.removeAt(index)),
            ),
            if (isRestricted)
              ComposerRestrictedBanner(
                channelType: widget.channelType,
                channelName: widget.channelName,
                isDark: isDark,
                isArabic: isArabic,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onOpenTemplates: widget.onOpenTemplates ?? _showTemplatesSheet,
              )
            else
              ComposerStandardInput(
                isDark: isDark,
                isArabic: isArabic,
                isPrivateNote: _isPrivateNote,
                channelName: widget.channelName,
                channelType: widget.channelType,
                controller: _controller,
                focusNode: _focusNode,
                isRecording: _isRecording,
                recordingBar: ComposerRecordingBar(
                  recordDuration: _recordDuration,
                  isDark: isDark,
                  isArabic: isArabic,
                  onCancel: _cancelRecording,
                  onSend: _stopAndSendRecording,
                ),
                isSending: widget.isSending,
                hasContent: hasContent,
                onSmartReply: _handleSmartReplyPrediction,
                onOpenCannedResponses: widget.onOpenCannedResponses,
                onOpenEmojiPicker: _showEmojiPicker,
                onOpenAttachmentMenu: _showAttachmentMenu,
                onStartRecording: _startRecording,
                onSend: _handleSend,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => setState(() => _isPrivateNote = !_isPrivateNote),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedNote01,
                            size: 16,
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
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _handleSummarize,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedSparkles,
                            size: 15,
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
