# Flutter setup and deployment

## Prerequisites

- Git, Flutter 3.41.9 (Dart 3.11.5), Android SDK/JDK configured for Flutter; Chrome for web.
- Run `flutter doctor -v` and resolve Android toolchain issues.
- Use the hosted backend or follow the [backend setup](https://github.com/kugelblitz84/Fb_international_assessment_project_backend/blob/master/docs/SETUP.md).

```sh
git clone https://github.com/kugelblitz84/assessment_project_fb_international_frontend.git
cd assessment_project_fb_international_frontend
flutter pub get
flutter devices
flutter run
```

Default API: `https://fb-international-assessment-project.onrender.com/api/v1`.

## Compile-time configuration

| Define | Default | Meaning |
|---|---|---|
| `API_BASE_URL` | Hosted API above | Absolute HTTP(S) URL including `/api/v1` once; HTTPS for production. |
| `DEMO_DATA` | false | Explicit fixture data override; does not itself replace real authentication. |
| `CAPTURE_UI` | false | Opt-in screenshot test flag. |
| `SCREENSHOT_FONT` | unset | Optional local font path for screenshot tests. |

Use `--dart-define=NAME=value`. These are compile-time public values, not secrets. Never pass JWT signing secrets, database credentials, Gemini keys, merchant credentials or Cloudinary secrets to Flutter. The Render build script also accepts the shell environment variable `API_BASE_URL` and optional `RENDER_FLUTTER_CACHE` for its SDK cache.

## Run against local backend

Start the backend on port 3000 first. For Android Studio emulator use host alias `10.0.2.2`:

```sh
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
flutter run -d chrome --web-port=5173 --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

For a physical Android device, use USB `adb reverse tcp:3000 tcp:3000` and `http://127.0.0.1:3000/api/v1`, or the computer's LAN IP with firewall/network configured. Android cleartext restrictions can block HTTP; use an HTTPS development endpoint or a debug-only network configuration if needed. Do not weaken release transport security. For web, add exactly `http://localhost:5173` to local backend `CORS_ORIGINS`; development cookies use `AUTH_COOKIE_SECURE=false` and `AUTH_COOKIE_SAME_SITE=lax` on localhost. Native clients do not require a CORS origin.

Offline UI demo (not production):

```sh
flutter run -t lib/demo/main_demo.dart
```

## Validation and release

```sh
dart format lib test scripts/check_architecture.dart
dart run scripts/check_architecture.dart
flutter analyze
flutter test
flutter build apk --release --dart-define=API_BASE_URL=https://fb-international-assessment-project.onrender.com/api/v1
flutter build web --release --dart-define=API_BASE_URL=https://fb-international-assessment-project.onrender.com/api/v1
```

APK: `build/app/outputs/flutter-apk/app-release.apk`. Web: `build/web/`. Install the release APK on a physical device (`adb install -r build/app/outputs/flutter-apk/app-release.apk`) and retest registration/login, restart persistence, service discovery, booking/cancel, profile, AI and checkout/resume. Existing assessment signing uses the debug key; configure a protected release key and final app identity for store distribution. Do not publish private keystores.

Optional fixture-based UI screenshots:

```sh
flutter test test/ui_screenshots_test.dart --dart-define=CAPTURE_UI=true
```

Output: `build/ui_screenshots/`. Prefer live final-app screenshots for the submission; label fixture images honestly.

## Render static site

Use `master`, root repository directory, build `bash scripts/render-build.sh`, publish `build/web`. The script fetches the pinned Flutter SDK and enforces the dependency lockfile. `render.yaml` configures a static site and SPA rewrite. Set the API base if deploying to a different backend. Add the actual frontend HTTPS origin to backend `CORS_ORIGINS`, with no path/trailing slash. Keep secure HttpOnly cookies, SameSite=None for cross-site browser sessions, and CSRF checks. Some browsers block third-party cookies; if reload fails, investigate cookie policy and consider same-site custom domains or a same-origin API proxy rather than disabling security. The SPA rewrite alone does not proxy API requests.

## Hosted acceptance

```sh
python scripts/hosted_acceptance.py
# Controlled opt-in: creates one test account/booking and sends one AI request
python scripts/hosted_acceptance.py --mutations --assistant
```

The mutation run leaves a labeled account (no account deletion API); avoid repeated runs. Use sandbox payments only. Verify provider configuration, browser reload, physical Android persistence and failed/cancelled payment recovery separately. Record final test date, environment, commit and actual outcomes before submission.
