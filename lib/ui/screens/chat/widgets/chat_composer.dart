import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: AppColors.primaryLight, size: 22.r),
                title: Text('معرض الصور (Gallery)', style: TextStyle(fontSize: 14.sp)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt_outlined, color: AppColors.primaryLight, size: 22.r),
                title: Text('الكاميرا (Camera)', style: TextStyle(fontSize: 14.sp)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.attach_file_rounded, color: AppColors.primaryLight, size: 22.r),
                title: Text('ملف / مستند (Document)', style: TextStyle(fontSize: 14.sp)),
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
            ? (isDark ? AppColors.privateNoteDark : AppColors.privateNoteLight)
            : (isDark ? AppColors.darkCard : Colors.white),
        border: Border(
          top: BorderSide(
            color: _isPrivateNote
                ? AppColors.privateNoteBorder
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: _isPrivateNote ? 1.5.h : 1.h,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Mode Banner (Private Note vs Reply)
            Row(
              children: [
                InkWell(
                  onTap: () => setState(() => _isPrivateNote = !_isPrivateNote),
                  borderRadius: BorderRadius.circular(6.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: _isPrivateNote
                          ? AppColors.privateNoteBorder.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: _isPrivateNote ? AppColors.privateNoteBorder : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isPrivateNote ? Icons.lock : Icons.lock_open,
                          size: 13.r,
                          color: _isPrivateNote ? AppColors.privateNoteBorder : Colors.grey,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          _isPrivateNote ? 'ملاحظة داخلية (فريق العمل)' : 'رد على العميل',
                          style: TextStyle(
                            fontSize: 11.sp,
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
                  icon: Icon(Icons.flash_on_rounded, size: 20.r, color: AppColors.primaryLight),
                  tooltip: 'الردود الجاهزة (Canned Responses)',
                  onPressed: widget.onOpenCannedResponses,
                ),
              ],
            ),

            // Attached Files Preview
            if (_attachedPaths.isNotEmpty) ...[
              SizedBox(height: 6.h),
              SizedBox(
                height: 48.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _attachedPaths.length,
                  itemBuilder: (context, index) {
                    final path = _attachedPaths[index];
                    return Stack(
                      children: [
                        Container(
                          margin: EdgeInsets.only(right: 8.w),
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.attachment, size: 16.r),
                              SizedBox(width: 4.w),
                              Text(
                                path.split(RegExp(r'[\\/]')).last,
                                style: TextStyle(fontSize: 11.sp),
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
                              child: Icon(Icons.close, size: 14.r, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],

            SizedBox(height: 6.h),
            // Text Input & Action Buttons
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.add_circle_outline_rounded, size: 24.r),
                  color: AppColors.primaryLight,
                  onPressed: _showAttachmentMenu,
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF262626) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
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
                        contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: BoxDecoration(
                    color: _isPrivateNote ? AppColors.privateNoteBorder : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: widget.isSending
                        ? SizedBox(
                            width: 18.r,
                            height: 18.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(Icons.send_rounded, size: 20.r, color: Colors.white),
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
