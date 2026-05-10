# i18n Follow-Ups

Items scoped out of the initial i18n infrastructure work (validator/timestamp
refactor → all-3-apps ARB extraction → hardcoded-string lint + pre-commit
hook). The framework now ships English-only with a Spanish stub that proves
locale resolution wires through; everything below is needed before a real
non-English locale can ship.

## 1. Backend `error_code` enum + frontend typed `ApiError`

The API today returns English `message` strings and Pydantic `error_type`
discriminators. Translating backend errors client-side requires:

- Backend: add a domain-level `error_code` enum to error response payloads
  (`contracts/openapi.json` change). Existing English `message` stays as a
  human fallback for unmapped codes.
- Frontend: introduce a typed `ApiError` class, refactor ~30 `throw
  Exception(...)` sites in `auth_controller.dart`, `mission_out_api.dart`,
  `responder_api.dart`, `team_admin_repository.dart` to throw `ApiError`,
  then map `error_code` → localized ARB key at render time.

Until this lands, repository-thrown error strings render as English
passthrough in status banners.

## 2. In-app language picker

OS-locale-only today. When user demand for app-language-≠-OS-language
emerges, add:

- Persistence: `SharedPreferences` + a `preferred_locale` field on the user
  profile (so the choice survives reinstalls).
- A Settings screen entry that lists `AppLocalizations.supportedLocales`.
- Locale-aware backend so emails and push match the user's preference (see
  #3).

Rough size: ~50 LOC of UI plus the backend user-profile contract change.

## 3. Push and email body localization

Composed by backend (FCM payloads, transactional email templates). Backend
must learn the user's locale (via #2) and render templates per-locale.
Frontend cannot localize these because the strings never enter Flutter.

## 4. GitHub Actions CI

No CI exists today. When repo CI infrastructure is added,
`UserInterface/tools/check_no_hardcoded_strings.sh` drops in alongside
`flutter test`. The current safety net is the tracked `.githooks/pre-commit`
hook.

## 5. `shared_l10n` package

Each app has its own `lib/l10n/app_en.arb` today; common strings ("Cancel",
"Save", "Log out", validator messages, response-status select) are
duplicated across the three apps. Defer extraction into a shared package
until one of:

- ~20+ keys are demonstrably duplicated across all three apps, or
- A 4th client app is added, or
- A translator is hired and the duplication becomes a translation-cost
  problem.

Until then, the per-app ARB layout keeps each app independently shippable
without a cross-package codegen dependency.
