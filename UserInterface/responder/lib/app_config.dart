const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL');
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
