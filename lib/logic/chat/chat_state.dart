import 'package:equatable/equatable.dart';
import '../../data/models/message.dart';

class ChatState extends Equatable {
  final int conversationId;
  final List<Message> messages;
  final bool isLoading;
  final bool isSending;
  final String? errorMessage;
  final String status;
  final Set<String> typingUsers;
  final List<Map<String, String>> cannedResponses;

  const ChatState({
    required this.conversationId,
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.errorMessage,
    this.status = 'open',
    this.typingUsers = const {},
    this.cannedResponses = const [],
  });

  ChatState copyWith({
    int? conversationId,
    List<Message>? messages,
    bool? isLoading,
    bool? isSending,
    String? errorMessage,
    String? status,
    Set<String>? typingUsers,
    List<Map<String, String>>? cannedResponses,
  }) {
    return ChatState(
      conversationId: conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage,
      status: status ?? this.status,
      typingUsers: typingUsers ?? this.typingUsers,
      cannedResponses: cannedResponses ?? this.cannedResponses,
    );
  }

  @override
  List<Object?> get props => [
        conversationId,
        messages,
        isLoading,
        isSending,
        errorMessage,
        status,
        typingUsers,
        cannedResponses,
      ];
}
