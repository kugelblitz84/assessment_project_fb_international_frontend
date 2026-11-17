# Hosted acceptance checklist

Executed on 2026-11-17 (Asia/Dhaka), exclusively against
`https://fb-international-assessment-project.onrender.com/api/v1`.
No local backend/database, destructive suites or real-money transactions ran.
HTTP checks are distinct from browser/physical-device Flutter acceptance.

## Executed

| Check | Actual result |
| --- | --- |
| Health | 200, production, status ok |
| Platform | 200; horizon 30, step 15, Asia/Dhaka, public settings and 14 hour intervals |
| Catalog | 200; nine items including three packages |
| Search/category/type filters | Passed with actual deployed UUIDs |
| Service detail | Passed |
| Price/offer invariants | price equals effectivePrice, effective <= original; two offers |
| Future availability | Persisted slot IDs and available future slots returned |
| Payment capabilities | Online disabled, sandbox true, pay-at-workshop enabled |
| Guest Gemini | One successful structured response; action IDs checked against live catalog |
| Registration/login | One dedicated randomly identified assessment customer |
| Session identity, CSRF, cookie rotation | Passed via native Python HTTP cookie jar |
| Missing authentication | Appointments/admin payments return 401 |
| Customer admin access | Admin payments returns 403 |
| Booking create/detail/history | Passed; pending, unpaid, backend eligibility fields |
| Payment history | Empty array for the unpaid test appointment |
| Cancellation | Test appointment cancelled through supported PATCH |
| Logout | Refresh returns 401 after logout |

Test appointment: `7af099f0-84cb-4131-8dc5-8945788dadaf` (cancelled).
Account display name: **AutoCare Hosted Acceptance**. Random credentials existed
only in memory, never saved/printed. One account remains because no account deletion
endpoint exists. No extra capacity bookings, uploads or checkout attempts were made.
Ignored `build/hosted-results.log` contains command output; this is the tracked summary.

Reproduce public checks with `python scripts/hosted_acceptance.py`. Add
`--mutations --assistant` explicitly for one new account/booking and one AI request.
Avoid repeated mutation runs: each leaves another labeled account. Cleanup cancels
the eligible booking and logs out in `finally`. Tokens/passwords/cookies are not logged.

## Blocked and pending operator checks

- [ ] **Deployed browser:** deploy the frontend, allow its exact backend CORS origin
  and follow [deployment.md](deployment.md). Verify reload, expired-token refresh,
  CSRF/logout, third-party cookies and account switching. No browser persistence
  result or exact failure cause is claimed.
- [ ] **Physical Android:** install release APK; test login/restart/secure storage,
  booking/cancel, service/package navigation, external checkout and payment refresh
  on resume at typical phone sizes. Widget/HTTP tests do not prove device behavior.
- [ ] **Admin:** provision a dedicated test administrator securely. Check dashboard,
  labeled catalog/offer operations, appointment transitions, payment list/detail
  and reconciliation. Deactivate only test records through supported APIs.
- [ ] **Cloudinary:** configure backend credentials. Upload one small supported
  image as ADMIN; verify returned URL and preview on Android/web, replacement
  failure and legacy/seeded external rendering. Compatibility is implemented and
  mock tested; actual image delivery was not visually verified.
- [ ] **Sandbox payment:** enable sandbox backend credentials/public callback root
  and IPN. Verify capability becomes enabled. Book a future service, enter actual
  test contact information, complete the external sandbox manually using official
  instructions, return and reconcile after five seconds. Verify amount/applied,
  unchanged appointment status, paid cancellation restriction and admin references.
- [ ] **Payment failure/uncertainty:** test gateway failure/cancel, delayed callbacks,
  history recovery, resume checkout, duplicate prevention and five-second spacing.
  Redirect names alone must not establish outcome. Review needs manual support;
  no refund/approval override exists.
- [ ] **Authenticated AI:** ask a budget/package question, compare prices/durations
  against current catalog, use service/package/category actions and verify chat
  clears across accounts. Guest HTTP IDs passed; authenticated/UI/numeric response
  acceptance was not executed. Quota/disabled/error cases are mock tested.
- [ ] **Controlled capacity:** use an operator-approved window and a small number
  of bookings to test server capacity/conflict recovery; cancel eligible test
  records afterward. This run created only one booking; capacity races remain
  mock tested rather than hosted tested.
- [ ] **Render build/publication:** execute pinned Bash build in clean Render Linux,
  inspect release output/deep links and record assigned origin. No remote push or
  frontend deployment was performed.

No backend contract blocker was found in executed checks. Administrator access,
gateway/provider configuration and the assigned frontend origin remain prerequisites.
