(function () {
  function isSupported() {
    return (
      typeof window !== 'undefined' &&
      'Notification' in window &&
      'serviceWorker' in navigator &&
      'PushManager' in window
    );
  }

  function supportsServiceWorker() {
    return typeof navigator !== 'undefined' && 'serviceWorker' in navigator;
  }

  function supportsPush() {
    return typeof window !== 'undefined' && 'PushManager' in window;
  }

  function urlBase64ToUint8Array(base64String) {
    var padding = '='.repeat((4 - (base64String.length % 4)) % 4);
    var base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/');
    var rawData = window.atob(base64);
    var outputArray = new Uint8Array(rawData.length);
    for (var i = 0; i < rawData.length; ++i) {
      outputArray[i] = rawData.charCodeAt(i);
    }
    return outputArray;
  }

  async function registerServiceWorker(scriptUrl) {
    if (!supportsServiceWorker()) {
      return { success: false, error: 'Service workers are not supported.' };
    }

    try {
      await navigator.serviceWorker.register(scriptUrl);
      return { success: true };
    } catch (error) {
      return {
        success: false,
        error: error && error.message ? error.message : String(error),
      };
    }
  }

  async function subscribe(applicationServerKey) {
    if (!isSupported()) {
      return null;
    }

    var registration = await navigator.serviceWorker.ready;
    var existing = await registration.pushManager.getSubscription();
    var subscription =
      existing ||
      (await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: urlBase64ToUint8Array(applicationServerKey),
      }));

    if (!subscription) {
      return null;
    }

    var json = subscription.toJSON();
    return {
      endpoint: json.endpoint,
      p256dh: json.keys && json.keys.p256dh ? json.keys.p256dh : '',
      auth: json.keys && json.keys.auth ? json.keys.auth : '',
    };
  }

  window.missionOutWebPush = {
    isSupported: isSupported,
    supportsServiceWorker: supportsServiceWorker,
    supportsPush: supportsPush,
    registerServiceWorker: registerServiceWorker,
    subscribe: subscribe,
  };
})();
