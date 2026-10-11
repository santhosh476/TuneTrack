import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/spotify_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../../data/local/secure_storage_service.dart';

/// Handles official Spotify OAuth 2.0 Authorization Code with PKCE flow
class SpotifyAuthService {
  final SecureStorageService _secureStorage;
  final http.Client _client;

  // Stored in-memory PKCE code verifier during active auth flow
  String? _codeVerifier;
  String? _authState;

  // Connection state stream
  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

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
    _authState = _generateCodeVerifier().substring(0, 16);
    final codeChallenge = _generateCodeChallenge(_codeVerifier!);

    final params = {
      'client_id': clientId.trim().isEmpty
          ? SpotifyConstants.defaultClientId
          : clientId.trim(),
      'response_type': 'code',
      'redirect_uri': redirectUri,
      'code_challenge_method': 'S256',
      'code_challenge': codeChallenge,
      'state': _authState!,
      'scope': SpotifyConstants.scopesString,
    };

    final uri = Uri.parse(SpotifyConstants.authEndpoint)
        .replace(queryParameters: params);
    return uri.toString();
  }

  /// Extracts the authorization code from a callback URL or code string
  String? extractCodeFromUrl(String callbackUrlOrCode) {
    final trimmed = callbackUrlOrCode.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.contains('code=')) {
      try {
        final uri = Uri.parse(trimmed);
        return uri.queryParameters['code'];
      } catch (_) {
        // Fallback simple query string extraction
        final regex = RegExp(r'[?&]code=([^&]+)');
        final match = regex.firstMatch(trimmed);
        if (match != null && match.groupCount >= 1) {
          return match.group(1);
        }
      }
    }
    // If user directly pasted the raw code
    if (!trimmed.contains('://') && !trimmed.contains('?')) {
      return trimmed;
    }
    return null;
  }

  /// Exchanges the authorization code for an Access Token and Refresh Token via PKCE
  Future<String> exchangeCodeForToken({
    required String code,
    required String clientId,
    required String redirectUri,
  }) async {
    // If verifier is somehow lost (e.g. cold restart during browser auth), generate fallback verifier
    final verifier = _codeVerifier ?? _generateCodeVerifier();
    final effectiveClientId = clientId.trim().isEmpty
        ? SpotifyConstants.defaultClientId
        : clientId.trim();

    try {
      final response = await _client.post(
        Uri.parse(SpotifyConstants.tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': effectiveClientId,
          'grant_type': 'authorization_code',
          'code': code.trim(),
          'redirect_uri': redirectUri,
          'code_verifier': verifier,
        },
      );

      if (response.statusCode != 200) {
        try {
          final body = jsonDecode(response.body);
          throw SpotifyAuthException(
            body['error_description'] as String? ??
                'Token exchange failed with status ${response.statusCode}',
            code: body['error'] as String?,
          );
        } catch (e) {
          if (e is SpotifyAuthException) rethrow;
          throw SpotifyAuthException(
              'Spotify authorization failed (HTTP ${response.statusCode}): ${response.body}');
        }
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

      _connectionController.add(true);
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
    if (refreshToken == null || refreshToken.isEmpty) return null;

    final effectiveClientId = clientId.trim().isEmpty
        ? SpotifyConstants.defaultClientId
        : clientId.trim();

    try {
      final response = await _client.post(
        Uri.parse(SpotifyConstants.tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': effectiveClientId,
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        },
      );

      if (response.statusCode != 200) {
        // If refresh fails due to revoked grant, clear tokens
        if (response.statusCode == 400 || response.statusCode == 401) {
          await _secureStorage.clearSpotifyTokens();
          _connectionController.add(false);
        }
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

      _connectionController.add(true);
      return newAccessToken;
    } catch (_) {
      return null;
    }
  }

  /// Request Client Credentials Token for app-level API access (Search, Catalog)
  Future<String?> requestClientCredentialsToken({
    required String clientId,
    required String clientSecret,
  }) async {
    final effectiveId = clientId.trim().isEmpty
        ? SpotifyConstants.defaultClientId
        : clientId.trim();
    final credentials =
        base64Encode(utf8.encode('$effectiveId:${clientSecret.trim()}'));
    try {
      final response = await _client.post(
        Uri.parse(SpotifyConstants.tokenEndpoint),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'grant_type': 'client_credentials'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['access_token'] as String;
        final expiresIn = data['expires_in'] as int? ?? 3600;
        await _secureStorage.saveSpotifyTokens(
          accessToken: token,
          refreshToken: null,
          expiresInSeconds: expiresIn,
        );
        _connectionController.add(true);
        return token;
      }
    } catch (_) {}
    return null;
  }

  /// Gets valid access token, auto-refreshing or requesting client credentials if needed
  Future<String?> getValidAccessToken(String clientId) async {
    final isExpired = await _secureStorage.isSpotifyTokenExpired();
    if (!isExpired) {
      final token = await _secureStorage.getSpotifyAccessToken();
      if (token != null && token.isNotEmpty) return token;
    }

    // 1. Try OAuth Refresh token
    final refreshed = await refreshAccessToken(clientId);
    if (refreshed != null) return refreshed;

    // 2. Try Client Credentials if configured
    final storedSecret = await _secureStorage.getSpotifyClientSecret();
    final storedClientId = await _secureStorage.getSpotifyClientId();
    final effectiveId = (storedClientId != null && storedClientId.isNotEmpty)
        ? storedClientId
        : clientId;

    if (storedSecret != null &&
        storedSecret.isNotEmpty &&
        effectiveId.isNotEmpty) {
      final ccToken = await requestClientCredentialsToken(
        clientId: effectiveId,
        clientSecret: storedSecret,
      );
      if (ccToken != null) return ccToken;
    }

    return _secureStorage.getSpotifyAccessToken();
  }

  Future<void> disconnect() async {
    await _secureStorage.clearSpotifyTokens();
    _codeVerifier = null;
    _authState = null;
    _connectionController.add(false);
  }

  Future<bool> isConnected() async {
    final token = await _secureStorage.getSpotifyAccessToken();
    return token != null && token.isNotEmpty;
  }

  void dispose() {
    _connectionController.close();
  }
}
