// ignore_for_file: prefer_initializing_formals
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:message_pro/data/repositories/conversation_repository.dart';
import '../../data/models/contact.dart';
import '../../data/models/contact_details_aggregate.dart';
import '../../data/repositories/contact_repository.dart';
import 'contact_details_state.dart';

class ContactDetailsCubit extends Cubit<ContactDetailsState> {
  final IContactRepository _contactRepo;
  final IConversationRepository _conversationRepo;
  int? _conversationId;

  ContactDetailsCubit({
    required IContactRepository contactRepo,
    required IConversationRepository conversationRepo,
    required Contact initialContact,
    List<LifecycleStage>? cachedStages,
  }) : _contactRepo = contactRepo,
       _conversationRepo = conversationRepo,
       super(
         ContactDetailsState(
           contact: initialContact,
           activeLifecycleStage: _resolveInitialStage(initialContact),
           lifecycleStages: cachedStages ?? const [],
         ),
       );

  @override
  void emit(ContactDetailsState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  static String _resolveInitialStage(Contact c) {
    final raw =
        c.customAttributes['lifecycle_stage']?.toString() ??
        (c.lifecycleStage?.name ?? '');
    if (raw.isNotEmpty) {
      final emoji =
          c.lifecycleStage?.icon ?? LifecycleStage.getEmojiForStage(raw);
      return raw.startsWith(emoji) ? raw : '$emoji $raw';
    }
    return '';
  }

  Future<void> loadDetails({int? conversationId}) async {
    if (conversationId != null && conversationId > 0) {
      _conversationId = conversationId;
    }

    emit(state.copyWith(isLoadingAggregate: true, isLoadingLabels: true));

    // 1. Lifecycle stages
    if (state.lifecycleStages.isEmpty) {
      final stagesRes = await _conversationRepo.fetchLifecycleStages();
      stagesRes.fold((_) {}, (stages) {
        emit(state.copyWith(lifecycleStages: stages));
      });
    }

    // 2. Aggregate Contact Details endpoint
    final aggRes = await _contactRepo.getContactDetailsAggregate(
      state.contact.id,
      conversationId: _conversationId,
      calendarBucket: state.calendarBucket,
    );

    aggRes.fold(
      (failure) async {
        // Fallback to labels endpoint if aggregate fails
        final labelsRes = await _contactRepo.getContactLabels(state.contact.id);
        labelsRes.fold(
          (_) => emit(
            state.copyWith(
              isLoadingAggregate: false,
              isLoadingLabels: false,
              errorMessage: failure.message,
            ),
          ),
          (labels) => emit(
            state.copyWith(
              labels: labels,
              isLoadingAggregate: false,
              isLoadingLabels: false,
            ),
          ),
        );
      },
      (agg) {
        _applyAggregateResponse(agg, replaceSections: true);
      },
    );
  }

  void _applyAggregateResponse(
    ContactDetailsAggregate agg, {
    bool replaceSections = false,
    String? appendSection,
  }) {
    final nextContact = agg.contact ?? state.contact;
    final nextStage = agg.lifecycleStage != null
        ? _resolveInitialStage(
            nextContact.copyWith(lifecycleStage: agg.lifecycleStage),
          )
        : (agg.contact != null
            ? _resolveInitialStage(agg.contact!)
            : state.activeLifecycleStage);

    final nextLabels = agg.labels.isNotEmpty || replaceSections
        ? (agg.labels.isNotEmpty ? agg.labels : state.labels)
        : state.labels;

    final mergedPagination = Map<String, SectionPaginationInfo>.from(state.pagination)
      ..addAll(agg.pagination);

    List<ContactAiActivityItem>? nextAi;
    if (agg.aiActivity != null) {
      nextAi = appendSection == 'ai_activity'
          ? [...state.aiActivity, ...agg.aiActivity!]
          : agg.aiActivity;
    }

    List<ContactAttachmentItem>? nextAttachments;
    if (agg.attachments != null) {
      nextAttachments = appendSection == 'attachments'
          ? [...state.attachments, ...agg.attachments!]
          : agg.attachments;
    }

    List<ContactActivityItem>? nextActivities;
    if (agg.activities != null) {
      nextActivities = appendSection == 'activities'
          ? [...state.activities, ...agg.activities!]
          : agg.activities;
    }

    List<ContactNoteItem>? nextNotes;
    if (agg.notes != null) {
      nextNotes = appendSection == 'notes'
          ? [...state.notes, ...agg.notes!]
          : agg.notes;
    }

    List<ContactCalendarEvent>? nextCalendar;
    if (agg.calendar != null) {
      nextCalendar = appendSection == 'calendar'
          ? [...state.calendarEvents, ...agg.calendar!]
          : agg.calendar;
    }

    emit(
      state.copyWith(
        contact: nextContact,
        labels: nextLabels,
        activeLifecycleStage: nextStage.isNotEmpty ? nextStage : state.activeLifecycleStage,
        assignee: agg.assignee ?? state.assignee,
        collaborators: agg.collaborators.isNotEmpty ? agg.collaborators : state.collaborators,
        teams: agg.teams.isNotEmpty ? agg.teams : state.teams,
        channels: agg.channels.isNotEmpty ? agg.channels : state.channels,
        aiActivity: nextAi,
        attachments: nextAttachments,
        activities: nextActivities,
        notes: nextNotes,
        calendarEvents: nextCalendar,
        ecommerce: agg.ecommerce,
        pagination: mergedPagination,
        isLoadingAggregate: false,
        isLoadingLabels: false,
      ),
    );
  }

  Future<void> refreshSection(String section) async {
    final loading = Set<String>.from(state.loadingSections)..add(section);
    emit(state.copyWith(loadingSections: loading, errorMessage: null));

    final res = await _contactRepo.getContactDetailsAggregate(
      state.contact.id,
      conversationId: _conversationId,
      sections: [section],
      calendarBucket: section == 'calendar' ? state.calendarBucket : null,
    );

    final doneLoading = Set<String>.from(state.loadingSections)..remove(section);
    res.fold(
      (failure) => emit(
        state.copyWith(loadingSections: doneLoading, errorMessage: failure.message),
      ),
      (agg) {
        emit(state.copyWith(loadingSections: doneLoading));
        _applyAggregateResponse(agg);
      },
    );
  }

  Future<void> loadMoreSection(String section) async {
    final pag = state.pagination[section];
    if (pag == null || !pag.hasMore || pag.nextPage == null) return;
    if (state.loadingSections.contains(section)) return;

    final loading = Set<String>.from(state.loadingSections)..add(section);
    emit(state.copyWith(loadingSections: loading));

    final nextPage = pag.nextPage!;
    final res = await _contactRepo.getContactDetailsAggregate(
      state.contact.id,
      conversationId: _conversationId,
      sections: [section],
      notesPage: section == 'notes' ? nextPage : null,
      attachmentsPage: section == 'attachments' ? nextPage : null,
      activitiesPage: section == 'activities' ? nextPage : null,
      aiActivityPage: section == 'ai_activity' ? nextPage : null,
      calendarPage: section == 'calendar' ? nextPage : null,
      calendarBucket: section == 'calendar' ? state.calendarBucket : null,
    );

    final doneLoading = Set<String>.from(state.loadingSections)..remove(section);
    res.fold(
      (failure) => emit(
        state.copyWith(loadingSections: doneLoading, errorMessage: failure.message),
      ),
      (agg) {
        emit(state.copyWith(loadingSections: doneLoading));
        _applyAggregateResponse(agg, appendSection: section);
      },
    );
  }

  Future<void> switchCalendarBucket(String bucket) async {
    if (state.calendarBucket == bucket) return;
    final loading = Set<String>.from(state.loadingSections)..add('calendar');
    emit(state.copyWith(calendarBucket: bucket, loadingSections: loading));

    final res = await _contactRepo.getContactDetailsAggregate(
      state.contact.id,
      conversationId: _conversationId,
      sections: const ['calendar'],
      calendarBucket: bucket,
      calendarPage: 1,
    );

    final doneLoading = Set<String>.from(state.loadingSections)..remove('calendar');
    res.fold(
      (failure) => emit(
        state.copyWith(loadingSections: doneLoading, errorMessage: failure.message),
      ),
      (agg) {
        emit(state.copyWith(loadingSections: doneLoading));
        _applyAggregateResponse(agg);
      },
    );
  }

  Future<void> loadMoreEcommerceOrders(EcommerceStoreData store) async {
    if (!store.hasNextPage) return;
    if (state.loadingSections.contains('ecommerce')) return;

    final loading = Set<String>.from(state.loadingSections)..add('ecommerce');
    emit(state.copyWith(loadingSections: loading));

    final res = await _contactRepo.getContactDetailsAggregate(
      state.contact.id,
      conversationId: _conversationId,
      sections: const ['ecommerce'],
      ecommerceCursors: store.endCursor != null && store.endCursor!.isNotEmpty
          ? {store.connectionId: store.endCursor!}
          : null,
      ecommercePages: store.nextPage != null
          ? {store.connectionId: store.nextPage!}
          : null,
    );

    final doneLoading = Set<String>.from(state.loadingSections)..remove('ecommerce');
    res.fold(
      (failure) => emit(
        state.copyWith(loadingSections: doneLoading, errorMessage: failure.message),
      ),
      (agg) {
        if (agg.ecommerce == null) {
          emit(state.copyWith(loadingSections: doneLoading));
          return;
        }
        final updatedStores = state.ecommerce.stores.map((existing) {
          if (existing.connectionId != store.connectionId) return existing;
          final incoming = agg.ecommerce!.stores
              .where((s) => s.connectionId == store.connectionId)
              .firstOrNull;
          if (incoming == null) return existing;
          return EcommerceStoreData(
            connectionId: existing.connectionId,
            storeName: existing.storeName,
            storeDomain: existing.storeDomain,
            isMatched: incoming.isMatched,
            matchedCustomer: incoming.matchedCustomer ?? existing.matchedCustomer,
            orders: [...existing.orders, ...incoming.orders],
            hasNextPage: incoming.hasNextPage,
            endCursor: incoming.endCursor,
            nextPage: incoming.nextPage,
            error: incoming.error,
          );
        }).toList();

        emit(
          state.copyWith(
            loadingSections: doneLoading,
            ecommerce: ContactEcommerceData(
              enabled: agg.ecommerce!.enabled,
              stores: updatedStores,
            ),
          ),
        );
      },
    );
  }

  void setSelectedStore(String? storeId) {
    if (storeId == null) {
      emit(state.copyWith(clearSelectedStore: true));
    } else {
      emit(state.copyWith(selectedStoreId: storeId));
    }
  }

  Future<bool> addPrivateNote(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty || _conversationId == null || _conversationId! <= 0) {
      return false;
    }
    emit(state.copyWith(isSavingNote: true, errorMessage: null));
    final res = await _conversationRepo.sendMessage(
      conversationId: _conversationId!,
      content: trimmed,
      isPrivate: true,
    );
    return await res.fold(
      (failure) {
        emit(state.copyWith(isSavingNote: false, errorMessage: failure.message));
        return false;
      },
      (_) async {
        emit(state.copyWith(isSavingNote: false));
        await refreshSection('notes');
        return true;
      },
    );
  }

