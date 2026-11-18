# AutoCare — Flutter application

AutoCare is a responsive vehicle service booking and management application. Customers can explore services and packages, reserve workshop appointments, manage bookings, pay through a hosted sandbox checkout and receive catalog-grounded AI assistance. Administrators can manage the catalog, offers, appointments, images and payment records.

**Assessment:** Service Booking & Management App | FB International

## Quick start

Install Flutter 3.41.9 (Dart 3.11.5), configure Android SDK or Chrome, and run:

```sh
flutter pub get
flutter run
```

Normal builds connect to `https://fb-international-assessment-project.onrender.com/api/v1`. No provider secrets are required on the client. The hosted backend may take time to wake from a cold start.

## Technology

Flutter, Dart, Riverpod 3, Dio, GoRouter, secure storage, cookie transport, image_picker and url_launcher. The backend uses NestJS, PostgreSQL, Prisma, Gemini, Cloudinary and SSLCommerz.

## Admin panel

**The main purpose of the admin panel is to provide a simple way to add services and service categories** to the customer-facing catalog. Additional management features are described in the [admin experience](docs/FEATURES.md#admin-experience).

Use the application's login screen with the following live platform admin credentials:

| Field | Value |
|---|---|
| Email | `sadimahmud225@gmail.com` |
| Password | `qwerty4321` |

## Documentation

- [Code architecture](docs/ARCHITECTURE.md)
- [Implemented features](docs/FEATURES.md)
- [Setup, environment and builds](docs/SETUP.md)
- [Backend source, API and database documentation](https://github.com/kugelblitz84/Fb_international_assessment_project_backend)

## Screenshots and release

<!-- Before submission: add actual screenshots from the final app and public APK/demo links here. -->

## Verification

```sh
flutter pub get
dart run scripts/check_architecture.dart
flutter analyze
flutter test
```

See the setup guide for release builds and manual acceptance checks. Automated tests and demo fixtures are not substitutes for live-device verification.
