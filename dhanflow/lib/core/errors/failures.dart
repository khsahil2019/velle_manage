class Failure implements Exception {
  final String message;
  final int? statusCode;

  const Failure(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Unable to reach server. Operating in offline mode.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message) : super(statusCode: 422);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication required']) : super(statusCode: 401);
}
