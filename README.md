# AutoCare

Your car. Expert care. One tap away.

Flutter foundations for a car service booking application. The service catalogue,
appointments, booking management, profile editing, and AI assistant are placeholders.
Authentication uses real HTTP requests.

## Run locally

Use a Flutter SDK compatible with the existing Dart `^3.11.5` constraint.

```sh
flutter pub get
flutter run
```

The default API base URL is `http://10.0.2.2:3000`, which reaches the development
computer from the Android emulator. For a physical Android device on the same
network, use the computer's LAN address and make the backend reachable on that
interface:

```sh
flutter run --dart-define=API_BASE_URL=http://YOUR_LOCAL_IP:3000
```

The URL may include a base path, for example `https://example.com/api`.
Configure deployed builds with an HTTPS backend URL. Android permits development
HTTP in the debug manifest only; Internet permission is included for all builds.
For iOS, use HTTPS or configure a local development transport exception in Xcode
when needed. iOS builds and device Keychain behavior require macOS/Xcode validation.
Web development needs backend CORS configuration; web secure storage requires HTTPS
or localhost.

The app launches without a running backend: a fresh installation opens Login.
If a saved token exists and the backend is unreachable, startup displays the retry
page and preserves that token.

## Architecture

Features own their presentation pages. Shared authentication and session behavior
lives in `core/session`:

- Domain: immutable `UserEntity` and `AuthSession`, sealed `AuthState`, repository
  and token-storage contracts, and session exceptions. No Flutter, Dio, or JSON dependencies.
- Data: validated `UserModel` JSON parsing, Dio repository implementation, and
  Flutter Secure Storage adapter.
- Application: Riverpod 3 `AsyncNotifier` session controller, derived current user,
  and dependency providers. A separate token-storage provider avoids circular
  imports between network and repository wiring.
- Presentation: bootstrap/retry screens and feature pages. Forms own submission
  loading, validation, and error feedback; pages do not call APIs directly.
- Network: environment-based Dio configuration, JSON handling, 15-second connect,
  send, and receive timeouts, and a bearer interceptor. Endpoint paths are centralized.
- Routes: names, paths, parameter helpers, page registration, and session-driven
  GoRouter refresh/redirects. Provider disposal releases the router and Dio.

No packages were added, removed, or upgraded. Existing Riverpod, GoRouter, Dio,
Flutter Secure Storage, and ScreenUtil dependencies are used without code generation.
SharedPreferences is retained but is never used for authentication tokens.

## Session and token flow

1. `main.dart` initializes Flutter bindings and `ProviderScope`. `App` configures
   `ScreenUtilInit` and `MaterialApp.router`, titled AutoCare, with Material defaults.
2. `sessionProvider` starts in `AsyncLoading`. The router displays `BootstrapView`
   while secure storage reads `autocare.access_token`.
3. No token produces `Unauthenticated`. A saved token is validated with `GET /auth/me`.
   A valid response produces `Authenticated(user)`. HTTP 401 clears the token and
   returns to Login. Network, server, malformed-response, and storage failures become
   `AsyncError`; a potentially valid token is retained. Retry invalidates the session
   provider and repeats initialization. Riverpod automatic startup retries are disabled.
4. Login and registration receive an `AuthSession` from the repository, await secure
   token persistence, and then publish `Authenticated`. Failures propagate to the form.
   Global state stays unchanged during form submission, avoiding bootstrap redirects.
5. `currentUserProvider` derives the authenticated user from session state, returning
   null during initialization, on errors, or when unauthenticated.
6. Logout awaits token deletion before publishing `Unauthenticated`. Deletion failures
   leave the authenticated state intact and are shown on Profile.

The storage adapter uses Flutter Secure Storage platform defaults. Android backup
is disabled to avoid restoring encrypted data without its device key. iOS Keychain
entitlements are connected to Debug, Profile, and Release configurations.
Tokens and credentials are never logged or displayed. The interceptor attaches a
stored bearer token only to the configured backend origin and base path, strips
authorization from login/registration and external requests, and disables automatic
redirect following for protected requests. Startup supplies its token explicitly.

## Backend integration agreement

These are expected contracts, not verified claims about the separate backend.
Only the frontend repository is changed.

- `POST /auth/login`: request `{email, password}`.
- `POST /auth/register`: request `{name, email, password}`.
- Both return `{accessToken: string, user: {id: string, name: string, email: string}}`.
- `GET /auth/me`: bearer authorization; returns `{user: {id, name, email}}`.
- Required strings must be nonempty. Unexpected shapes produce a domain response
  error. HTTP 401 during login/registration means invalid credentials; during session
  restoration it means an invalid/expired session. Other HTTP/network errors produce
  safe messages without exposing raw request details.

There is no refresh-token or server-logout contract. Logout is local token deletion.
Future protected business API errors and token refresh are outside this foundation.
There is no production mock authentication or hardcoded successful response.

