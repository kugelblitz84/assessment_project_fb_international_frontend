# AutoCare final integration report

Historical integration snapshot from before the architectural cleanup. Source paths,
readiness infrastructure and automated counts below describe that earlier revision.
Use [architecture cleanup report](architecture_cleanup_report.md) for the current
architecture and verification; the hosted acceptance evidence here remains historical.

Date: **2026-11-17**, Asia/Dhaka. Production API:
`https://fb-international-assessment-project.onrender.com/api/v1`.

## Implementation

Audited the clean frontend at `7216ed9` and the adjacent backend payment revision
`177c0bf`, including implemented controllers/services and all eight requested backend
documents. Current GitHub documentation was also retrieved through the connector.
Existing catalog, booking, auth, profile, admin image and assistant features were
preserved. No backend source or database configuration was changed.

- Production API is now the default, with explicit `API_BASE_URL` overrides and
  offline demo retained. Live failures never activate demo fixtures.
- Both existing authenticated transports share one demand-driven health readiness
  coordinator, bounded to 90 seconds. A connecting/failure banner provides Retry.
  Successful readiness is cached for five minutes, with no permanent keep-alive.
  Ordinary requests use 30-second limits; AI/payment/upload response waiting allows
  75 seconds and large sends 60 seconds. There are no connection-failure retries
  of mutations; read retry is explicit through UI actions.
- Authentication refresh coordination, secure cookie storage, CSRF, trusted origin
  validation and generation checks remain. A final transport generation check
  prevents a mutation queued during startup from executing under another session.
- Typed platform service/provider parses booking configuration, settings and hours.
  Production date selection uses the backend horizon and Asia/Dhaka, with today
  included and the final date at today+horizon-1. Configuration older than five
  minutes must reload; errors block booking instead of selecting a default horizon.
  Existing persisted slot IDs, availability refresh and booking conflicts remain.
- Shared/customer and admin appointments parse independent payment summaries,
  nullable payment method, `canPayOnline` and `canCancel`. Snapshot prices/names/
  durations remain intact; paid never means automatically confirmed.
- Customer payment models/service/controller/UI cover capabilities, exact contact
  payload/validation, initiation, history/detail transport and reconciliation.
  Saved bookings offer workshop payment independently from online checkout.
  External checkout validates exact sandbox/live gateway HTTPS hosts, port and
  absence of URL credentials. No app auth headers or payment secrets reach checkout.
- Ambiguous initiation loads existing history and reconciles unresolved attempts.
  Another initiation requires fresh backend eligibility and no unresolved/applied
  attempt. Session identities isolate results. Resume/visibility and manual refresh
  synchronize payment and appointment state; a shared gate prevents simultaneous
  reconciliation and enforces five seconds after completion before another call.
  No polling, card collection, refund or manual approval override was added.
- Admin Payments reuses the existing shell, repository, role guard and owner-keyed
  providers. It supports status filtering, details, references/incidents, last
  reconciliation and guarded manual reconciliation. Optional date filtering was
  not added. Admin DTOs omit checkout URLs.
- All twelve documented payment error codes map to safe local messages, separately
  from booking conflicts and generic server failures. Upload contracts, unchanged
  absolute image URLs, replacement preservation and structured AI actions remain.
- Render Blueprint, pinned SDK Bash build and hosted acceptance script were added.
  Android Gradle memory/workers were reduced after an initial daemon crash.

## API coverage

