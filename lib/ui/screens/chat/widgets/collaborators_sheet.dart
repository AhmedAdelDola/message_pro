import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../data/models/contact.dart';
import '../../../../data/models/user.dart';
import '../../../../data/repositories/conversation_repository.dart';
import '../../../../core/di/injection_container.dart';
import '../../../widgets/avatar_widget.dart';

class CollaboratorsSheet extends StatefulWidget {
  final int conversationId;
  final List<User> workspaceAgents;
  final User? assignee;
  final VoidCallback? onCollaboratorsChanged;

  const CollaboratorsSheet({
    super.key,
    required this.conversationId,
    required this.workspaceAgents,
    this.assignee,
    this.onCollaboratorsChanged,
  });

  @override
  State<CollaboratorsSheet> createState() => _CollaboratorsSheetState();
}

class _CollaboratorsSheetState extends State<CollaboratorsSheet> {
  final IConversationRepository _repo = sl<IConversationRepository>();
  bool _isLoading = true;
  bool _isAdding = false;
  bool _showAddPicker = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<Collaborator> _collaborators = [];
  bool _canManageCollaborators = true;

  @override
  void initState() {
    super.initState();
    _loadCollaborators();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCollaborators() async {
    setState(() => _isLoading = true);
    final res = await _repo.getCollaborators(widget.conversationId);
    if (!mounted) return;
    res.fold(
      (failure) {
        setState(() => _isLoading = false);
      },
      (contact) {
        setState(() {
          _collaborators = List.from(contact.collaborators);
          _canManageCollaborators = contact.canManageCollaborators;
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _addCollaborator(int userId) async {
    if (_collaborators.length >= 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الحد الأقصى للمتعاونين هو 9'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isAdding = true);
    final res = await _repo.addCollaborator(widget.conversationId, userId);
    if (!mounted) return;
    setState(() => _isAdding = false);

    res.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message.isNotEmpty ? failure.message : 'تعذر إضافة المتعاون'),
            backgroundColor: Colors.redAccent,
          ),
        );
      },
      (contact) {
        setState(() {
          _collaborators = List.from(contact.collaborators);
          _canManageCollaborators = contact.canManageCollaborators;
          _showAddPicker = false;
        });
        widget.onCollaboratorsChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت إضافة المتعاون بنجاح'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
      },
    );
  }

  Future<void> _removeCollaborator(int userId) async {
    final res = await _repo.removeCollaborator(widget.conversationId, userId);
    if (!mounted) return;
    res.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message.isNotEmpty ? failure.message : 'تعذر إزالة المتعاون'),
            backgroundColor: Colors.redAccent,
          ),
        );
      },
      (contact) {
        setState(() {
          _collaborators = List.from(contact.collaborators);
          _canManageCollaborators = contact.canManageCollaborators;
        });
        widget.onCollaboratorsChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت إزالة المتعاون'),
            duration: Duration(seconds: 2),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final bgColor = isDark ? const Color(0xFF161616) : Colors.white;
    final surfaceColor = isDark ? const Color(0xFF1E1F23) : const Color(0xFFF4F4F6);
    final borderColor = isDark ? const Color(0xFF2B2E35) : const Color(0xFFE5E7EB);
    final textPrimary = isDark ? const Color(0xFFEDEEF0) : const Color(0xFF282E34);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF626F7F);

    // Filter agents for adding (exclude current assignee and existing collaborators)
    final existingIds = _collaborators.map((c) => c.id).toSet();
    if (widget.assignee != null) existingIds.add(widget.assignee!.id);

    final availableAgents = widget.workspaceAgents.where((agent) {
      if (existingIds.contains(agent.id)) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return agent.name.toLowerCase().contains(q) || agent.email.toLowerCase().contains(q);
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: EdgeInsets.only(top: 10.h, bottom: 8.h),
                width: 36.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                children: [
                  if (_showAddPicker)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: textPrimary,
                      onPressed: () => setState(() => _showAddPicker = false),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _showAddPicker
                              ? (isArabic ? 'إضافة متعاون' : 'Add Collaborator')
                              : (isArabic ? 'المتعاونين' : 'Collaborators'),
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                            fontFamily: 'Gontserrat',
                          ),
                        ),
                        Text(
                          _showAddPicker
                              ? (isArabic ? 'اختر عضواً من الفريق للمشاركة في المحادثة' : 'Select a team member to collaborate')
                              : '${_collaborators.length} / 9 ${isArabic ? 'متعاونين' : 'collaborators'}',
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            color: textSecondary,
                            fontFamily: 'Gontserrat',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_showAddPicker && _canManageCollaborators && _collaborators.length < 9)
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _showAddPicker = true),
                      icon: const Icon(Icons.person_add_rounded, size: 16),
                      label: Text(isArabic ? 'إضافة' : 'Add'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4162E3),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                        textStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, fontFamily: 'Gontserrat'),
                      ),
                    ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20.r, color: textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Content
            Flexible(
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: LinearProgressIndicator(
                          color: Color(0xFF4162E3),
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                    )
                  : _showAddPicker
                      ? _buildAgentPicker(availableAgents, isDark, isArabic, textPrimary, textSecondary, surfaceColor, borderColor)
                      : _buildCollaboratorsList(isDark, isArabic, textPrimary, textSecondary, borderColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollaboratorsList(
    bool isDark,
    bool isArabic,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
  ) {
    if (_collaborators.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 48.r,
              color: textSecondary.withValues(alpha: 0.5),
            ),
            SizedBox(height: 12.h),
            Text(
              isArabic ? 'لا يوجد متعاونين في هذه المحادثة بعد' : 'No collaborators yet',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: textPrimary,
                fontFamily: 'Gontserrat',
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              isArabic
                  ? 'يمكنك إضافة أعضاء من الفريق للمتابعة والمشاركة في هذه المحادثة.'
                  : 'Add teammates to keep them looped in this conversation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: textSecondary,
                fontFamily: 'Gontserrat',
              ),
            ),
            if (_canManageCollaborators) ...[
              SizedBox(height: 16.h),
              OutlinedButton.icon(
                onPressed: () => setState(() => _showAddPicker = true),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(isArabic ? 'إضافة متعاون الآن' : 'Add collaborator now'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4162E3),
                  side: const BorderSide(color: Color(0xFF4162E3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      shrinkWrap: true,
      itemCount: _collaborators.length,
      separatorBuilder: (_, __) => Divider(height: 1, indent: 64.w, endIndent: 16.w, color: borderColor),
      itemBuilder: (ctx, index) {
        final collab = _collaborators[index];
        final avatar = collab.avatarUrl ?? collab.thumbnail;
        return ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          leading: AvatarWidget(
            avatarUrl: avatar,
            name: collab.name,
            size: 40,
          ),
          title: Text(
            collab.name,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              fontFamily: 'Gontserrat',
            ),
          ),
          subtitle: Text(
            collab.type == 'user' ? (isArabic ? 'عضو فريق' : 'Team Member') : collab.type,
            style: TextStyle(
              fontSize: 11.5.sp,
              color: textSecondary,
              fontFamily: 'Gontserrat',
            ),
          ),
          trailing: _canManageCollaborators
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: Colors.redAccent,
                  tooltip: isArabic ? 'إزالة' : 'Remove',
                  onPressed: () => _removeCollaborator(collab.id),
                )
              : null,
        );
      },
    );
  }

  Widget _buildAgentPicker(
    List<User> availableAgents,
    bool isDark,
    bool isArabic,
    Color textPrimary,
    Color textSecondary,
    Color surfaceColor,
    Color borderColor,
  ) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            style: TextStyle(fontSize: 13.5.sp, color: textPrimary, fontFamily: 'Gontserrat'),
            decoration: InputDecoration(
              hintText: isArabic ? 'بحث بالاسم أو البريد...' : 'Search agent...',
              hintStyle: TextStyle(fontSize: 12.5.sp, color: textSecondary, fontFamily: 'Gontserrat'),
              prefixIcon: Icon(Icons.search_rounded, size: 20.r, color: textSecondary),
              filled: true,
              fillColor: surfaceColor,
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(color: Color(0xFF4162E3)),
              ),
            ),
          ),
        ),

        // Agents list
        Expanded(
          child: _isAdding
              ? const Center(
                  child: LinearProgressIndicator(
                    color: Color(0xFF4162E3),
                    backgroundColor: Colors.transparent,
                  ),
                )
              : availableAgents.isEmpty
                  ? Center(
                      child: Text(
                        isArabic ? 'لا يوجد أعضاء متاحين للإضافة' : 'No available agents to add',
                        style: TextStyle(fontSize: 13.sp, color: textSecondary, fontFamily: 'Gontserrat'),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      itemCount: availableAgents.length,
                      separatorBuilder: (_, __) => Divider(height: 1, indent: 64.w, endIndent: 16.w, color: borderColor),
                      itemBuilder: (ctx, index) {
                        final agent = availableAgents[index];
                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
                          leading: AvatarWidget(
                            avatarUrl: agent.avatarUrl,
                            name: agent.name,
                            size: 38,
                          ),
                          title: Text(
                            agent.name,
                            style: TextStyle(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                              fontFamily: 'Gontserrat',
                            ),
                          ),
                          subtitle: Text(
                            agent.email,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: textSecondary,
                              fontFamily: 'Gontserrat',
                            ),
                          ),
                          trailing: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF4162E3), size: 22),
                          onTap: () => _addCollaborator(agent.id),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
