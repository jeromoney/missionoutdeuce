const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
const webPushPublicKey = String.fromEnvironment(
  'WEB_PUSH_PUBLIC_KEY',
  defaultValue: '',
);
const emailLinkContinueUrl = String.fromEnvironment(
  'EMAIL_LINK_CONTINUE_URL',
  defaultValue: '',
);

String resolveApiBaseUrl() {
  if (apiBaseUrl.endsWith('/')) {
    return apiBaseUrl.substring(0, apiBaseUrl.length - 1);
  }
  return apiBaseUrl;
}
