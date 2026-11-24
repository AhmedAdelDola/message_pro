import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/error/failures.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../data/models/contact.dart';
import '../../data/repositories/contact_repository.dart';
import 'contacts_state.dart';

class ContactsCubit extends Cubit<ContactsState> {
  final IContactRepository repository;
  final SecureStorageService _storage = SecureStorageService();

  ContactsCubit({required this.repository})
      : super(const ContactsState()) {
    _loadCachedContacts();
  }

  void _loadCachedContacts() async {
    try {
      final accId = await _storage.getActiveAccountId();
      if (accId != null && accId > 0 && state.contacts.isEmpty) {
        final cached = repository.getCachedContacts(accId);
        if (cached.isNotEmpty && !isClosed) {
          emit(state.copyWith(
            status: ContactsStatus.success,
            contacts: cached,
            hasMore: true,
          ));
        }
      }
    } catch (_) {}
  }

  @override
  void emit(ContactsState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  Future<void> fetchContacts({bool refresh = false}) async {
    if (refresh) {
      emit(state.copyWith(
        status: ContactsStatus.loading,
        page: 1,
        hasMore: true,
        errorMessage: null,
      ));
    } else if (state.status == ContactsStatus.initial) {
      emit(state.copyWith(status: ContactsStatus.loading));
    }

    final query = state.searchQuery.trim();
    final res = query.isNotEmpty
        ? await repository.searchContacts(query, page: 1)
        : await repository.getContacts(page: 1);

    res.fold(
      (failure) => emit(state.copyWith(
        status: ContactsStatus.failure,
        errorMessage: failure.message,
      )),
      (list) => emit(state.copyWith(
        status: ContactsStatus.success,
        contacts: list,
        page: 1,
        hasMore: list.length >= 25,
      )),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.status == ContactsStatus.loading) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true));
    final nextPage = state.page + 1;
    final query = state.searchQuery.trim();

    final res = query.isNotEmpty
        ? await repository.searchContacts(query, page: nextPage)
        : await repository.getContacts(page: nextPage);

    res.fold(
      (failure) => emit(state.copyWith(isLoadingMore: false)),
      (list) {
        final updatedList = List<Contact>.from(state.contacts)..addAll(list);
        emit(state.copyWith(
          contacts: updatedList,
          page: nextPage,
          hasMore: list.isNotEmpty && list.length >= 25,
          isLoadingMore: false,
        ));
      },
    );
  }

  Future<void> search(String query) async {
    emit(state.copyWith(
      searchQuery: query,
      page: 1,
      hasMore: true,
      status: ContactsStatus.loading,
    ));

    final trimmed = query.trim();
    final res = trimmed.isNotEmpty
        ? await repository.searchContacts(trimmed, page: 1)
        : await repository.getContacts(page: 1);

    res.fold(
      (failure) => emit(state.copyWith(
        status: ContactsStatus.failure,
        errorMessage: failure.message,
      )),
      (list) => emit(state.copyWith(
        status: ContactsStatus.success,
        contacts: list,
        hasMore: list.length >= 25,
      )),
    );
  }

  Future<Either<Failure, Contact>> createContact({
    required String name,
    String? email,
    String? phoneNumber,
    List<String>? tags,
    Map<String, dynamic>? customAttributes,
  }) async {
    final res = await repository.createContact(
      name: name,
      email: email,
      phoneNumber: phoneNumber,
      customAttributes: customAttributes,
    );

    return res.fold(
      (failure) => Left(failure),
      (contact) async {
        if (tags != null && tags.isNotEmpty) {
          await repository.updateContactLabels(contact.id, tags);
        }
        addContactLocally(contact);
        return Right(contact);
      },
    );
  }

  Future<Either<Failure, Contact>> updateContact(
    int id, {
    String? name,
    String? email,
    String? phoneNumber,
    Map<String, dynamic>? customAttributes,
    int? lifecycleStageId,
    bool clearLifecycleStage = false,
  }) async {
    final res = await repository.updateContact(
      id,
      name: name,
      email: email,
      phoneNumber: phoneNumber,
      customAttributes: customAttributes,
      lifecycleStageId: lifecycleStageId,
      clearLifecycleStage: clearLifecycleStage,
    );
    res.fold((_) {}, (updated) => updateContactLocally(updated));
    return res;
  }

  void addContactLocally(Contact newContact) {
    final updated = List<Contact>.from(state.contacts)..insert(0, newContact);
    emit(state.copyWith(contacts: updated));
  }

  void updateContactLocally(Contact updatedContact) {
    final updated = state.contacts.map((c) {
      return c.id == updatedContact.id ? updatedContact : c;
    }).toList();
    emit(state.copyWith(contacts: updated));
  }
}
