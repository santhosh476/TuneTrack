import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/spotify_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../../data/local/secure_storage_service.dart';

/// Handles Spotify OAuth 2.0 PKCE Authorization flow
class SpotifyAuthService {
  final SecureStorageService _secureStorage;
  final http.Client _client;

  // Stored in-memory PKCE code verifier during active auth flow
  String? _codeVerifier;

  SpotifyAuthService(this._secureStorage, [http.Client? client])
      : _client = client ?? http.Client();

  /// Generates a high-entropy cryptographic code verifier for PKCE
  String _generateCodeVerifier() {
    final random = Random.secure();
    final values = List<int>.generate(64, (i) => random.nextInt(256));
    return base64UrlEncode(values)
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
  }

  /// Generates code challenge from verifier using SHA-256
  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes)
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
  }

  /// Builds the official Spotify Authorization URL for PKCE
  String buildAuthorizationUrl({
    required String clientId,
    required String redirectUri,
  }) {
    _codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(_codeVerifier!);

    final params = {
      'client_id': clientId,
      'response_type': 'code',
      'redirect_uri': redirectUri,
      'code_challenge_method': 'S256',
      'code_challenge': codeChallenge,
      'scope': SpotifyConstants.scopesString,
    };

    final uri = Uri.parse(SpotifyConstants.authEndpoint)
        .replace(queryParameters: params);
    return uri.toString();
  }

  /// Exchanges the authorization code for an Access Token and Refresh Token via PKCE
  Future<String> exchangeCodeForToken({
    required String code,
    required String clientId,
    required String redirectUri,
  }) async {
    if (_codeVerifier == null) {
      throw const SpotifyAuthException(
          'PKCE code verifier is missing. Please initiate authorization first.');
    }

    try {
      final response = await _client.post(
        Uri.parse(SpotifyConstants.tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': redirectUri,
          'code_verifier': _codeVerifier!,
        },
      );

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw SpotifyAuthException(
          body['error_description'] as String? ??
              'Token exchange failed with status ${response.statusCode}',
          code: body['error'] as String?,
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final accessToken = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String?;
      final expiresIn = data['expires_in'] as int? ?? 3600;

      await _secureStorage.saveSpotifyTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresInSeconds: expiresIn,
      );

      return accessToken;
    } catch (e) {
      if (e is SpotifyAuthException) rethrow;
      throw SpotifyAuthException(
          'Network error during Spotify authorization: $e');
    }
  }

  /// Refreshes expired access token using stored refresh token
  Future<String?> refreshAccessToken(String clientId) async {
    final refreshToken = await _secureStorage.getSpotifyRefreshToken();
    if (refreshToken == null) return null;

    try {
      final response = await _client.post(
        Uri.parse(SpotifyConstants.tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        },
      );

      if (response.statusCode != 200) {
        await _secureStorage.clearSpotifyTokens();
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final newAccessToken = data['access_token'] as String;
      final newRefreshToken = data['refresh_token'] as String? ?? refreshToken;
      final expiresIn = data['expires_in'] as int? ?? 3600;

      await _secureStorage.saveSpotifyTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
        expiresInSeconds: expiresIn,
      );

      return newAccessToken;
    } catch (_) {
      return null;
    }
  }

  /// Gets valid access token, auto-refreshing if expired
  Future<String?> getValidAccessToken(String clientId) async {
    final isExpired = await _secureStorage.isSpotifyTokenExpired();
    if (isExpired) {
      return refreshAccessToken(clientId);
    }
    return _secureStorage.getSpotifyAccessToken();
  }

  Future<void> disconnect() async {
    await _secureStorage.clearSpotifyTokens();
  }

  Future<bool> isConnected() async {
    final token = await _secureStorage.getSpotifyAccessToken();
    return token != null && token.isNotEmpty;
  }
}