  Future<List<Map<String, dynamic>>> resolveAvailableInboxes({
    List<Inbox> workspaceInboxes = const [],
  }) async {
    emit(state.copyWith(isLoadingInboxes: true));
    final List<Map<String, dynamic>> inboxes = [];
    final phone = state.contact.phoneNumber?.trim();

    if (phone != null && phone.isNotEmpty) {
      final phoneDestRes = await _conversationRepo.getPhoneDestinations(
        phoneNumber: phone,
      );
      phoneDestRes.fold((_) {}, (destList) {
        for (final d in destList) {
          final rawInbox = d['inbox'];
          int? parsedId;
          String? pName;
          String? chType;
          if (rawInbox is Map) {
            parsedId = rawInbox['id'] is int
                ? rawInbox['id']
                : int.tryParse(rawInbox['id']?.toString() ?? '');
            pName = rawInbox['name']?.toString();
            chType = rawInbox['channel_type']?.toString();
          } else {
            parsedId = d['inbox_id'] is int
                ? d['inbox_id']
                : int.tryParse(d['inbox_id']?.toString() ?? '');
            pName = d['inbox_name']?.toString();
            chType = d['channel_type']?.toString();
          }
          final srcId = d['source_id']?.toString() ?? phone;

          if (parsedId != null &&
              parsedId > 0 &&
              !inboxes.any((existing) => existing['id'] == parsedId)) {
            final matching = workspaceInboxes
                .where((wi) => wi.id == parsedId)
                .firstOrNull;
            pName ??= matching?.name;
            chType ??= matching?.channelType ?? 'Channel::Whatsapp';
            inboxes.add({
              'id': parsedId,
              'name': (pName != null && pName.isNotEmpty) ? pName : 'WhatsApp',
              'channel_type': chType,
              'source_id': srcId,
            });
          }
        }
      });
    }

    if (inboxes.isEmpty) {
      final inboxesResult = await _conversationRepo.getContactableInboxes(
        state.contact.id,
      );
      inboxesResult.fold((_) {}, (list) {
        for (final item in list) {
          final inbMap = item['inbox'] is Map
              ? Map<String, dynamic>.from(item['inbox'] as Map)
              : null;
          final rawInboxId = inbMap?['id'] ?? item['inbox_id'];
          final inboxId = rawInboxId is int
              ? rawInboxId
              : int.tryParse(rawInboxId?.toString() ?? '');

          if (inboxId == null || inboxId <= 0) continue;

          final matching = workspaceInboxes
              .where((wi) => wi.id == inboxId)
              .firstOrNull;
          final name =
              inbMap?['name']?.toString() ?? matching?.name ?? 'قناة مراسلة';
          final channelType =
              inbMap?['channel_type']?.toString() ??
              matching?.channelType ??
              '';
          final sourceId =
              item['source_id']?.toString() ??
              state.contact.phoneNumber ??
              state.contact.email ??
              'contact_${state.contact.id}';

          if (!inboxes.any((existing) => existing['id'] == inboxId)) {
            inboxes.add({
              'id': inboxId,
              'name': name,
              'channel_type': channelType,
              'source_id': sourceId,
            });
          }
        }
      });
    }

    if (inboxes.isEmpty) {
      if (workspaceInboxes.isNotEmpty) {
        for (final inb in workspaceInboxes) {
          if (!inboxes.any((existing) => existing['id'] == inb.id)) {
            inboxes.add({
              'id': inb.id,
              'name': inb.name,
              'channel_type': inb.channelType,
              'source_id':
                  state.contact.phoneNumber ??
                  state.contact.email ??
                  state.contact.name,
            });
          }
        }
      } else {
        final allInboxes = await _conversationRepo.fetchInboxes();
        allInboxes.fold((_) {}, (list) {
          for (final inb in list) {
            if (!inboxes.any((existing) => existing['id'] == inb.id)) {
              inboxes.add({
                'id': inb.id,
                'name': inb.name,
                'channel_type': inb.channelType,
                'source_id':
                    state.contact.phoneNumber ??
                    state.contact.email ??
                    state.contact.name,
              });
            }
          }
        });
      }
    }

    emit(state.copyWith(inboxes: inboxes, isLoadingInboxes: false));
    return inboxes;
  }

