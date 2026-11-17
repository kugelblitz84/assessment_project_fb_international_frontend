# Admin implementation report

Historical implementation notes. Current payment integration, hosted results and
deployment readiness are recorded in [final integration report](final_integration_report.md).

The existing Flutter app now has an independent administration shell at `/admin`,
using its existing login, session controller, token storage, refresh coordinator,
GoRouter and theme. Customer navigation remains in its existing shell.

## Contract inspected

The adjacent backend's `docs/api.md`, actual controllers, Zod schemas, Prisma models,
DTO methods and administrator CLI were inspected before implementation.
`docs/admin-api.md` was absent in that checkout. The public API documentation omits
roles and administration and describes older profile responses, so actual backend
source was authoritative: `src/features/admin/domain/admin.schemas.ts`,
`src/features/admin/http/`, `src/features/admin/application/`,
`src/features/media/`, `src/features/auth/data/user.repository.ts`,
`prisma/models/appointment.prisma` and `scripts/create-admin.ts`.

| Integration | Backend contract used |
| --- | --- |
| Authentication and profile | Backend user `role` is exactly `ADMIN` or `CUSTOMER`; unknown/missing values default to customer. Existing `/auth/login`, `/auth/me`, `/auth/logout`; profile `PATCH /users/me` returns `{user: ...}`. |
| Dashboard | `GET /admin/dashboard`; eight backend count fields, no fabricated metrics. Services count includes packages, following the backend. |
| Categories | `GET/POST /admin/categories`, `GET/PATCH /admin/categories/:id`; active status, slug, image URL, description and sort order. |
| Services and packages | `GET/POST /admin/services`, `GET/PATCH /admin/services/:id`. Admin price is stored base price. Packages use `type: PACKAGE` and `packageItems: [{serviceId, quantity}]`. No package endpoints are invented. |
| Media | `POST /admin/media/images`; multipart `file`, maximum 2 × 1024 × 1024 bytes; JPEG/PNG/WebP. Returns absolute `imageUrl`; backend checks signatures. |
| Offers | `GET/POST /admin/offers`, `GET/PATCH /admin/offers/:id`; `PERCENTAGE` or `FIXED_AMOUNT`, positive decimal value, UTC ISO timestamps. Backend owns effective pricing. |
| Appointments | `GET /admin/appointments?status=...&date=YYYY-MM-DD`, `GET /admin/appointments/:id`, `PATCH /admin/appointments/:id/status`. Admin DTO has direct timestamps and nested user/vehicle, unlike the public DTO's nested slot. |

The frontend does not change backend files or introduce a second client or auth
system. It reuses public ServiceModel and BookingStatus, with typed administrative
metadata where the public DTO omits fields. Features follow this repository's
model/view/controller/service convention rather than introducing another structure.

## Screens and behavior

- Dashboard with eight live counts and five quick actions.
- Categories: list, create, edit, activation/deactivation and image upload.
- Services: list, search, category/status filters, create and edit; dynamic inclusions,
  live category UUIDs, BDT price, duration, sort order, featured and active flags.
- Packages: the same service form and adapter, with unique individual service UUIDs,
  quantities 1–1,000 and an explicit package price. Packages cannot contain packages.
- Offers: list, create and edit, enable/disable, active/scheduled/expired/disabled
  states, discount validation and Asia/Dhaka date entry with UTC serialization.
- Appointments: server status/date filters, customer/service/price rows, details,
  confirmed/cancelled transitions from pending and completed/cancelled transitions
  from confirmed. Completion is available only at/after the end time. Terminal
  appointments have no mutation actions. Confirmations precede mutations; conflicts
  refresh the detail, list, public appointments, availability and dashboard.
- Responsive sidebar/drawer navigation, administrator identity and existing logout.

All requested create/edit/detail URLs are registered. Direct admin links require
authentication and administrator role. Safe return destinations remain validated.
Role changes notify the stable GoRouter. New account/session/authorization identities
get separate auto-disposed query instances so old responses cannot appear in a new
account. In-flight mutation results are discarded after ownership changes.

Image fields use a provider scoped to the particular form. Selected bytes preview
locally, then upload through authenticated Dio; only the returned URL enters JSON.
Previous images survive failures. Saving is disabled during uploads and mutations.
Multipart is never automatically replayed; an expired upload session can renew
through the existing coordinator before an explicit retry with new FormData.
The shared API handler supports HTTP 400/401/403/404/409/413 and network/server errors.

