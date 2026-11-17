# AutoCare

Responsive Flutter customer/admin application using Riverpod 3, Dio, GoRouter and
feature-first model/view/controller/service modules. Android is the primary
assessment platform. The normal entry point defaults to the deployed backend:

```text
https://fb-international-assessment-project.onrender.com/api/v1
```

Use Flutter **3.41.9 / Dart 3.11.5**, pinned in the Render build script. No local
backend, PostgreSQL instance or provider secrets are needed by evaluators.

```sh
flutter pub get
flutter run
# Optional explicit override, including /api/v1 exactly once:
flutter run --dart-define=API_BASE_URL=https://fb-international-assessment-project.onrender.com/api/v1
```

The free backend can need up to 90 seconds to start. A shared readiness check,
connecting banner and manual Retry cover startup. Ordinary requests have 30-second
timeouts; AI/payment/upload responses allow 75 seconds and large sends 60 seconds.
Connection failures never automatically replay mutations or activate demo data.

## Explicit offline demo

```sh
flutter run -t lib/demo/main_demo.dart
```

Use any valid email and nonempty password. The demo overrides existing session
dependencies with memory-only fixtures; restart resets changes. It does not wait
for backend readiness or enable online payments. DEMO_DATA=true selects sample
business data only; use the explicit target for fully offline authentication.
Do not deploy demo options for assessment.

## Architecture and booking

The existing trusted-backend transport, secure token storage, persistent native
cookies, credentialed browser cookies, CSRF and coordinated refresh remain.
GoRouter owns navigation. Private controllers/routes isolate session identities,
discard late results and enforce administrator access. Feature controllers reuse
central safe error mapping; there is no second authentication or payment store.

Customer flows include catalog search/filtering, discounts, service/package detail,
backend availability, booking review/create/acknowledgement, history/cancellation,
profile editing and structured Gemini recommendations. Appointment names, prices
and durations remain stored snapshots. Payment status and booking status are separate.

GET /platform supplies the booking horizon and Asia/Dhaka timezone. The picker
includes today through today plus horizon minus one, independently of device time.
Configuration expires after five minutes and requires refresh; invalid/unavailable
configuration has no production fallback. Availability uses returned slot UUIDs,
with no locally generated production slots. Conflicts reload availability; uncertain
creation asks users to check My Bookings before another request.

## Hosted payments

Book first. Confirmation/details link to payment options/history; booking cards
show payment status. Pay Online collects only phone, address, city and postcode.
The backend controls amount, currency, user and transaction details. Pay at Workshop
keeps the saved booking without creating a successful online payment record.

The backend-returned checkout URL opens externally through url_launcher after
HTTPS, exact sandbox/live hostname, credentials and port validation. AutoCare never
collects card numbers, CVVs, PINs or OTPs, or sends its auth headers to checkout.
Browser popup restrictions may require pressing Resume Checkout after initiation.

The payment route refreshes on app resume/browser visibility return and supplies
Refresh Payment Status. Reconciliation is serialized with five-second minimum
spacing, including remounts. There is no background polling. Ambiguous initiation
loads history and reconciles an existing attempt before another charge. Only
verified API responses establish applied payment; redirects never establish success.
Manual review directs users to support. Refunds/approval overrides are out of scope.

The admin shell includes payment list/status filtering, details, customer/service,
amount, merchant/bank/validation references, incidents, reconciliation time and
manual reconciliation. Admin DTOs omit checkout URLs. Customers cannot access
admin payment routes/providers.

The deployed gateway currently advertises onlinePaymentEnabled=false and
payAtWorkshopEnabled=true. Booking works; hosted sandbox completion is blocked
until the owner configures the backend gateway.

## Images and assistant

Admin uploads use authenticated POST /admin/media/images, multipart field file,
JPEG/PNG/WebP and a 2 MiB limit. Returned absolute Cloudinary/legacy/external URLs
are preserved. Replacement failures retain previous images and preview/fallback
behavior. No direct Cloudinary upload or credentials exist in Flutter.

Gemini retains catalog-backed UUID cards, service/package navigation and category
browse actions. Arbitrary generated URLs/HTML never become executable actions.
Session isolation, generation checks, privacy notice, manual retry and safe
quota/disabled/timeout handling remain. One hosted guest recommendation succeeded;
other live-provider/UI scenarios remain on the acceptance checklist.

## Build and deployment

```sh
dart format lib test
flutter analyze
flutter test
flutter build web --release --dart-define=API_BASE_URL=https://fb-international-assessment-project.onrender.com/api/v1
flutter build apk --release --dart-define=API_BASE_URL=https://fb-international-assessment-project.onrender.com/api/v1
```

Render Static Site: branch master, repository root, build command
`bash scripts/render-build.sh`, publish directory `build/web`, auto deployment on
commit. Set API_BASE_URL to the deployed API above (also the script default).
The script retrieves pinned Flutter, checks its commit, installs locked dependencies
and builds release output. render.yaml includes the SPA rewrite /* to /index.html;
existing hash URLs also work. No remote push/deployment was performed.

Add the assigned frontend's exact HTTPS origin to backend CORS_ORIGINS. Preserve
secure HttpOnly cookies, SameSite=None and CSRF. Separate Render hosts may encounter
third-party cookie restrictions; browser reload persistence is not yet verified.
If blocked, use HTTPS custom domains under one registrable domain or a same-origin
reverse proxy routing /api/v1 to the backend. Never weaken CORS/CSRF/cookie security
or expose refresh tokens to JavaScript.

Android release includes INTERNET, HTTPS production traffic and disabled backups.
The existing assessment application ID/icon and debug-key release signing remain;
configure a private release keystore and final identity before public distribution.
No signing secrets were added.

## Verification and handover

- [Final integration report](docs/final_integration_report.md): actual results, API coverage and changed files.
- [Deployment instructions](docs/deployment.md): exact Render/Android settings and browser considerations.
- [Hosted checklist](docs/live_testing_checklist.md): executed checks, blockers and operator actions.

```sh
# Read-only hosted checks:
python scripts/hosted_acceptance.py
# Explicit controlled acceptance: ONE account/booking and ONE assistant call:
python scripts/hosted_acceptance.py --mutations --assistant
```

Credentials remain in memory and are never printed. The eligible test booking is
cancelled; a labeled account remains because no deletion endpoint exists. These
HTTP checks do not claim browser/physical-device UI acceptance. No local backend,
local database, destructive suite or real-money payment is used.

Existing [UI notes](docs/ui_implementation.md) and [admin notes](docs/admin_implementation.md)
describe earlier work; the final report is authoritative for current readiness.
