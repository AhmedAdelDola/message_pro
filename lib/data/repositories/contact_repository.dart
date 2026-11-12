import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../core/error/failures.dart';
import '../../core/network/api_client.dart';
import '../models/contact.dart';
import '../models/conversation.dart';

abstract class IContactRepository {
  Future<Either<Failure, List<Contact>>> getContacts({
    int page = 1,
    int perPage = 25,
    String sort = 'name',
  });
  Future<Either<Failure, List<Contact>>> searchContacts(String query, {int page = 1});
  Future<Either<Failure, Contact>> getContact(int id);
  Future<Either<Failure, List<Conversation>>> getContactConversations(int contactId);
  Future<Either<Failure, Contact>> createContact({
    required String name,
    String? email,
    String? phoneNumber,
    Map<String, dynamic>? customAttributes,
  });
  Future<Either<Failure, Contact>> updateContact(
    int id, {
    String? name,
    String? email,
    String? phoneNumber,
    Map<String, dynamic>? customAttributes,
    int? lifecycleStageId,
    bool clearLifecycleStage = false,
  });
  Future<Either<Failure, List<String>>> getContactLabels(int contactId);
  Future<Either<Failure, List<String>>> updateContactLabels(int contactId, List<String> labels);
  Future<Either<Failure, Contact>> updateContactLifecycle(
    int contactId,
    String stage, {
    int? stageId,
    bool clearStage = false,
  });
}

class ContactRepository implements IContactRepository {
  final ApiClient _api;

  ContactRepository({ApiClient? api}) : _api = api ?? ApiClient();

  @override
  Future<Either<Failure, List<Contact>>> getContacts({
    int page = 1,
    int perPage = 25,
    String sort = 'name',
  }) async {
    try {
      final response = await _api.get(
        'contacts',
        queryParameters: {
          'page': page,
          'per_page': perPage,
          'sort': sort,
          'include_contact_inboxes': false,
        },
      );
      final data = response.data;
      List list = [];
      if (data is Map && data['payload'] != null) {
        list = data['payload'];
      } else if (data is List) {
        list = data;
      }
      return Right(list.map((c) => Contact.fromJson(c as Map<String, dynamic>)).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'فشل تحميل جهات الاتصال'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Contact>>> searchContacts(String query, {int page = 1}) async {
    try {
      final response = await _api.get(
        'contacts/search',
        queryParameters: {'q': query, 'page': page},
      );
      final data = response.data;
      List list = [];
      if (data is Map && data['payload'] != null) {
        list = data['payload'];
      } else if (data is List) {
        list = data;
      }
      return Right(list.map((c) => Contact.fromJson(c as Map<String, dynamic>)).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'فشل البحث عن جهات الاتصال'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Contact>> getContact(int id) async {
    try {
      final response = await _api.get('contacts/$id');
      final data = response.data;
      final payload = data is Map && data['payload'] != null ? data['payload'] : data;
      return Right(Contact.fromJson(payload as Map<String, dynamic>));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Conversation>>> getContactConversations(int contactId) async {
    try {
      final response = await _api.get('contacts/$contactId/conversations');
      final data = response.data;
      List list = [];
      if (data is Map && data['payload'] != null) {
        list = data['payload'];
      } else if (data is List) {
        list = data;
      }
      return Right(list.map((c) => Conversation.fromJson(c as Map<String, dynamic>)).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Contact>> createContact({
    required String name,
    String? email,
    String? phoneNumber,
    Map<String, dynamic>? customAttributes,
  }) async {
    try {
      final postData = <String, dynamic>{
        'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
        if (phoneNumber != null && phoneNumber.isNotEmpty) 'phone_number': phoneNumber,
        if (customAttributes != null && customAttributes.isNotEmpty) 'custom_attributes': customAttributes,
      };

      final response = await _api.post(
        'contacts',
        data: postData,
      );
      final data = response.data;
      final payload = data is Map && data['payload'] != null
          ? data['payload']
          : (data is Map && data['data'] != null ? data['data'] : data);
      final contactData = payload is Map && payload['contact'] != null ? payload['contact'] : payload;
      return Right(Contact.fromJson(contactData as Map<String, dynamic>));
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'فشل إنشاء جهة الاتصال'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Contact>> updateContact(
    int id, {
    String? name,
    String? email,
    String? phoneNumber,
    Map<String, dynamic>? customAttributes,
    int? lifecycleStageId,
    bool clearLifecycleStage = false,
  }) async {
    try {
      final patchData = <String, dynamic>{};
      if (name != null) patchData['name'] = name;
      if (email != null) patchData['email'] = email;
      if (phoneNumber != null) patchData['phone_number'] = phoneNumber;
      if (customAttributes != null) patchData['custom_attributes'] = customAttributes;
      if (lifecycleStageId != null) {
        patchData['lifecycle_stage_id'] = lifecycleStageId;
      } else if (clearLifecycleStage) {
        patchData['lifecycle_stage_id'] = null;
      }

      final response = await _api.patch(
        'contacts/$id',
        data: patchData,
      );
      final data = response.data;
      final payload = data is Map && data['payload'] != null
          ? data['payload']
          : (data is Map && data['data'] != null ? data['data'] : data);
      final contactData = payload is Map && payload['contact'] != null ? payload['contact'] : payload;
      return Right(Contact.fromJson(contactData as Map<String, dynamic>));
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'فشل تعديل جهة الاتصال'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getContactLabels(int contactId) async {
    try {
      final response = await _api.get('contacts/$contactId/labels');
      final data = response.data;
      final list = data is Map && data['payload'] is List
          ? data['payload'] as List
          : (data is List ? data : []);
      return Right(list.map((e) => e is Map ? (e['title'] ?? e['name'] ?? '').toString() : e.toString()).where((e) => e.isNotEmpty).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> updateContactLabels(int contactId, List<String> labels) async {
    try {
      final response = await _api.post(
        'contacts/$contactId/labels',
        data: {'labels': labels},
      );
      final data = response.data;
      final list = data is Map && data['payload'] is List
          ? data['payload'] as List
          : (data is List ? data : []);
      return Right(list.map((e) => e is Map ? (e['title'] ?? e['name'] ?? '').toString() : e.toString()).where((e) => e.isNotEmpty).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Contact>> updateContactLifecycle(
    int contactId,
    String stage, {
    int? stageId,
    bool clearStage = false,
  }) async {
    return updateContact(
      contactId,
      lifecycleStageId: stageId,
      clearLifecycleStage: clearStage,
      customAttributes: {'lifecycle_stage': stage, 'lead_status': stage},
    );
  }
}
