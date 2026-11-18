# Implemented features

## Customer experience

| Feature | Implementation |
|---|---|
| Registration and login | Validated name/email/password forms, REST auth, persistent session and logout. |
| Explore | Shared active service catalog, service/package cards, featured flag, search and category filtering, offer prices and images. |
| Service details | Typed service model with description, duration, inclusions, original/effective price and package contents. |
| Booking | Fetches workshop configuration and server-returned slot UUIDs; date selection, availability, review and confirmation. |
| My bookings | Upcoming/previous views, booking details, status and payment summaries; pending cancellation when permitted. |
| Profile | View/update name and email; logout. Password change is not implemented. |
| AI assistant | Gemini via backend; chat, structured service/package recommendations and category navigation. |
| Payment | Pay at workshop or external SSLCommerz checkout, history, status refresh and reconciliation. |

## Technical details

### Explore on mobile

Android and iOS save the public catalog in SQLite after a successful load. For six hours, opening Explore uses the saved catalog without requesting it again. After that, Explore shows saved services while checking for updates when the page opens, becomes visible again, or the app resumes. If a refresh fails, search, category filters, featured services and details still work with the saved catalog. Pull to refresh at any time to fetch current prices and offers. Successful admin edits to services, categories and offers expire the local catalog.

Service photos are cached on disk as they are viewed. Offline browsing can show previously loaded photos while they remain in the device cache.

### Booking

The workshop uses Asia/Dhaka and a backend-defined rolling booking horizon. No production slots are fabricated locally. The controller prevents double submissions, refreshes after conflicts and asks users to check booking history after ambiguous failures. The backend determines owner, price, duration, bay and status and enforces capacity at the database level. On successful creation the shared appointment provider is invalidated. A booking is initially pending; payment and appointment status are separate.

### Authentication and privacy

The application uses backend-issued access tokens and refresh cookies, secure native token storage and coordinated refresh. Session identity boundaries isolate private data and discard outdated responses. Backend role checks remain authoritative. Guest catalog and assistant access are supported; private booking, profile and administration require an authenticated session.

### AI

The client sends recent conversation history (up to 12 messages, 2,000 characters per message and 12,000 total characters) to the backend. Recommendations are checked against the catalog and rendered as typed navigation actions, not arbitrary URLs. The server supplies verified price/duration lines. No Gemini key is included in Flutter. Chat clears across session identities; quota, timeout and unavailable-provider errors are presented safely. The assistant cannot create/cancel bookings or access personal records.

### Payment

A saved appointment precedes optional checkout. The customer provides contact fields; the backend supplies amount, currency and owner. The app opens only a validated HTTPS gateway URL externally. It does not collect card details or treat a redirect as payment success. On resume/manual refresh it reconciles the saved attempt; reconciliation spacing is at least five seconds. Unresolved attempts prevent another charge; review cases require manual support. Paid cancellation/refunds are outside the automated flow.

## Admin experience

**The admin panel is primarily a simple way to add services and service categories** so customers can browse and book the workshop's offerings. Catalog entry is its main purpose; the other management tools support that workflow.

Live platform admin login credentials are listed in the [README admin panel section](../README.md#admin-panel).

The same application includes role-protected dashboard counts, category/service/package/offer management, active/featured controls, image upload and preview, appointment status transitions and payment review/reconciliation. Images are uploaded to the backend as multipart data; new images are delivered from Cloudinary. No provider secrets or admin promotion logic are in Flutter. Normal registration creates customers only. Backend setup describes admin provisioning.

## UI and reliability

Responsive phone/desktop layouts, reusable components, loading, empty/error states and typed error handling. Network failures do not silently switch to demo data. Explicit offline demo mode uses fixtures; it is not a production integration test.

## Scope boundaries

No automated refunds, appointment rescheduling, password change or vehicle-management UI are included. Android is the primary assessment target; web is an additional deployment. iOS release acceptance is not claimed.