## Changed files

| Area | Files |
| --- | --- |
| Roles/session data | `lib/core/session/domain/user_entity.dart`, `lib/core/session/data/user_model.dart` |
| Network and profile | `lib/core/network/api_endpoints.dart`, `api_error_handler.dart`, `lib/features/profile/service/profile_service.dart` |
| Routing | `lib/routes/app_routes.dart`, `app_pages.dart`, `route_access_policy.dart`, `router_provider.dart` |
| Shared admin state and UI | `lib/features/admin/shared/model/admin_models.dart`, `admin_validation.dart`; `shared/service/admin_repository.dart`; `shared/controller/admin_providers.dart`; `shared/view/admin_shell.dart`, `admin_widgets.dart` |
| Dashboard and catalog | `admin/dashboard/view/admin_dashboard_page.dart`; `admin/categories/view/admin_categories_page.dart`, `admin_category_form.dart`; `admin/services/view/admin_services_page.dart`, `admin_service_form.dart` |
| Media | `admin/media/controller/admin_image_controller.dart`, `admin/media/view/admin_image_field.dart` |
| Offers and appointments | `admin/offers/view/admin_offers_page.dart`, `admin_offer_form.dart`; `admin/appointments/view/admin_appointments_page.dart`, `admin_appointment_details.dart` |
| Dependency wiring | `pubspec.yaml`, `pubspec.lock`; generated image-picker plugin registrants for desktop platforms |
| Tests | `test/admin_panel_test.dart`, `test/support/admin_fakes.dart`, `test/admin_screenshots_test.dart` |
| Documentation | `README.md`, this report |

## Verification

Final results (17 November 2026):

| Check | Result |
| --- | --- |
| `dart format .` | Attempted; Windows directory traversal fails inside generated Android `build/.../.transforms/...` paths. |
| `dart format lib test` and no-change format check | Passed, all 161 Dart source/test files formatted. |
| `flutter analyze` | Passed, no issues. |
| `flutter test` | Passed: 149 tests, including 24 admin tests; four opt-in screenshot tests skipped. |
| Admin screenshot tests with capture enabled | Passed separately, two viewport tests; ten screenshots generated. Desktop dashboard and mobile service form visually inspected. |
| `flutter build apk --debug` | Passed; `build/app/outputs/flutter-apk/app-debug.apk`. |
| `flutter build web` | Passed, including Wasm compatibility dry run; `build/web/`. |
| Live API | Not verified: local backend health endpoint unreachable. |

Admin tests exercise exact role deserialization, role-preserving copies, restoration,
login return paths, unauthorized direct access, role demotion and logout; validation
ranges; package payloads and explicit pricing; byte/multipart/MIME construction and
size limits; failed-upload preservation and explicit retry; offer periods and time
conversion; appointment action boundaries and 409 reloads; mutation invalidation,
duplicate submissions and session isolation; safe 403 handling without refresh loops.
Every admin screen is exercised at widths 320, 768 and 1280, including doubled text
at 320/1280, plus form draft preservation across resizing.

Opt-in screenshots use transport fixtures, with legible review fonts:

```sh
flutter test test/admin_screenshots_test.dart --dart-define=CAPTURE_ADMIN_UI=true --dart-define=SCREENSHOT_FONT=C:/Windows/Fonts/segoeui.ttf
```

Artifacts are under `build/admin_screenshots/` (mobile and desktop). These screenshots
and mocked transport tests are not evidence of live API integration.

## Remaining limits and deployment checks

- The deployed backend is available. Live administrator CRUD/upload and native
  picker acceptance still require a dedicated provisioned test administrator;
  see the [hosted checklist](live_testing_checklist.md).
- Backend `PUBLIC_API_BASE_URL` must be reachable from the target client; CORS and
  secure browser cookies must be configured for the deployed frontend origin.
- Lists are intentionally unpaginated, following the backend. Service search and
  category/status filtering are local. Offer dates use validated text input in
  `YYYY-MM-DD HH:mm` format. Workshop timezone is the backend's fixed Asia/Dhaka.
- Customer booking HTTP integration and admin payments are now implemented;
  current verification is recorded in the final report linked above.
- No administrator registration, user management, refunds, rescheduling,
  notifications, analytics charts or unrelated customer redesign was added.
