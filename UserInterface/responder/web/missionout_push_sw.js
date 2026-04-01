self.addEventListener('install', function (event) {
  self.skipWaiting();
});

self.addEventListener('activate', function (event) {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('push', function (event) {
  var payload = {};
  try {
    payload = event.data ? event.data.json() : {};
  } catch (error) {
    payload = {
      title: 'MissionOut alert',
      body: event.data ? event.data.text() : 'New responder alert',
    };
  }

  var title = payload.title || 'MissionOut alert';
  var body = payload.body || 'New responder alert';
  var incidentId = payload.incident_id || null;

  event.waitUntil(
    self.registration.showNotification(title, {
      body: body,
      data: {
        incidentId: incidentId,
        url: '/',
      },
    }),
  );
});

self.addEventListener('notificationclick', function (event) {
  event.notification.close();

  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then(
      function (clientList) {
        for (var i = 0; i < clientList.length; i += 1) {
          var client = clientList[i];
          if ('focus' in client) {
            return client.focus();
          }
        }

        if (self.clients.openWindow) {
          return self.clients.openWindow('/');
        }

        return Promise.resolve();
      },
    ),
  );
});
