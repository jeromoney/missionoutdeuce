const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000',
);
const webPushPublicKey = String.fromEnvironment(
  'WEB_PUSH_PUBLIC_KEY',
  defaultValue: '',
);

String resolveApiBaseUrl() {
  if (apiBaseUrl.endsWith('/')) {
    return apiBaseUrl.substring(0, apiBaseUrl.length - 1);
  }
  return apiBaseUrl;
}
