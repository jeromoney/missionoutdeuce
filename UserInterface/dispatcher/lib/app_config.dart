const _apiBaseUrlFromEnv = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: '',
);

const emailLinkContinueUrl = String.fromEnvironment(
  'EMAIL_LINK_CONTINUE_URL',
  defaultValue: '',
);

const _defaultApiBaseUrl = 'http://127.0.0.1:8000';

String resolveApiBaseUrl() {
  if (_apiBaseUrlFromEnv.isNotEmpty) {
    return _trimTrailingSlash(_apiBaseUrlFromEnv);
  }

  final baseUri = Uri.base;
  final host = baseUri.host.toLowerCase();
  final isLocalHost = host == 'localhost' || host == '127.0.0.1';

  if (isLocalHost || host.isEmpty) {
    return 'http://127.0.0.1:8000';
  }

  return _defaultApiBaseUrl;
}

String _trimTrailingSlash(String value) {
  if (value.endsWith('/')) {
    return value.substring(0, value.length - 1);
  }
  return value;
}
