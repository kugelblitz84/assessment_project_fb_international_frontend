# AutoCare

Flutter foundations for a car service booking application. Authentication uses HTTP;
service catalogue, booking screens, profile editing and the AI assistant remain
placeholders. This migration adds no production UI design or dependencies.

## Run locally

Use a Flutter SDK compatible with Dart `^3.11.5`:

```sh
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

The default URL reaches the development computer from the Android emulator. Use a
reachable LAN address on physical devices, or HTTPS for deployed builds. Base paths
such as `https://example.com/api` are supported. Android allows development HTTP only
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

## Session architecture

Riverpod's `AsyncNotifier` session controller owns restoration, authentication and
logout. `currentUserProvider` derives the user from session state; there are no
business-data caches yet. User state clears on logout, invalid sessions and account
replacement. Login/register forms own submission state and errors, with no competing
success-navigation logic. Replacing an account invalidates the previous request
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

## Backend contract and limits

These contracts must be supplied by the separate backend; tests use HTTP adapters,
not a live server:

- `POST /auth/login`: `{email, password}`.
- `POST /auth/register`: `{name, email, password}`.
- Both return `{accessToken, user: {id, name, email}}` and set a refresh cookie.
- `GET /auth/me`: bearer authorization, returns `{user: {id, name, email}}`.
- `POST /auth/refresh`: refresh cookie, returns `{accessToken}` and rotates the cookie.
- `POST /auth/logout`: revokes/clears the cookie session; returns 200/204.
- Refresh and logout send no bearer token or refresh-token body. Refresh rejection
  uses 401. Protected 401s with no code or `ACCESS_TOKEN_EXPIRED` allow renewal;
  other explicit error codes skip renewal. A second 401 is returned without retry.
- Required response strings must be nonempty. Invalid shapes and HTTP failures become
  safe domain errors. Backend authorization must enforce all private business APIs;
  frontend navigation guards do not replace server authorization.

Production requires HTTPS, HttpOnly/Secure refresh cookies, an appropriate SameSite
policy and a narrow cookie path covering refresh/logout. Cross-site web deployments
need SameSite=None; Secure, exact CORS origins, credential support and preflight support
for Content-Type/Authorization. Cookie-authenticated mutations require backend CSRF
protection (Origin/SameSite checks or an agreed CSRF token/header contract).

The HTTP emulator default cannot send Secure cookies. Use trusted local HTTPS for
production-like refresh testing. Browser cookie blocking may prevent persistence.
Browser cookie deletion after failed server logout cannot be guaranteed. Refresh
rotation/reuse detection and revocation are backend responsibilities; single-flight
coordination is per provider container, so multiple tabs/processes require backend
concurrency tolerance or additional coordination. Native device storage, browser
cookie behavior and iOS compilation still require platform integration validation.

## Verification

Run `dart format lib test`, `flutter analyze`, and `flutter test`.
Tests cover startup loading and deep links, guest/private access, return destinations,
logout, restoration retry, redirect security, cookies and concurrent token refresh.
Storage uses platform mocks; live backend and platform integration remain separate.
