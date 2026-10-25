import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'حدث خطأ في الاتصال بالخادم']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'يرجى التحقق من اتصالك بالإنترنت']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'بيانات تسجيل الدخول غير صحيحة']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'فشل في استرجاع البيانات المحفوظة']);
}
