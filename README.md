# AutoCare

Responsive Flutter car service booking UI, using Riverpod 3, GoRouter, Dio and
feature-first model/view/controller/service modules. All customer screens are
implemented. Authentication, catalog and the Gemini assistant use the live backend by default.
Booking/profile business adapters still require their remaining HTTP integration.
An explicit demo target retains in-memory sample data. No frontend dependencies were added.

## Run locally

Use a Flutter SDK compatible with Dart `^3.11.5`:

For a complete demo without a backend:

```sh
flutter pub get
flutter run -t lib/demo/main_demo.dart
# Or: flutter run -d chrome -t lib/demo/main_demo.dart
```

Sign in with any valid email and a nonempty password, or register a sample account.
Demo credentials, profile changes and appointments stay in memory. Restarting resets
the demo. This target overrides the existing Core auth dependencies; the actual
session controller and route guards still run. It is not a production auth adapter.

The normal entry point preserves real authentication:

```sh
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```

The default URL reaches the development computer from the Android emulator. Use a
reachable LAN address on physical devices, or HTTPS for deployed builds. Base paths
must include `/api/v1`, for example `https://example.com/api/v1`. Android allows development HTTP only
in debug builds. iOS local transport exceptions require Xcode configuration. Web
secure storage requires HTTPS or localhost and backend CORS configuration.

## Navigation

App shows a loading screen while session restoration is unresolved, keeping the
Router subtree unmounted so protected pages cannot start private requests.
GoRouter stays stable, preserves deep links and defaults to Home. Restoration
errors allow guest browsing and preserve credentials; Profile offers retry.

Guests can browse Home, services, Profile and AI Assistant. Booking routes and
profile editing require authentication. Only recognized protected routes are valid
return destinations. Login/Register preserve that destination or default to Home.
Logout rebuilds Profile in guest mode; invalidation on private routes goes to Login.
Malformed, external, ambiguous and traversal redirects remain rejected.

Primary pages use four lazy `StatefulShellRoute.indexedStack` branches: Explore,
Bookings, AI Assistant and Profile. The shell owns primary navigation. Tab switches
restore the branch's last location; reselecting the active tab preserves its stack,
scroll and filters. Inactive branches mute tickers. Booking details/confirmation and
profile editing stay in their branches with primary navigation hidden; service
details and appointment booking use the root navigator. Existing URLs remain valid.

Authentication ownership changes replace branch navigators and clear private state
without replacing GoRouter. Profile edits preserve the authentication generation,
conversation, history filters and active booking drafts.

Feature caching and background refresh stay independent of routing.
SharedPreferences is retained for future caching; caching is not implemented.

Route names and identifier parameters are centralized in `lib/routes/app_routes.dart`;
registration is in `app_pages.dart`, access rules and redirect validation in
`route_access_policy.dart`, and redirects in `router_provider.dart`.

| Page | Name | Path | Access |
| --- | --- | --- | --- |
| Login | `login` | `/login` | Guest |
| Register | `register` | `/register` | Guest |
| Home | `home` | `/home` | Public |
| Service details | `serviceDetails` | `/services/:serviceId` | Public |
| Booking | `booking` | `/services/:serviceId/book` | Authenticated |
| Booking confirmation | `bookingConfirmation` | `/bookings/:bookingId/confirmation` | Authenticated |
| My bookings | `myBookings` | `/bookings` | Authenticated |
| Booking details | `bookingDetails` | `/bookings/:bookingId` | Authenticated |
| Profile | `profile` | `/profile` | Public |
| Edit profile | `editProfile` | `/profile/edit` | Authenticated |
| AI assistant | `assistant` | `/assistant` | Public |
| Not found | `notFound` | `/not-found` | Public |

## Feature architecture

Features follow the model/view/controller/service convention described in
`AutoCare_Feature_Architecture.md`. Existing pages and auth form helpers live in
`lib/features/<feature>/view/`. The current feature modules are `auth`, `home`,
`services`, `booking`, `bookings`, `profile` and `assistant`.

The singular folders separate responsibilities:

