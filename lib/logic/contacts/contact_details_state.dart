import 'package:equatable/equatable.dart';
import '../../data/models/contact.dart';
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
      ];
}
