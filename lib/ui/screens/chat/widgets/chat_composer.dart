import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/constants/app_colors.dart';

class ChatComposer extends StatefulWidget {
  final Function(String text, bool isPrivate, List<String>? attachments) onSend;
  final VoidCallback onOpenCannedResponses;
  final bool isSending;

  const ChatComposer({
    super.key,
    required this.onSend,
    required this.onOpenCannedResponses,
    this.isSending = false,
  });

  @override
  State<ChatComposer> createState() => ChatComposerState();
}

class ChatComposerState extends State<ChatComposer> {
  final _controller = TextEditingController();
  bool _isPrivateNote = false;
  final List<String> _attachedPaths = [];
  final ImagePicker _picker = ImagePicker();

  void insertText(String text) {
    final current = _controller.text;
    _controller.text = current.isEmpty ? text : '$current $text';
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primaryLight),
                title: const Text('معرض الصور (Gallery)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryLight),
                title: const Text('الكاميرا (Camera)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_file_rounded, color: AppColors.primaryLight),
                title: const Text('ملف / مستند (Document)'),
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

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty && _attachedPaths.isEmpty) return;

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

    return Container(
      decoration: BoxDecoration(
        color: _isPrivateNote
            ? (_isPrivateNote ? (isDark ? AppColors.privateNoteDark : AppColors.privateNoteLight) : Colors.transparent)
            : (isDark ? AppColors.darkCard : Colors.white),
        border: Border(
          top: BorderSide(
            color: _isPrivateNote
                ? AppColors.privateNoteBorder
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: _isPrivateNote ? 1.5 : 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Mode Banner (Private Note vs Reply)
            Row(
              children: [
                InkWell(
                  onTap: () => setState(() => _isPrivateNote = !_isPrivateNote),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isPrivateNote
                          ? AppColors.privateNoteBorder.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _isPrivateNote ? AppColors.privateNoteBorder : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isPrivateNote ? Icons.lock : Icons.lock_open,
                          size: 13,
                          color: _isPrivateNote ? AppColors.privateNoteBorder : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isPrivateNote ? 'ملاحظة داخلية (فريق العمل)' : 'رد على العميل',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _isPrivateNote ? AppColors.privateNoteBorder : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.flash_on_rounded, size: 20, color: AppColors.primaryLight),
                  tooltip: 'الردود الجاهزة (Canned Responses)',
                  onPressed: widget.onOpenCannedResponses,
                ),
              ],
            ),

            // Attached Files Preview
            if (_attachedPaths.isNotEmpty) ...[
              const SizedBox(height: 6),
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _attachedPaths.length,
                  itemBuilder: (context, index) {
                    final path = _attachedPaths[index];
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.attachment, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                path.split(RegExp(r'[\\/]')).last,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: -4,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => setState(() => _attachedPaths.removeAt(index)),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 6),
            // Text Input & Action Buttons
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 24),
                  color: AppColors.primaryLight,
                  onPressed: _showAttachmentMenu,
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF262626) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      controller: _controller,
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: _isPrivateNote ? 'اكتب ملاحظة خاصة لزملائك...' : 'اكتب رسالتك للعميل...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _isPrivateNote ? AppColors.privateNoteBorder : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: widget.isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 20, color: Colors.white),
                    onPressed: widget.isSending ? null : _handleSend,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
