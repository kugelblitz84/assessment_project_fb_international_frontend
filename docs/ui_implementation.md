# AutoCare UI implementation

All existing routes now have responsive pages: login, registration, Explore,
service details, schedule and review, acknowledgement, booking history and
details, guest/account profile, profile editing, assistant and not-found.

Run the complete in-memory demo with:

```sh
flutter run -t lib/demo/main_demo.dart
```

Any valid email and nonempty password works in this explicit demo target. The
normal `lib/main.dart` still uses real authentication. Both targets currently use
sample business data, indicated by the preview banner. The assistant is a
deterministic catalogue demo; it does not call an AI model. No API key is needed.
Sample prices are BDT major units; sample slots use Asia/Dhaka (UTC+06:00). These
are demo choices, not assertions about the future API.

The existing architecture remains in place:

- `core/theme`, `core/responsive`, `core/widgets` and the adaptive navigation shell
  provide shared visual infrastructure. ScreenUtil remains initialized once.
- Feature `model`, `service`, `controller`, and `view` folders separate data,
  transport boundaries, Riverpod state and presentation. No repositories, use
  cases, base controllers, code generation or new dependencies were introduced.
- `features/shared` owns the authoritative catalogue, appointment data and
  reusable business widgets. Related features consume the same providers.
- `features/booking` owns availability and the two-step draft. A date change
  clears the slot; late responses are discarded. Create is guarded against double
  submission. A conflict returns to scheduling. Ambiguous failures require
  checking booking history rather than automatically repeating a mutation.
- Appointment status changes follow service acknowledgement. Cancellation is
  pending-only and requires a confirmation dialog. List/detail data refreshes
  after successful mutations. Acknowledgements load by ID for direct links.
- Private providers watch the Core session. Views check record ownership, and
  late operations verify session identity before publishing results. Assistant
  history clears when the session changes.
- Profile responses update the existing Core session through the small guarded
  `SessionController.updateUser` method. There is no second user provider.
- Auth forms still delegate to Core; GoRouter still owns success redirects and
  validates protected return destinations. The authentication interceptor,
  refresh coordination, token storage and access policies were preserved.

## Connecting the backend later

The service methods currently return typed demo responses. Each receives
`dioProvider`; its demo branch can be replaced independently. Setting
`DEMO_DATA=false` disables the fixtures and produces a safe `NOT_CONFIGURED`
result until integration is implemented. No business endpoints have been guessed.

1. Adapt model `fromJson` and request `toJson` to the actual DTOs/envelopes.
2. Connect catalogue, availability, appointment create/list/detail/cancel,
   profile update and assistant methods using the injected Dio. Public operations
   must explicitly opt into `RequestAccess.public` after access is verified;
   protected operations retain the fail-closed default. Real APIs must derive
   account ownership from the authenticated request, not trust a client user ID.
3. Confirm currency units, workshop calendar/timezone, supported profile fields,
   status strings and conflict codes. Demo time-slot objects distinguish the
   absolute start instant from workshop wall-clock display time.
4. Parse assistant actions into the supported typed actions, omitting malformed
   or unknown actions. Controllers also validate service/category references
   against the shared catalogue. Messages render as plain text, with no arbitrary
   deep-link or HTML execution.
5. Remove the demo launch configuration from any production delivery and disable
   sample data. Verify real server authorization, atomic slot validation,
   mutation ambiguity handling and platform session behavior against the backend.

## Review and verification

`flutter test` covers the existing session/network/redirect rules, the guest
booking/cancellation journey, feature controllers and the responsive screen matrix
(320–1440px, normal and 2x text, keyboard open, resizing with active input).
`ui_screenshots_test.dart` optionally renders mobile and desktop review PNGs under
`build/ui_screenshots`; fonts can be supplied through `SCREENSHOT_FONT` without
adding a product font dependency. Network image fallbacks are intentional in
these widget-test captures.

Build commands:

```sh
flutter build web -t lib/demo/main_demo.dart
flutter build apk --debug -t lib/demo/main_demo.dart
```

These builds validate compilation. Browser interaction and physical Android/iOS
device checks are separate from widget rendering and have not been claimed.