## Routes

All routes have centralized names and paths in `lib/routes/app_routes.dart`.
Dynamic path helpers encode identifiers; page constructors receive decoded parameters.

| Page | Name | Path |
| --- | --- | --- |
| Bootstrap | `bootstrap` | `/` |
| Login | `login` | `/login` |
| Register | `register` | `/register` |
| Home / service catalogue placeholder | `home` | `/home` |
| Service details | `serviceDetails` | `/services/:serviceId` |
| Booking | `booking` | `/services/:serviceId/book` |
| Booking confirmation | `bookingConfirmation` | `/bookings/:bookingId/confirmation` |
| My bookings | `myBookings` | `/bookings` |
| Booking details | `bookingDetails` | `/bookings/:bookingId` |
| Profile | `profile` | `/profile` |
| Edit profile | `editProfile` | `/profile/edit` |
| AI assistant | `assistant` | `/assistant` |
| Bootstrap error | `bootstrapError` | `/bootstrap-error` |
| Not found | `notFound` | `/not-found`, plus unknown-route fallback |

Initialization always shows Bootstrap. Initialization errors show Bootstrap Error.
Authenticated users can access application routes; authentication/bootstrap routes
redirect to Home. Unauthenticated users can access Login and Register; other routes
redirect to Login. After bootstrap or sign-in, navigation begins at Home; restoration
of an initially requested deep link is not implemented. Unknown routes display the
fallback once authenticated.

Home links to My Bookings, Profile, and AI Assistant. Login and Register link to each
other. Profile links to Edit Profile and logout. Service Details forwards its actual
service ID to the booking scaffold. No sample service or booking records are created.

## Final lib structure

```text
lib/
|-- main.dart
|-- app.dart
|-- core/
|   |-- navigation/presentation/not_found_page.dart
|   |-- network/
|   |   |-- api_endpoints.dart
|   |   |-- auth_interceptor.dart
|   |   `-- dio_provider.dart
|   `-- session/
|       |-- application/
|       |   |-- current_user_provider.dart
|       |   |-- session_controller.dart
|       |   |-- session_providers.dart
|       |   `-- token_storage_provider.dart
|       |-- data/
|       |   |-- auth_repository_impl.dart
|       |   |-- secure_token_storage.dart
|       |   `-- user_model.dart
|       |-- domain/
|       |   |-- auth_repository.dart
|       |   |-- auth_session.dart
|       |   |-- auth_state.dart
|       |   |-- session_exception.dart
|       |   |-- token_storage.dart
|       |   `-- user_entity.dart
|       `-- presentation/
|           |-- bootstrap_errorpage.dart
|           `-- bootstrap_view.dart
|-- features/
|   |-- assistant/presentation/pages/ai_assistant_page.dart
|   |-- auth/presentation/
|   |   |-- auth_form_helpers.dart
|   |   `-- pages/
|   |       |-- login_page.dart
|   |       `-- register_page.dart
|   |-- booking/presentation/pages/
|   |   |-- booking_confirmation_page.dart
|   |   `-- booking_page.dart
|   |-- bookings/presentation/pages/
|   |   |-- booking_details_page.dart
|   |   `-- my_bookings_page.dart
|   |-- home/presentation/pages/home_page.dart
|   |-- profile/presentation/pages/
|   |   |-- edit_profile_page.dart
|   |   `-- profile_page.dart
|   `-- services/presentation/pages/service_details_page.dart
`-- routes/
    |-- app_pages.dart
    |-- app_routes.dart
    `-- router_provider.dart
```

## Foundation file inventory

Created:

- `lib/app.dart`
- `lib/core/navigation/presentation/not_found_page.dart`
- `lib/core/network/api_endpoints.dart`
- `lib/core/network/auth_interceptor.dart`
- `lib/core/session/application/session_providers.dart`
- `lib/core/session/application/token_storage_provider.dart`
- `lib/core/session/data/secure_token_storage.dart`
- `lib/core/session/domain/auth_session.dart`
- `lib/core/session/domain/token_storage.dart`
- `lib/features/assistant/presentation/pages/ai_assistant_page.dart`
- `lib/features/auth/presentation/auth_form_helpers.dart`
- `lib/features/auth/presentation/pages/login_page.dart`
- `lib/features/auth/presentation/pages/register_page.dart`
- `lib/features/booking/presentation/pages/booking_confirmation_page.dart`
- `lib/features/booking/presentation/pages/booking_page.dart`
- `lib/features/bookings/presentation/pages/booking_details_page.dart`
- `lib/features/bookings/presentation/pages/my_bookings_page.dart`
- `lib/features/home/presentation/pages/home_page.dart`
- `lib/features/profile/presentation/pages/edit_profile_page.dart`
- `lib/features/profile/presentation/pages/profile_page.dart`
- `lib/features/services/presentation/pages/service_details_page.dart`
- `ios/Runner/Runner.entitlements`
- `test/network_auth_test.dart`
- `test/session_controller_test.dart`
- `test/support/session_fakes.dart`

Modified:

- `README.md`
- `android/app/src/debug/AndroidManifest.xml`
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`
- `ios/Runner.xcodeproj/project.pbxproj`
- `lib/main.dart`
- `lib/core/network/dio_provider.dart`
- `lib/core/session/application/current_user_provider.dart`
- `lib/core/session/application/session_controller.dart`
- `lib/core/session/data/auth_repository_impl.dart`
- `lib/core/session/data/user_model.dart`
- `lib/core/session/domain/auth_repository.dart`
- `lib/core/session/domain/session_exception.dart`
- `lib/core/session/domain/user_entity.dart`
- `lib/core/session/presentation/bootstrap_errorpage.dart`
- `lib/core/session/presentation/bootstrap_view.dart`
- `lib/routes/app_pages.dart`
- `lib/routes/app_routes.dart`
- `lib/routes/router_provider.dart`
- `test/widget_test.dart` (replaces the default counter test)