| API group | Frontend coverage | Hosted evidence |
| --- | --- | --- |
| GET health/status | Coordinated cold-start readiness/banner/retry | 200 production health |
| GET platform | Typed configuration and dynamic booking dates | 200; 30 days, 15 minutes, Asia/Dhaka |
| Auth register/login/me/csrf/refresh/logout | Existing secured session transport preserved | Native HTTP register/login/identity/rotation/logout passed |
| GET services, service detail, search/filters/offers | Existing catalog/package integration preserved | Nine items, three packages, two offers; search/category/type/detail passed |
| GET services/:id/availability | Existing persisted-slot booking adapter | Future slots returned |
| POST/GET appointments, detail, PATCH cancel | Existing booking/history/cancellation preserved | One future booking created, read and cancelled |
| PATCH users/me | Existing profile adapter retained | Mock regression coverage; no hosted profile edit |
| GET payments/config | Typed public capabilities | 200; online disabled, workshop enabled |
| POST appointments/:id/pay | Exact contact-only payload, eligibility preflight, uncertainty recovery | Blocked by disabled gateway; mocked |
| GET appointments/:id/payments | Typed owned history and recovery | Empty history for test appointment |
| GET payments/:id | Typed detail transport | Mock transport implementation; no real attempt available |
| POST payments/:id/reconcile | Serialized/throttled status verification and state sync | Mocked; no configured sandbox attempt |
| GET admin/payments and :id | Owner/role guarded list/filter/detail | Missing bearer 401; customer 403; authorized admin acceptance pending |
| POST admin/payments/:id/reconcile | Protected manual reconciliation | Mocked/implemented; admin credentials unavailable |
| POST admin/media/images | Existing authenticated multipart, file, 2 MiB and returned URL | Mocked compatibility; live upload pending ADMIN/provider prerequisites |
| POST assistant/chat | Structured catalog actions/privacy/session isolation preserved | One guest recommendation succeeded with valid live IDs |

## Actual automated results

| Check | Result |
| --- | --- |
| `dart format lib test` | Passed; 174 Dart files formatted |
| `flutter analyze` | Passed; no issues |
| `flutter test` | **180 passed**, zero failures; four existing opt-in screenshot tests skipped |
| `flutter build web --release --dart-define=API_BASE_URL=...` | Passed; `build/web` |
| `flutter build apk --release --dart-define=API_BASE_URL=...` | Passed after Gradle resource adjustment; final artifact below |
| Git Bash `-n scripts/render-build.sh` | Passed syntax check |
| `flutter pub get --enforce-lockfile` | Passed; lockfile unchanged |
| `git diff --check` | Passed |

The eighteen new tests cover platform parsing/ranges, readiness sharing/failure/
manual recovery, session changes during warm-up, payment capabilities/disabled
gateway, independent appointment summaries, attempt statuses, trimmed exact contact
payloads, trusted checkout URLs, reconciliation concurrency/spacing, initiation,
ambiguous recovery without duplicate charges, payment/appointment synchronization,
late-result isolation, admin authorization/filtering/DTOs, safe error mapping, and
payment layouts at 390/1440 pixels. Existing auth, booking, admin, assistant,
navigation, privacy and responsive regression tests remain; none were deleted.
Provider responses are mocked in automated tests.

The initial Android build failed because its Gradle daemon disappeared. After
reducing heap/metaspace/workers, release compilation succeeded. Web compilation's
Wasm compatibility dry run also succeeded; the ordinary JavaScript release is the
deployment artifact. Logs under ignored `build/` record the executed commands.
No clean Linux Render build, actual publication, browser session acceptance or
physical-device payment test is claimed.

## Hosted acceptance

The public API, platform/catalog/search/packages/offers/detail/availability and one
guest Gemini request passed. One dedicated customer account exercised registration,
login, auth identity, CSRF acquisition, refresh-cookie rotation, future booking,
detail/history/payment history, cancellation and logout. Missing-auth requests were
denied with 401; the customer was denied admin payments with 403.

The sole test appointment `7af099f0-84cb-4131-8dc5-8945788dadaf` was cancelled through
the supported endpoint. One labeled account remains because no delete API exists;
its random credentials were never saved or printed. No capacity flooding, provider
checkout, upload, real-money transaction, local backend or local database ran.
See [hosted checklist](live_testing_checklist.md) for exact results/procedures.

## Remaining operator actions

1. Deploy the static frontend using the exact settings in [deployment.md](deployment.md).
   No remote push or deployment was authorized/performed. Add the assigned exact
   HTTPS origin to backend CORS and verify real browser cookie/CSRF/reload behavior.
   If third-party cookie policy blocks refresh, use same-site custom domains or a
   secure same-origin API reverse proxy. Do not weaken security.
2. Configure backend SSLCOMMERZ **sandbox** credentials/callback base/IPN, then run
   manual gateway success/failure/cancel/uncertainty/reconciliation acceptance.
   Current capabilities advertise online disabled; workshop booking works.
