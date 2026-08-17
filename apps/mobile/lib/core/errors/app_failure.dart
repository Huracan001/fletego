/// Central app failures. Map to Spanish copy at the UI boundary.
sealed class AppFailure implements Exception {
  const AppFailure(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

final class NetworkFailure extends AppFailure {
  // ignore: use_super_parameters — cause is a named super param
  const NetworkFailure([
    String message =
        'No pudimos conectar. Revisa tu conexión e inténtalo de nuevo.',
    Object? cause,
  ]) : super(message, cause: cause);
}

final class AuthFailure extends AppFailure {
  // ignore: use_super_parameters
  const AuthFailure([
    String message = 'No pudimos autenticarte. Verifica tus datos.',
    Object? cause,
  ]) : super(message, cause: cause);
}

final class PermissionFailure extends AppFailure {
  // ignore: use_super_parameters
  const PermissionFailure([
    String message = 'No tienes permiso para realizar esta acción.',
    Object? cause,
  ]) : super(message, cause: cause);
}

final class NotFoundFailure extends AppFailure {
  // ignore: use_super_parameters
  const NotFoundFailure([
    String message = 'No encontramos lo que buscabas.',
    Object? cause,
  ]) : super(message, cause: cause);
}

final class ValidationFailure extends AppFailure {
  // ignore: use_super_parameters
  const ValidationFailure([
    String message = 'Revisa los datos ingresados.',
    Object? cause,
  ]) : super(message, cause: cause);
}

final class UnexpectedFailure extends AppFailure {
  // ignore: use_super_parameters
  const UnexpectedFailure([
    String message = 'Ocurrió un error inesperado. Inténtalo de nuevo.',
    Object? cause,
  ]) : super(message, cause: cause);

  factory UnexpectedFailure.fromCause(Object cause) => UnexpectedFailure(
    'Ocurrió un error inesperado. Inténtalo de nuevo.',
    cause,
  );
}
