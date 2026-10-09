import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';

/// Secure platform storage for sensitive tokens and credentials
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions:
                  IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  Future<void> saveSpotifyTokens({
    required String accessToken,
    required String? refreshToken,
    required int expiresInSeconds,
  }) async {
    final expiresAt = DateTime.now()
        .add(Duration(seconds: expiresInSeconds))
        .millisecondsSinceEpoch
        .toString();
    await _storage.write(
        key: AppConstants.keySpotifyAccessToken, value: accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(
          key: AppConstants.keySpotifyRefreshToken, value: refreshToken);
    }
    await _storage.write(
        key: AppConstants.keySpotifyExpiresAt, value: expiresAt);
  }

  Future<String?> getSpotifyAccessToken() async {
    return _storage.read(key: AppConstants.keySpotifyAccessToken);
  }

  Future<String?> getSpotifyRefreshToken() async {
    return _storage.read(key: AppConstants.keySpotifyRefreshToken);
  }

  Future<bool> isSpotifyTokenExpired() async {
    final expiresAtStr =
        await _storage.read(key: AppConstants.keySpotifyExpiresAt);
    if (expiresAtStr == null) return true;
    final expiresAtMs = int.tryParse(expiresAtStr);
    if (expiresAtMs == null) return true;
    // Buffer by 60 seconds
    return DateTime.now().millisecondsSinceEpoch >= (expiresAtMs - 60000);
  }

  Future<void> clearSpotifyTokens() async {
    await _storage.delete(key: AppConstants.keySpotifyAccessToken);
    await _storage.delete(key: AppConstants.keySpotifyRefreshToken);
    await _storage.delete(key: AppConstants.keySpotifyExpiresAt);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
