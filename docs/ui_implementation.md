# AutoCare presentation and architecture

The existing visual design is preserved. Customer and admin screens retain their
responsive mobile/desktop layouts, typography, spacing, navigation history, forms,
loading/error/empty states, and image fallbacks.

The [architecture cleanup report](architecture_cleanup_report.md) is the current
source and verification reference. The [earlier integration report](final_integration_report.md)
records historical hosted acceptance.

## Ownership

- `app/shell` owns customer navigation and secondary page composition.
- `app/widgets` owns branding, startup presentation, automotive artwork and the
  explicit demo notice.
- `core/widgets` contains generic layout, controls, state messages and resume handling.
- `features/catalog` owns service/package data and reusable catalog presentation.
- `features/appointments` owns appointment records, history/detail state and mutations.
- `features/workshop` owns server configuration, availability models and Dhaka calendar rules.
- `features/booking` owns scheduling/review/create; `features/bookings` owns the
  customer listing and management presentation.
- Admin categories, services/packages, offers, appointments, payments and media
  each own their resource controllers, payloads, models and transport.
- `demo` owns fixture behavior and explicit dependency overrides. Production
  service failures cannot select it.

Views construct typed input, invoke controllers, display safe messages and handle
navigation/dialogs. Controllers own mutation state, duplicate-submission guards,
ownership checks and cache invalidation. Services own HTTP and decoding; models
own payload serialization and pure validation. Local editing controllers, focus,
scroll position, password visibility and dialog state remain in widgets.

The catalog snapshot renders cached details immediately. Missing direct-link data
uses the documented detail endpoint. Assistant actions are validated against the
catalog and category browsing uses one route intent, including repeated clicks.
Private route instances and operation guards isolate account changes. A successful
checkout redirect never establishes payment success.

## Offline demo

```sh
flutter run -t lib/demo/main_demo.dart
flutter build web --release -t lib/demo/main_demo.dart --output build/demo_web
```

Any valid email and nonempty password work in this explicit target. Authentication
and business data stay in memory; online payment initiation is disabled. Normal
`main.dart` uses real authentication. An explicit `DEMO_DATA=true` selects business
fixture adapters only and does not replace authentication.

## Verification

The normal suite covers controller flows, account changes, navigation persistence,
resizing, keyboard layouts and text scaling. Opt-in screenshot tests remain available.
Release compilation and mocked browser transport tests are separate from deployed
browser cookies, physical-device behavior and provider sandbox acceptance.
See the current report for actual results and remaining operator checks.
