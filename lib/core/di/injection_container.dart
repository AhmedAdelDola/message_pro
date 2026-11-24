import 'package:get_it/get_it.dart';
import '../network/api_client.dart';
import '../network/websocket_client.dart';
import '../storage/secure_storage_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/conversation_repository.dart';
import '../../data/repositories/contact_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../logic/auth/auth_cubit.dart';
import '../../logic/conversation/conversation_cubit.dart';
import '../../logic/chat/chat_cubit.dart';
import '../../logic/notification/notification_cubit.dart';
import '../../logic/calls/calls_cubit.dart';
import '../../logic/settings/settings_cubit.dart';
import '../../logic/shorebird/shorebird_cubit.dart';
import '../../logic/contacts/contacts_cubit.dart';
import '../../logic/contacts/contact_details_cubit.dart';
import '../../data/models/contact.dart';
import '../../data/models/conversation.dart';

final sl = GetIt.instance;

Future<void> initDI() async {
  // 1. Core Services & Singletons
  sl.registerLazySingleton<SecureStorageService>(() => SecureStorageService());
  sl.registerLazySingleton<ApiClient>(() => ApiClient());
  sl.registerLazySingleton<ActionCableClient>(() => ActionCableClient());

  // 2. Repositories
  sl.registerLazySingleton<IAuthRepository>(
    () => AuthRepository(api: sl(), storage: sl()),
  );
  sl.registerLazySingleton<IConversationRepository>(
    () => ConversationRepository(api: sl()),
  );
  sl.registerLazySingleton<IContactRepository>(
    () => ContactRepository(api: sl()),
  );
  sl.registerLazySingleton<INotificationRepository>(
    () => NotificationRepository(api: sl()),
  );

  // 3. Cubits (Blocs)
  sl.registerFactory<AuthCubit>(
    () => AuthCubit(authRepo: sl(), storage: sl(), ws: sl()),
  );
  sl.registerFactory<ConversationCubit>(
    () => ConversationCubit(repo: sl(), ws: sl()),
  );
  sl.registerFactoryParam<ChatCubit, dynamic, dynamic>(
    (param1, param2) {
      if (param1 is Conversation) {
        return ChatCubit(
          conversationId: param1.id,
          accountId: param1.accountId,
          repo: sl(),
          ws: sl(),
          contactLastSeenAt: param1.contactLastSeenAt,
        );
      }
      final convId = param1 is int ? param1 : (int.tryParse(param1?.toString() ?? '') ?? 0);
      final accId = param2 is int ? param2 : (param2 is Conversation ? param2.accountId : null);
      final lastSeen = param2 is DateTime ? param2 : null;
      return ChatCubit(
        conversationId: convId,
        accountId: accId,
        repo: sl(),
        ws: sl(),
        contactLastSeenAt: lastSeen,
      );
    },
  );
  sl.registerFactory<NotificationCubit>(
    () => NotificationCubit(repo: sl()),
  );
  sl.registerFactory<CallsCubit>(
    () => CallsCubit(),
  );
  sl.registerFactory<SettingsCubit>(
    () => SettingsCubit(),
  );
  sl.registerFactory<ShorebirdCubit>(
    () => ShorebirdCubit(),
  );
  sl.registerFactory<ContactsCubit>(
    () => ContactsCubit(repository: sl()),
  );
  sl.registerFactoryParam<ContactDetailsCubit, Contact, List<LifecycleStage>?>(
    (contact, stages) => ContactDetailsCubit(
      contactRepo: sl(),
      conversationRepo: sl(),
      initialContact: contact,
      cachedStages: stages,
    ),
  );
}
