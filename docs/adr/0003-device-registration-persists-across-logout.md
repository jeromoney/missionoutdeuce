# Device Registration Persists Across Logout

A Device remains registered and active in the backend when a user logs out of the responder app. FCM delivery is not suppressed by logout.

## Considered Options

**Deactivate Device on logout** — the app calls a deregister endpoint on logout, setting `Device.is_active = False`. The user stops receiving Incident pages immediately on logout.

**Registration persists across logout (chosen)** — logout makes no backend call regarding the Device. The Device stays active. The only paths that suppress FCM delivery are the user explicitly toggling Availability to Unavailable, or FCM returning a permanent token rejection (e.g. `NOT_REGISTERED` on uninstall).

## Consequences

- A user who logs out of the app continues to receive Incident pages until they toggle Unavailable or uninstall the app.
- Installing the app is the opt-in gesture; uninstalling is the opt-out gesture. No in-app soft opt-out exists beyond the Availability toggle.
- The backend has no logout endpoint for Devices. The `POST /devices/fcm` registration endpoint is the only app-initiated write path for token validity.
- Token rotation while the app is running in the background is an accepted gap: `onNewToken` updates SharedPreferences, but re-registration only occurs on the next app launch after auth resolves. For an emergency alerting system, the monitoring layer (planned) is the backstop for detecting stale tokens at the team level.
- This is an emergency alerting system. The design prioritises delivery over user convenience. A member who does not want to receive pages should toggle Unavailable or uninstall.
