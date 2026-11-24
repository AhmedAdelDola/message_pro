import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../core/error/failures.dart';
import '../../../core/network/api_client.dart';
import '../../models/contact.dart';
import '../interfaces/i_collaborator_operations.dart';

class CollaboratorOperationsService implements ICollaboratorOperations {
  final ApiClient _api;

  CollaboratorOperationsService({ApiClient? api}) : _api = api ?? ApiClient();

  @override
  Future<Either<Failure, Contact>> getCollaborators(int conversationId) async {
    try {
      final response = await _api.get('conversations/$conversationId/collaborators');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return Right(Contact.fromJson(data));
      } else if (data is Map) {
        return Right(Contact.fromJson(Map<String, dynamic>.from(data)));
      }
      return Left(ServerFailure('Invalid response for collaborators'));
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'فشل تحميل المتعاونين'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Contact>> addCollaborator(int conversationId, int userId) async {
    try {
      final response = await _api.post(
        'conversations/$conversationId/collaborators',
        data: {'user_id': userId},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return Right(Contact.fromJson(data));
      } else if (data is Map) {
        return Right(Contact.fromJson(Map<String, dynamic>.from(data)));
      }
      return Left(ServerFailure('Invalid response'));
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'فشل إضافة المتعاون'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Contact>> removeCollaborator(int conversationId, int userId) async {
    try {
      final response = await _api.delete('conversations/$conversationId/collaborators/$userId');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return Right(Contact.fromJson(data));
      } else if (data is Map) {
        return Right(Contact.fromJson(Map<String, dynamic>.from(data)));
      }
      return Left(ServerFailure('Invalid response'));
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'فشل حذف المتعاون'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