The existing sealed authentication states were reused without modification.

## Verification

```sh
flutter pub get
dart format .
flutter analyze
flutter test
flutter build apk --debug --no-pub
```

Tests use in-memory repositories/storage and a Dio HTTP adapter, never a live backend.
They cover token restoration, HTTP 401 clearing, retry after temporary startup errors,
secure-storage failures, persistence before authentication, logout, validated responses,
authentication request contracts, bearer isolation, form interactions, protected routes,
encoded route parameters, and unknown-route handling. The secure-storage adapter test
uses the plugin's in-memory platform mock; native device storage is not exercised by
unit/widget tests.

Validation results:

- `flutter pub get`: passed; dependency versions and lockfile unchanged.
- `dart format .`: passed before the native build. A later full-tree pass hit a
  Windows directory-listing error in Gradle's generated transform cache;
  `dart format lib test` then completed successfully for all 40 Dart source files.
- `flutter analyze`: passed, no issues found.
- `flutter test`: passed, all 18 tests, without an active backend.
- `flutter build apk --debug --no-pub`: passed and produced
  `build/app/outputs/flutter-apk/app-debug.apk`. Kotlin initially reported an
  incremental-cache error because the package cache and project are on different
  Windows drives; Gradle recovered and finished successfully.
- iOS compilation and native device storage were not tested on this Windows host.

No backend repository changes, commits, or pushes were made.

## Cookie refresh sessions

The adjacent backend currently has no auth implementation. These contracts are provisional:
login/register return `{accessToken, user}` and set a refresh cookie; POST `/auth/refresh`
returns `{accessToken}` and rotates that cookie; GET `/auth/me` returns `{user}`;
POST `/auth/logout` revokes the cookie session and returns 200/204. Refresh and logout
send no bearer or refresh-token body. Refresh rejection uses 401; optional protected
request code `ACCESS_TOKEN_EXPIRED` enables renewal (other explicit codes skip renewal).

The API client injects bearer tokens and retries replayable requests once after a 401.
Streams and multipart bodies are not replayed. A shared coordinator uses one pending
Future, reuses newer saved tokens for late failures, and never retries refresh itself.
Logout invalidates renewal, waits for pending auth, revokes remotely, and clears local
credentials. Network failures preserve credentials and surface the bootstrap retry UI.
Successful background renewal does not change application loading/navigation state.

Native clients share a PersistCookieJar whose storage adapter uses Flutter Secure
Storage, namespaced by backend URL. Cookie expiration, path, domain and Secure flags
are handled by cookie_jar. Only trusted backend paths load or save cookies. Web uses
browser-managed HttpOnly cookies and credentialed requests; it cannot delete these
cookies locally if server logout fails. No refresh token is exposed in domain state.

Production requires HTTPS, HttpOnly and Secure cookies, an appropriate SameSite policy,
and a narrow cookie path covering refresh/logout. Prefer host-only cookies. Cross-site
web deployments require SameSite=None; Secure, exact allowed CORS origins (never `*`),
Access-Control-Allow-Credentials: true, and OPTIONS support for Content-Type and
Authorization. Enforce CSRF protection on cookie-authenticated mutations (Origin checks
and SameSite, or integrate the backend's CSRF token/header contract before deployment).
Browser cookie blocking policies can prevent cross-site session persistence.

The emulator HTTP default cannot send Secure cookies. Prefer local HTTPS with a trusted
development certificate and API_BASE_URL override. If an HTTP-only local backend is
used, its non-Secure cookie exception must be confined to its development configuration;
the frontend does not weaken Secure handling or certificate validation.

Refresh reuse detection and revocation belong to the backend. An ambiguous refresh
network failure is surfaced without automatic retry because rotation may have happened.
Single-flight coordination is per provider container; multiple browser tabs or independent
app processes require backend concurrency tolerance or additional cross-context locking.
