import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../core/error/failures.dart';
import '../../core/network/api_client.dart';
import '../models/contact.dart';
import '../models/conversation.dart';

abstract class IContactRepository {
  Future<Either<Failure, List<Contact>>> searchContacts(String query, {int page = 1});
  Future<Either<Failure, Contact>> getContact(int id);
  Future<Either<Failure, List<Conversation>>> getContactConversations(int contactId);
  Future<Either<Failure, Contact>> createContact({
    required String name,
    String? email,
    String? phoneNumber,
  });
}

class ContactRepository implements IContactRepository {
  final ApiClient _api;

  ContactRepository({ApiClient? api}) : _api = api ?? ApiClient();

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
  }) async {
    try {
      final response = await _api.post(
        'contacts',
        data: {
          'name': name,
          'email': email,
          'phone_number': phoneNumber,
        },
      );
      final data = response.data;
      final payload = data is Map && data['payload'] != null ? data['payload'] : data;
      return Right(Contact.fromJson(payload as Map<String, dynamic>));
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'فشل إنشاء جهة الاتصال'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
