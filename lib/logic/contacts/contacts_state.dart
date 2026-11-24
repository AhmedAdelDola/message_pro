import 'package:equatable/equatable.dart';
import '../../data/models/contact.dart';

enum ContactsStatus { initial, loading, success, failure }

class ContactsState extends Equatable {
  final ContactsStatus status;
  final List<Contact> contacts;
  final bool hasMore;
  final int page;
  final bool isLoadingMore;
  final String searchQuery;
  final String? errorMessage;

  const ContactsState({
    this.status = ContactsStatus.initial,
    this.contacts = const [],
    this.hasMore = true,
    this.page = 1,
    this.isLoadingMore = false,
    this.searchQuery = '',
    this.errorMessage,
  });

  ContactsState copyWith({
    ContactsStatus? status,
    List<Contact>? contacts,
    bool? hasMore,
    int? page,
    bool? isLoadingMore,
    String? searchQuery,
    String? errorMessage,
  }) {
    return ContactsState(
      status: status ?? this.status,
      contacts: contacts ?? this.contacts,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        contacts,
        hasMore,
        page,
        isLoadingMore,
        searchQuery,
        errorMessage,
      ];
}