3. Provision an explicit test ADMIN and verify dashboard/catalog/offers/images,
   appointments and payment management with labeled test records. Live Cloudinary
   verification requires backend provider configuration and this administrator.
4. Install the APK on Android and verify secure persistence, external checkout and
   resume behavior. Complete authenticated AI/card navigation/price acceptance and
   controlled capacity checks using the prepared procedures.
5. Before store distribution, select final application branding/package and private
   release signing. The existing assessment ID/icon/debug-key signing remain.

## Exact deployment/build handover

Render: **Static Site**, branch **master**, root **repository root**, build command
**`bash scripts/render-build.sh`**, publish **`build/web`**, auto deployment **on commit**,
`API_BASE_URL=https://fb-international-assessment-project.onrender.com/api/v1`, SPA
rewrite **`/*` to `/index.html`**. No backend/provider secrets in frontend variables.

```sh
flutter build apk --release --dart-define=API_BASE_URL=https://fb-international-assessment-project.onrender.com/api/v1
```

APK: `build/app/outputs/flutter-apk/app-release.apk` (approximately 53.7 MB).
Final APK size: 56,317,446 bytes. SHA-256:
`e7349da8fbe5c58ec65718d2525dddb23662428c2a4e17e9da000af67151645c`.

**Verdict:** implementation and automated/release compilation are ready for
assessment handover against the hosted backend. Full deployment acceptance remains
conditional on the explicitly pending browser, administrator, provider sandbox and
physical-device checks above. Production store distribution is not signed off.

## Changed-file inventory

The inventory below includes all files changed by this task (including this report).

- `.gitattributes`
- `.gitignore`
- `android/gradle.properties`
- `docs/admin_implementation.md`
- `docs/deployment.md`
- `docs/final_integration_report.md`
- `docs/live_testing_checklist.md`
- `lib/app.dart`
- `lib/core/config/platform_config.dart`
- `lib/core/network/api_endpoints.dart`
- `lib/core/network/api_error_handler.dart`
- `lib/core/network/backend_readiness.dart`
- `lib/core/network/dio_provider.dart`
- `lib/core/network/readiness_banner.dart`
- `lib/core/utils/workshop_calendar.dart`
- `lib/features/admin/appointments/view/admin_appointment_details.dart`
- `lib/features/admin/appointments/view/admin_appointments_page.dart`
- `lib/features/admin/payments/view/admin_payments_page.dart`
- `lib/features/admin/shared/controller/admin_providers.dart`
- `lib/features/admin/shared/model/admin_models.dart`
- `lib/features/admin/shared/service/admin_repository.dart`
- `lib/features/admin/shared/view/admin_shell.dart`
- `lib/features/booking/controller/booking_controller.dart`
- `lib/features/booking/view/booking_confirmation_page.dart`
- `lib/features/booking/view/booking_page.dart`
- `lib/features/bookings/view/booking_details_page.dart`
- `lib/features/bookings/view/widgets/booking_card.dart`
- `lib/features/payments/controller/payment_controller.dart`
- `lib/features/payments/model/payment_models.dart`
- `lib/features/payments/service/payment_service.dart`
- `lib/features/payments/view/payment_actions.dart`
- `lib/features/payments/view/payment_page.dart`
- `lib/features/shared/model/appointment_model.dart`
- `lib/features/shared/model/payment_summary.dart`
- `lib/features/shared/service/demo_workshop.dart`
- `lib/features/shared/view/appointment_info.dart`
- `lib/routes/app_pages.dart`
- `lib/routes/app_routes.dart`
- `lib/routes/route_access_policy.dart`
- `linux/flutter/generated_plugin_registrant.cc`
- `linux/flutter/generated_plugins.cmake`
- `macos/Flutter/GeneratedPluginRegistrant.swift`
- `pubspec.lock`
- `pubspec.yaml`
- `README.md`
- `render.yaml`
- `scripts/hosted_acceptance.py`
- `scripts/render-build.sh`
- `test/live_booking_integration_test.dart`
- `test/network_auth_test.dart`
- `test/payment_integration_test.dart`
- `test/refresh_integration_test.dart`
- `test/support/admin_fakes.dart`
- `test/support/demo_container.dart`
- `windows/flutter/generated_plugin_registrant.cc`
- `windows/flutter/generated_plugins.cmake`
