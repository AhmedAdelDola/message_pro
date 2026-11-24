import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../models/contact.dart';

abstract class ICollaboratorOperations {
  Future<Either<Failure, Contact>> getCollaborators(int conversationId);
  Future<Either<Failure, Contact>> addCollaborator(int conversationId, int userId);
  Future<Either<Failure, Contact>> removeCollaborator(int conversationId, int userId);
}
