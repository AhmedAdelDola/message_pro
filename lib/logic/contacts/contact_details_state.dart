import 'package:equatable/equatable.dart';
import '../../data/models/contact.dart';
import '../../data/models/contact_details_aggregate.dart';
import '../../data/models/conversation.dart';

enum ContactDetailsStatus { initial, loading, success, failure }

class ContactDetailsState extends Equatable {
  final ContactDetailsStatus status;
  final Contact contact;
  final List<String> labels;
  final bool isLoadingLabels;
  final List<LifecycleStage> lifecycleStages;
  final String activeLifecycleStage;
  final bool isUpdatingStage;
  final List<Map<String, dynamic>> inboxes;
  final bool isLoadingInboxes;
  final bool isStartingConversation;
  final Conversation? createdConversation;
  final String? feedbackMessage;
  final String? errorMessage;

  // Aggregate sections
  final bool isLoadingAggregate;
  final Set<String> loadingSections;
  final Map<String, dynamic>? assignee;
  final List<Map<String, dynamic>> collaborators;
  final List<Map<String, dynamic>> teams;
  final List<String> channels;
  final List<ContactAiActivityItem> aiActivity;
  final List<ContactAttachmentItem> attachments;
  final List<ContactActivityItem> activities;
  final List<ContactNoteItem> notes;
  final List<ContactCalendarEvent> calendarEvents;
  final String calendarBucket; // 'upcoming' | 'past'
  final ContactEcommerceData ecommerce;
  final String? selectedStoreId; // null = all stores
  final Map<String, SectionPaginationInfo> pagination;
  final bool isSavingNote;

  const ContactDetailsState({
    this.status = ContactDetailsStatus.initial,
    required this.contact,
    this.labels = const [],
    this.isLoadingLabels = false,
    this.lifecycleStages = const [],
    this.activeLifecycleStage = '',
    this.isUpdatingStage = false,
    this.inboxes = const [],
    this.isLoadingInboxes = false,
    this.isStartingConversation = false,
    this.createdConversation,
    this.feedbackMessage,
    this.errorMessage,
    this.isLoadingAggregate = false,
    this.loadingSections = const {},
    this.assignee,
    this.collaborators = const [],
    this.teams = const [],
    this.channels = const [],
    this.aiActivity = const [],
    this.attachments = const [],
    this.activities = const [],
    this.notes = const [],
    this.calendarEvents = const [],
    this.calendarBucket = 'upcoming',
    this.ecommerce = const ContactEcommerceData(),
    this.selectedStoreId,
    this.pagination = const {},
    this.isSavingNote = false,
  });

  ContactDetailsState copyWith({
    ContactDetailsStatus? status,
    Contact? contact,
    List<String>? labels,
    bool? isLoadingLabels,
    List<LifecycleStage>? lifecycleStages,
    String? activeLifecycleStage,
    bool? isUpdatingStage,
    List<Map<String, dynamic>>? inboxes,
    bool? isLoadingInboxes,
    bool? isStartingConversation,
    Conversation? createdConversation,
    String? feedbackMessage,
    String? errorMessage,
    bool? isLoadingAggregate,
    Set<String>? loadingSections,
    Map<String, dynamic>? assignee,
    List<Map<String, dynamic>>? collaborators,
    List<Map<String, dynamic>>? teams,
    List<String>? channels,
    List<ContactAiActivityItem>? aiActivity,
    List<ContactAttachmentItem>? attachments,
    List<ContactActivityItem>? activities,
    List<ContactNoteItem>? notes,
    List<ContactCalendarEvent>? calendarEvents,
    String? calendarBucket,
    ContactEcommerceData? ecommerce,
    String? selectedStoreId,
    bool clearSelectedStore = false,
    Map<String, SectionPaginationInfo>? pagination,
    bool? isSavingNote,
  }) {
    return ContactDetailsState(
      status: status ?? this.status,
      contact: contact ?? this.contact,
      labels: labels ?? this.labels,
      isLoadingLabels: isLoadingLabels ?? this.isLoadingLabels,
      lifecycleStages: lifecycleStages ?? this.lifecycleStages,
      activeLifecycleStage: activeLifecycleStage ?? this.activeLifecycleStage,
      isUpdatingStage: isUpdatingStage ?? this.isUpdatingStage,
      inboxes: inboxes ?? this.inboxes,
      isLoadingInboxes: isLoadingInboxes ?? this.isLoadingInboxes,
      isStartingConversation: isStartingConversation ?? this.isStartingConversation,
      createdConversation: createdConversation,
      feedbackMessage: feedbackMessage,
      errorMessage: errorMessage,
      isLoadingAggregate: isLoadingAggregate ?? this.isLoadingAggregate,
      loadingSections: loadingSections ?? this.loadingSections,
      assignee: assignee ?? this.assignee,
      collaborators: collaborators ?? this.collaborators,
      teams: teams ?? this.teams,
      channels: channels ?? this.channels,
      aiActivity: aiActivity ?? this.aiActivity,
      attachments: attachments ?? this.attachments,
      activities: activities ?? this.activities,
      notes: notes ?? this.notes,
      calendarEvents: calendarEvents ?? this.calendarEvents,
      calendarBucket: calendarBucket ?? this.calendarBucket,
      ecommerce: ecommerce ?? this.ecommerce,
      selectedStoreId: clearSelectedStore ? null : (selectedStoreId ?? this.selectedStoreId),
      pagination: pagination ?? this.pagination,
      isSavingNote: isSavingNote ?? this.isSavingNote,
    );
  }

  @override
  List<Object?> get props => [
        status,
        contact,
        labels,
        isLoadingLabels,
        lifecycleStages,
        activeLifecycleStage,
        isUpdatingStage,
        inboxes,
        isLoadingInboxes,
        isStartingConversation,
        createdConversation,
        feedbackMessage,
        errorMessage,
        isLoadingAggregate,
        loadingSections,
        assignee,
        collaborators,
        teams,
        channels,
        aiActivity,
        attachments,
        activities,
        notes,
        calendarEvents,
        calendarBucket,
        ecommerce,
        selectedStoreId,
        pagination,
        isSavingNote,
      ];
}
