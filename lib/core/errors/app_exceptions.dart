/// Base exception class for TuneTrack
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => '[$code] $message';
}

class AudioPlaybackException extends AppException {
  const AudioPlaybackException(super.message,
      {super.code, super.originalError});
}

class StorageException extends AppException {
  const StorageException(super.message, {super.code, super.originalError});
}

class SpotifyAuthException extends AppException {
  const SpotifyAuthException(super.message, {super.code, super.originalError});
}

class SpotifyApiException extends AppException {
  final int? statusCode;
  const SpotifyApiException(super.message,
      {super.code, this.statusCode, super.originalError});
}

class SyncException extends AppException {
  const SyncException(super.message, {super.code, super.originalError});
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.originalError});
}

class LocalMediaException extends AppException {
  const LocalMediaException(super.message, {super.code, super.originalError});
}
