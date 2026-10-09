import '../../services/spotify/spotify_auth_service.dart';
import '../../services/spotify/spotify_api_service.dart';
import '../models/track_model.dart';
import '../models/artist_model.dart';

class SpotifyRepository {
  final SpotifyAuthService _authService;
  final SpotifyApiService _apiService;
  String _clientId = '';

  SpotifyRepository(this._authService, this._apiService);

  void configureClientId(String clientId) {
    _clientId = clientId;
  }

  String get clientId => _clientId;
  bool get hasClientId => _clientId.isNotEmpty;

  Future<bool> isConnected() => _authService.isConnected();

  String getAuthorizationUrl(String redirectUri) {
    return _authService.buildAuthorizationUrl(
      clientId: _clientId,
      redirectUri: redirectUri,
    );
  }

  Future<String> handleAuthCode(String code, String redirectUri) {
    return _authService.exchangeCodeForToken(
      code: code,
      clientId: _clientId,
      redirectUri: redirectUri,
    );
  }

  Future<void> disconnect() => _authService.disconnect();

  Future<Map<String, dynamic>> searchSpotify(String query) async {
    final token = await _authService.getValidAccessToken(_clientId);
    if (token == null) {
      return {'tracks': <TrackModel>[], 'artists': <ArtistModel>[]};
    }
    return _apiService.search(token: token, query: query);
  }

  Future<Map<String, dynamic>?> getPlaybackState() async {
    final token = await _authService.getValidAccessToken(_clientId);
    if (token == null) return null;
    return _apiService.getPlaybackState(token);
  }
}