| Folder | Responsibility |
| --- | --- |
| `model/` | Immutable typed response data, request payloads and feature state |
| `service/` | Concrete API clients using `dioProvider`, returning typed data |
| `controller/` | Riverpod 3 `Notifier`/`AsyncNotifier` state and service orchestration |
| `view/` | Pages and widgets watching providers and dispatching events |

Controllers wrap service operations with `ApiErrorHandler.run` from
`lib/core/network/api_error_handler.dart`. Services return data directly; the
handler produces `ApiResponse<T>` once. Check `result.success`, including for
`void` or nullable data, and use `ApiErrorHandler.messageFor(result.errorCode)`
for safe UI messages. The handler maps transport, HTTP, parsing and existing
session exceptions without performing refresh, retries or navigation. Until
domain errors are confirmed by the backend, HTTP 409 maps only to `CONFLICT`.

Code shared by multiple business features belongs in `features/shared/`, using
the same singular folder names. Core owns infrastructure and must not depend on
concrete features. Keep one authoritative model/service for shared catalogue or
appointment data. Private feature providers clear on authentication ownership
changes and discard results from the previous account. Auth views continue using the existing
Core session implementation through a short-lived form controller; there is no
second auth service or session store.

Catalogue and appointment models, services, controllers and business widgets are
shared under `features/shared/`. Home owns its filters, Booking owns its draft and
availability, Bookings owns its tab selection, Profile owns profile mutations and
Assistant owns the conversation. Authentication views use the existing Core session.
`SessionController.updateUser` accepts profile results only for the active account.

Layouts use a 900px desktop breakpoint, a centered 560px compact column and a
1200px desktop container. Compact pages have bottom navigation; desktop pages have
top navigation. Shared theme tokens and bounded ScreenUtil spacing keep controls
readable across widths. Form input, search, booking selections and chat drafts
survive window resizing. See [UI implementation notes](docs/ui_implementation.md).

## Session architecture

Riverpod's `AsyncNotifier` session controller owns restoration, authentication and
logout. `currentUserProvider` derives the user from session state; there are no
business-data caches yet. User state clears on logout, invalid sessions and account
replacement. Login/register form controllers own submission state and errors,
with no competing success-navigation logic. Replacing an account invalidates the previous request
generation, drains pending refresh/auth work and clears previous native credentials.

A stored access token is validated with `GET /auth/me`, allowing one coordinated
refresh if expired. Without an access token, native restoration first checks for an
applicable persisted refresh cookie. Fresh native installs make no backend request.
Web must probe refresh because browser-managed HttpOnly cookies cannot be inspected.
An invalid session clears native credentials and enters guest mode. Network, malformed
response and storage errors retain potentially valid credentials, disable protected
requests and expose retry from guest Profile. Automatic restoration retries are disabled.

Authentication publishes the user only after secure token persistence. Logout first
invalidates refresh, drains in-flight auth/refresh work, attempts server revocation,
and clears local credentials before publishing guest state. Local deletion failures
remain visible on Profile for retry. Remote logout failure still permits local logout;
web cannot locally remove an HttpOnly cookie if server revocation fails.

Access tokens use Flutter Secure Storage, never SharedPreferences. Android backup is
disabled to avoid restoring encrypted data without its device key; iOS Keychain
entitlements are connected for Debug, Profile and Release.

## API request access and refresh

Business requests default to `RequestAccess.protected` (fail closed). Public requests
must explicitly opt in through Dio options:

```dart
final response = await dio.get<Object?>(
  '/services',
  options: Options(extra: {requestAccessKey: RequestAccess.public}),
);
```

Import `core/network/request_access.dart` alongside Dio. Public requests strip bearer
authorization, work without a token and after logout, and never trigger refresh.
Auth endpoints are independently classified and always skip bearer injection/refresh.
Protected requests require a token and an active request generation. Bearer tokens
are limited to the configured backend origin/base path and stripped from external
requests. Automatic HTTP redirects are disabled. Generation checks prevent requests
waiting on storage from carrying an old session across logout/account replacement.

One shared coordinator refreshes concurrent failures once, reuses newer saved tokens
for late failures and retries replayable protected requests once. Streams and multipart
requests are not replayed; refresh itself is not retried. Logout invalidates pending
refresh results. Temporary refresh failures preserve credentials; invalid refresh
sessions clear credentials and user state. Normal background refresh does not change
application loading/navigation state.

