import 'package:http/http.dart' as http;

typedef AccessTokenProvider = Future<String?> Function();
typedef TeamIdProvider = String? Function();

/// An [http.BaseClient] that stamps [Authorization: Bearer] and [X-Team-Id]
/// onto every outbound request. Both providers are resolved lazily per request.
class AuthHeaderClient extends http.BaseClient {
  AuthHeaderClient(
    this._inner,
    this._tokenProvider, {
    this.teamIdProvider,
  });

  final http.Client _inner;
  final AccessTokenProvider _tokenProvider;
  final TeamIdProvider? teamIdProvider;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = (await _tokenProvider())?.trim();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    final teamId = teamIdProvider?.call()?.trim();
    if (teamId != null && teamId.isNotEmpty) {
      request.headers['X-Team-Id'] = teamId;
    }
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
