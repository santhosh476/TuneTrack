import 'package:uuid/uuid.dart';

/// Cryptographically secure, stable UUID v4 and prefix-based ID generator
class IdGenerator {
  IdGenerator._();

  static const Uuid _uuid = Uuid();

  /// Generates a standard UUID v4 string
  static String generateUuid() {
    return _uuid.v4();
  }

  /// Generates a track ID with prefix
  static String generateTrackId() {
    return 'trk_${_uuid.v4()}';
  }

  /// Generates a listening session ID with prefix
  static String generateSessionId() {
    return 'ses_${_uuid.v4()}';
  }

  /// Generates a playlist ID with prefix
  static String generatePlaylistId() {
    return 'ply_${_uuid.v4()}';
  }

  /// Generates an anonymous local guest ID
  static String generateGuestId() {
    return 'gst_${_uuid.v4().substring(0, 12)}';
  }
}