Native clients share a PersistCookieJar backed by Flutter Secure Storage, namespaced
by backend URL. Only trusted backend paths load/save cookies; cookie expiration, path,
domain and Secure flags are handled by cookie_jar. Web uses credentialed requests and
browser-managed cookies, rejecting untrusted destinations. Tokens and credentials are
never logged or displayed.

## Backend contract and Gemini assistant

The adjacent backend implements authentication, catalog, packages, offers, availability, appointments and a public Gemini assistant under `/api/v1`. The frontend now connects authentication, catalog and assistant calls. Its remaining booking/profile business adapters still require HTTP wiring; explicit demo mode preserves the complete offline UI.

- Android: `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1`.
- Browser: `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api/v1`; allow the exact browser origin in backend CORS configuration.
- Offline demo: `flutter run -t lib/demo/main_demo.dart`, or opt into business demo data with `--dart-define=DEMO_DATA=true`.

Default mode uses live endpoints. The backend owns GEMINI_API_KEY and model configuration; no provider key enters Flutter. POST `/assistant/chat` sends at most twelve recent messages and 12,000 characters. Strict response models accept only `serviceDetails` with an actual service/package UUID and `browseServices` with an optional category UUID. Recommendation cards use the refreshed live catalog for images, effective/original prices, duration and View service/View package labels. Navigation uses existing AppRoutes; arbitrary URLs/actions are rejected. Riverpod state, account isolation, retry/clear and stale-response protections remain.

Guest assistant calls use optional authentication; signed-in calls attach the existing access token. Public catalog calls omit credentials. Browser refresh/logout first acquire `/auth/csrf` and send `X-CSRF-Token` with credentialed cookies. The shared coordinator serializes refresh. Native cookie transport needs no browser CSRF header. Production requires HTTPS and secure host-only HttpOnly cookies. Revoked/expired sessions cannot access protected backend APIs. Multiple browser tabs must coordinate refresh to avoid strict replay revocation.

Messages go to Google Gemini. Free-tier data may be used to improve products. Do not send names, emails, phones, credentials, vehicle registrations or private appointments. The backend screens common sensitive patterns and supplies public catalog/policy data only; automated screening cannot identify every kind of personal information. No backend chat-history table exists. The assistant cannot create/cancel appointments or provide definitive mechanical diagnoses. This privacy notice also appears in the assistant UI.

Disabled/configuration errors, limits, quota exhaustion, timeout and invalid output use locally defined safe messages. Live model availability still requires a successful configured request; fake-provider tests do not establish it. Browser cookie behavior and native platform persistence also need deployment checks.


## Verification

Run `dart format lib test`, `flutter analyze`, and `flutter test`.
Build the demo with `flutter build web -t lib/demo/main_demo.dart` or
`flutter build apk --debug -t lib/demo/main_demo.dart`.

Tests additionally cover the complete guest booking/cancellation interaction,
duplicate submissions, conflicts, latest-date response ordering, ambiguous mutation
timeouts, profile/session synchronization, assistant retry/action validation and
session-scoped clearing. The responsive matrix renders all pages at 320, 375, 390,
430, 768, 900, 1024, 1280 and 1440 logical pixels with normal and 2x text, checks
keyboard-open chat and verifies state survives resizing.

Optional screenshot generation writes to `build/ui_screenshots/`:

```sh
flutter test test/ui_screenshots_test.dart --dart-define=CAPTURE_UI=true
# For legible review fonts, also pass --dart-define=SCREENSHOT_FONT=/path/to/font.ttf
```

Screenshots from widget tests deliberately exercise network-image fallbacks.
Tests cover startup loading and deep links, guest/private access, return destinations,
logout, restoration retry, redirect security, cookies and concurrent token refresh.
API error tests cover typed/nullable/no-content success, network/timeouts, HTTP
failures, generic conflicts, malformed JSON/models, session exceptions and safe
message fallbacks without mutation retries.
Storage uses platform mocks; live backend and platform integration remain separate.

See [the refactoring report](docs/refactoring_report.md) for the navigation choices,
controller and widget changes, lifecycle rules, verification and complete file list.