  Future<void> startConversation({
    required int inboxId,
    required String sourceId,
  }) async {
    emit(
      state.copyWith(
        isStartingConversation: true,
        errorMessage: null,
        createdConversation: null,
      ),
    );

    final res = await _conversationRepo.startNewConversation(
      contactId: state.contact.id,
      inboxId: inboxId,
      sourceId: sourceId,
    );

    res.fold(
      (failure) => emit(
        state.copyWith(
          isStartingConversation: false,
          errorMessage: failure.message,
        ),
      ),
      (conversation) => emit(
        state.copyWith(
          isStartingConversation: false,
          createdConversation: conversation,
        ),
      ),
    );
  }

  Future<void> updateLifecycleStage(
    String stage, {
    int? stageId,
    int? conversationId,
    bool isArabic = false,
  }) async {
    final oldStage = state.activeLifecycleStage;
    emit(
      state.copyWith(
        activeLifecycleStage: stage,
        isUpdatingStage: true,
        errorMessage: null,
        feedbackMessage: null,
      ),
    );

    int? resolvedId = stageId;
    if (resolvedId == null && state.lifecycleStages.isNotEmpty) {
      for (final s in state.lifecycleStages) {
        if (stage.contains(s.name) || s.name.contains(stage)) {
          resolvedId = s.id;
          break;
        }
      }
    }

    final res = await _contactRepo.updateContactLifecycle(
      state.contact.id,
      stage,
      stageId: resolvedId,
    );

    res.fold(
      (failure) {
        emit(
          state.copyWith(
            activeLifecycleStage: oldStage,
            isUpdatingStage: false,
            errorMessage: failure.message,
          ),
        );
      },
      (updatedContact) {
        if (conversationId != null) {
          _conversationRepo.updateConversationCustomAttributes(conversationId, {
            'lifecycle_stage': stage,
            'lead_status': stage,
          });
        }

        final msg = isArabic
            ? 'تم تحديث مرحلة العميل إلى: $stage'
            : 'Lifecycle stage updated to: $stage';

        emit(
          state.copyWith(
            contact: updatedContact,
            isUpdatingStage: false,
            feedbackMessage: msg,
          ),
        );
      },
    );
  }

  Future<void> updateLabels(List<String> newLabels) async {
    emit(state.copyWith(isLoadingLabels: true));
    final res = await _contactRepo.updateContactLabels(
      state.contact.id,
      newLabels,
    );
    res.fold(
      (failure) => emit(
        state.copyWith(isLoadingLabels: false, errorMessage: failure.message),
      ),
      (updated) =>
          emit(state.copyWith(labels: updated, isLoadingLabels: false)),
    );
  }

  void clearCreatedConversation() {
    emit(state.copyWith(createdConversation: null));
  }
}
