# Deployment

Production API: `https://fb-international-assessment-project.onrender.com/api/v1`.
Normal builds default to this URL. `API_BASE_URL` overrides it at compile time and
must include `/api/v1` exactly once. All frontend environment values are public;
never supply database, JWT, Gemini, Cloudinary, merchant or signing secrets here.

## Render Static Site

| Setting | Exact value |
| --- | --- |
| Repository | `kugelblitz84/assessment_project_fb_international_frontend` |
| Branch | `master` |
| Root directory | Repository root (leave blank) |
| Service type | Static Site |
| Build command | `bash scripts/render-build.sh` |
| Publish directory | `build/web` |
| Auto deployment | Enabled, on commit |
| `API_BASE_URL` | `https://fb-international-assessment-project.onrender.com/api/v1` |
| Rewrite | `/*` to `/index.html` (Rewrite, not Redirect) |

`render.yaml` uses `type: web`, `runtime: static` and `autoDeployTrigger: commit`,
following the [Render Blueprint reference](https://render.com/docs/blueprint-spec).
No frontend service was created/deployed and no Git changes were pushed.

The Bash script uses `set -euo pipefail`, retrieves official Flutter tag **3.41.9**,
checks commit `00b0c91f06209d9e4a41f71b7a512d6eb3b9c694`, enables web, runs
`flutter pub get --enforce-lockfile`, then builds web release. This release supplies
Dart **3.11.5**, satisfying `^3.11.5`. Its official
[engine revision](https://github.com/flutter/flutter/blob/3.41.9/bin/internal/engine.version)
matches the installed SDK. The checkout is cached only at the pinned revision.
Optional `RENDER_FLUTTER_CACHE` changes the SDK cache directory. Git/Bash and
outbound GitHub/Flutter artifact access are required. Git Bash syntax validation
passed. Clean Linux Render execution remains an operator step; local web release
compilation uses the same SDK version.

The app retains Flutter's default hash URL strategy. The rewrite supports direct
SPA paths and future path-strategy compatibility without changing route guards.

## Browser authentication

1. After Render assigns a hostname, add its exact HTTPS origin (no path/trailing
   slash/wildcard) to backend `CORS_ORIGINS`, preserving other trusted origins.
2. Keep `AUTH_COOKIE_SECURE=true` and `AUTH_COOKIE_SAME_SITE=none` for cross-site
   sessions. Refresh cookies remain host-only, HttpOnly and scoped to `/api/v1/auth`.
3. Test login, `GET /auth/csrf`, CSRF headers on refresh/logout, cookie rotation,
   reload, expired-access refresh, logout and two-account isolation in real browsers.
4. If restoration fails, record Network/Cookies evidence distinguishing CORS,
   missing credential permission, cookie attributes and third-party cookie policy.
5. For browser policy blocking, use HTTPS custom domains under one registrable
   domain or a controlled same-origin reverse proxy for `/api/v1`. Update the API
   base and exact origins accordingly. An SPA rewrite alone does not proxy APIs.

Native HTTP refresh/rotation passed; it does not prove browser persistence. No
assigned frontend URL was available for deployed browser acceptance, and no exact
browser failure cause is asserted. Never disable CSRF, weaken cookies, use wildcard
credentialed CORS or expose refresh tokens to JavaScript.

## Android release

```sh
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=https://fb-international-assessment-project.onrender.com/api/v1
```

Artifact: `build/app/outputs/flutter-apk/app-release.apk`. The release manifest
includes INTERNET, AutoCare label and disabled backups. Secure token/cookie storage,
HTTPS transport, external `url_launcher` checkout and resume listener are retained.
Install on a physical device and run the checklist before claiming runtime behavior.

The first build's Gradle daemon disappeared with the old 8 GiB heap/4 GiB metaspace.
The repository now limits heap to 3 GiB, metaspace to 1 GiB and workers to two.
Memory pressure was a possible cause, not a proven diagnosis.

The existing `com.example.assessment_project_fb_international_frontend` ID, launcher
icon and debug-key release signing support assessment installation. Final branding,
application ID and a protected release keystore are required for store distribution.
No keystore/signing secret was added.

## Provider prerequisites (backend only)

For sandbox checkout, configure `SSLCOMMERZ_STORE_ID`, `SSLCOMMERZ_STORE_PASSWORD`,
`SSLCOMMERZ_IS_LIVE=false` and `PUBLIC_API_BASE_URL` set to the deployed HTTPS API.
Register the IPN listener
`https://fb-international-assessment-project.onrender.com/api/v1/payments/sslcommerz/ipn`
in the merchant sandbox portal and verify callbacks. Follow backend documentation
and official gateway test instructions; never use real money. The deployed public
capability currently reports online payment disabled.

Provision a dedicated test ADMIN using backend `npm run admin:create` in the owner's
secure environment. Configure all three Cloudinary credentials there for upload
acceptance. No frontend secrets or backend contract changes are needed.
