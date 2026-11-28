import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../data/models/workflow.dart';
import '../../../../../data/repositories/conversation_repository.dart';

class WorkflowShortcutsSheet extends StatefulWidget {
  final int conversationId;
  final IConversationRepository repository;

  const WorkflowShortcutsSheet({
    super.key,
    required this.conversationId,
    required this.repository,
  });

  @override
  State<WorkflowShortcutsSheet> createState() => _WorkflowShortcutsSheetState();
}

class _WorkflowShortcutsSheetState extends State<WorkflowShortcutsSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<WorkflowShortcut> _available = const [];
  List<WorkflowRun> _activeRuns = const [];
  bool _isLoading = true;
  String? _error;
  int? _startingWorkflowId;
  int? _stoppingRunId;
  WorkflowShortcut? _pendingInputWorkflow;
  final Map<String, dynamic> _inputValues = {};
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final results = await Future.wait([
      widget.repository.getAvailableWorkflows(widget.conversationId),
      widget.repository.getWorkflowRuns(widget.conversationId),
    ]);

    if (!mounted) return;

    final availRes = results[0] as dynamic;
    final runsRes = results[1] as dynamic;

    String? err;
    List<WorkflowShortcut> avail = [];
    List<WorkflowRun> runs = [];

    availRes.fold(
      (f) => err = f.message,
      (list) => avail = List<WorkflowShortcut>.from(list),
    );
    runsRes.fold(
      (_) {},
      (list) => runs = List<WorkflowRun>.from(list),
    );

    setState(() {
      _available = avail;
      _activeRuns = runs;
      _error = err;
      _isLoading = false;
    });
  }

  Future<void> _handleSelectShortcut(WorkflowShortcut workflow) async {
    if (_startingWorkflowId != null) return;
    if (workflow.inputs.isNotEmpty) {
      setState(() {
        _pendingInputWorkflow = workflow;
        _inputValues.clear();
        for (final input in workflow.inputs) {
          if (input.type == 'select' && input.options.isNotEmpty) {
            _inputValues[input.name] = input.options.first;
          }
        }
      });
      return;
    }
    await _startWorkflow(workflow, const {});
  }

  Future<void> _startWorkflow(
    WorkflowShortcut workflow,
    Map<String, dynamic> variables,
  ) async {
    setState(() => _startingWorkflowId = workflow.id);
    final res = await widget.repository.startWorkflow(
      widget.conversationId,
      workflow.id,
      variables: variables,
    );
    if (!mounted) return;

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    res.fold(
      (failure) {
        setState(() => _startingWorkflowId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Colors.red.shade600,
          ),
        );
      },
      (_) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? 'تم تشغيل "${workflow.name}" بنجاح'
                  : 'Started "${workflow.name}"',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      },
    );
  }

  Future<void> _stopRun(WorkflowRun run) async {
    if (_stoppingRunId != null) return;
    setState(() => _stoppingRunId = run.id);
    final res = await widget.repository.stopWorkflowRun(
      widget.conversationId,
      run.id,
    );
    if (!mounted) return;

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    res.fold(
      (failure) {
        setState(() => _stoppingRunId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Colors.red.shade600,
          ),
        );
      },
      (_) async {
        setState(() => _stoppingRunId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic ? 'تم إيقاف "${run.name}"' : 'Stopped "${run.name}"',
            ),
          ),
        );
        await _loadData();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final bgColor = isDark ? const Color(0xFF18181B) : Colors.white;
    final cardColor = isDark ? const Color(0xFF27272A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF3F3F46) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final query = _searchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _available
        : _available.where((w) {
            return w.name.toLowerCase().contains(query) ||
                (w.description?.toLowerCase().contains(query) ?? false);
          }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              SizedBox(height: 10.h),
              Container(
                width: 38.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.bolt_rounded,
                        color: const Color(0xFFD97706),
                        size: 20.r,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        _pendingInputWorkflow != null
                            ? _pendingInputWorkflow!.name
                            : (isArabic ? 'اختصارات الورك فلو' : 'Workflow shortcuts'),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    if (_pendingInputWorkflow != null)
                      TextButton(
                        onPressed: () => setState(() => _pendingInputWorkflow = null),
                        child: Text(isArabic ? 'رجوع' : 'Back'),
                      )
                    else
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: textSecondary, size: 20.r),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                  ],
                ),
              ),
              Divider(height: 1, color: borderColor),
              Expanded(
                child: _pendingInputWorkflow != null
                    ? _buildInputsForm(
                        _pendingInputWorkflow!,
                        isArabic: isArabic,
                        textPrimary: textPrimary,
                        borderColor: borderColor,
                      )
                    : ListView(
                        controller: scrollController,
                        padding: EdgeInsets.all(16.r),
                        children: [
                          TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: isArabic
                                  ? 'ابحث في الاختصارات...'
                                  : 'Search shortcuts...',
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: textSecondary,
                                size: 20.r,
                              ),
                              filled: true,
                              fillColor: cardColor,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 10.h,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide(color: borderColor),
                              ),
                            ),
                          ),
                          SizedBox(height: 14.h),
                          if (_isLoading)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 32.h),
                              child: const Center(child: CircularProgressIndicator()),
                            )
                          else if (_error != null)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.h),
                              child: Column(
                                children: [
                                  Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.red.shade400, fontSize: 13.sp),
                                  ),
                                  SizedBox(height: 8.h),
                                  TextButton.icon(
                                    onPressed: _loadData,
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
                                  ),
                                ],
                              ),
                            )
                          else if (filtered.isEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 28.h),
                              child: Center(
                                child: Text(
                                  isArabic
                                      ? 'لا توجد اختصارات ورك فلو متاحة'
                                      : 'No workflow shortcuts available',
                                  style: TextStyle(color: textSecondary, fontSize: 13.sp),
                                ),
                              ),
                            )
                          else
                            ...filtered.map(
                              (w) => _buildShortcutTile(
                                w,
                                isDark: isDark,
                                isArabic: isArabic,
                                cardColor: cardColor,
                                borderColor: borderColor,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                              ),
                            ),
                          SizedBox(height: 16.h),
                          Divider(height: 1, color: borderColor),
                          SizedBox(height: 14.h),
                          Text(
                            isArabic ? 'مسارات العمل النشطة' : 'Active workflows',
                            style: TextStyle(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          if (_activeRuns.isEmpty)
                            Text(
                              isArabic
                                  ? 'لا توجد مسارات عمل نشطة لهذه المحادثة.'
                                  : 'No active workflows for this contact.',
                              style: TextStyle(fontSize: 12.5.sp, color: textSecondary),
                            )
                          else
                            ..._activeRuns.map(
                              (run) => Container(
                                margin: EdgeInsets.only(bottom: 8.h),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 10.h,
                                ),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(10.r),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.play_circle_outline_rounded,
                                      size: 18.r,
                                      color: AppColors.primary,
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Text(
                                        run.name,
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w600,
                                          color: textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (run.canStop)
                                      TextButton(
                                        onPressed: _stoppingRunId == run.id
                                            ? null
                                            : () => _stopRun(run),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          minimumSize: Size(0, 30.h),
                                          padding: EdgeInsets.symmetric(horizontal: 10.w),
                                        ),
                                        child: _stoppingRunId == run.id
                                            ? SizedBox(
                                                width: 14.r,
                                                height: 14.r,
                                                child: const CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : Text(isArabic ? 'إيقاف' : 'Stop'),
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
        );
      },
    );
  }

  Widget _buildShortcutTile(
    WorkflowShortcut workflow, {
    required bool isDark,
    required bool isArabic,
    required Color cardColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final isStarting = _startingWorkflowId == workflow.id;
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: borderColor),
      ),
      child: InkWell(
        onTap: isStarting ? null : () => _handleSelectShortcut(workflow),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Row(
            children: [
              Icon(
                Icons.bolt_rounded,
                color: const Color(0xFFD97706),
                size: 20.r,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workflow.name,
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    if (workflow.description != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        workflow.description!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              if (isStarting)
                SizedBox(
                  width: 16.r,
                  height: 16.r,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  isArabic ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                  color: textSecondary,
                  size: 20.r,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputsForm(
    WorkflowShortcut workflow, {
    required bool isArabic,
    required Color textPrimary,
    required Color borderColor,
  }) {
    final isStarting = _startingWorkflowId == workflow.id;
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          ...workflow.inputs.map((input) {
            if (input.type == 'select' && input.options.isNotEmpty) {
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: DropdownButtonFormField<String>(
                  initialValue: _inputValues[input.name]?.toString(),
                  decoration: InputDecoration(
                    labelText: input.label,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  items: input.options
                      .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                      .toList(),
                  onChanged: (val) => setState(() => _inputValues[input.name] = val),
                  validator: input.required
                      ? (v) => (v == null || v.isEmpty)
                          ? (isArabic ? 'هذا الحقل مطلوب' : 'Required')
                          : null
                      : null,
                ),
              );
            }
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: input.label,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                onChanged: (val) => _inputValues[input.name] = val,
                validator: input.required
                    ? (v) => (v == null || v.trim().isEmpty)
                        ? (isArabic ? 'هذا الحقل مطلوب' : 'Required')
                        : null
                    : null,
              ),
            );
          }),
          SizedBox(height: 8.h),
          ElevatedButton.icon(
            onPressed: isStarting
                ? null
                : () {
                    if (_formKey.currentState?.validate() ?? false) {
                      _startWorkflow(workflow, Map<String, dynamic>.from(_inputValues));
                    }
                  },
            icon: isStarting
                ? SizedBox(
                    width: 16.r,
                    height: 16.r,
                    child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.bolt_rounded),
            label: Text(isArabic ? 'تشغيل الورك فلو' : 'Start workflow'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
