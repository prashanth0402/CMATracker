/// Custom application exceptions. Raw SQLite / platform errors must be wrapped
/// in one of these before reaching the UI layer.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  /// User-friendly message safe to display.
  final String message;

  /// Original error, for logging only – never shown to users.
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.cause});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.cause});
}

class TimerException extends AppException {
  const TimerException(super.message, {super.cause});
}

class BackupException extends AppException {
  const BackupException(super.message, {super.cause});
}

class ImportException extends AppException {
  const ImportException(super.message, {super.cause});
}

class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.cause});
}
