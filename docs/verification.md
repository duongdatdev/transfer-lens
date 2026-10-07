# Verification evidence - 07/10/2026

- `flutter analyze`: no issues.
- `flutter test`: 31 passing unit/widget tests, including 375px phones, landscape,
  tablet, light/dark themes, 200% text scaling, form validation and chart selection.
- `flutter test integration_test/app_test.dart -d emulator-5554`: native ML Kit,
  sender/recipient/date/amount extraction, edited review saving, private images and
  thumbnails, SQLite reopen, duplicate warning and image cleanup passed.
- `integration_test/demo_test.dart`: complete native UI walkthrough passed; saved
  three fictional confirmations, selected an unknown category manually, inspected
  both canvas charts, edited a transaction and switched to dark mode.
- `tool/release_smoke.dart` in a signed, optimized release: actual native OCR and
  parser passed without Internet permission. Measured recognition: 2,595 ms.
- APK signature verification: dedicated 2048-bit RSA release key, APK signature v2.
- Final report: four pages, rendered and visually inspected; includes the official
  template sections and four actual annotated screenshots.
- Final demonstration: 2 minutes 40 seconds, 720x1780 H.264 with Vietnamese captions
  in a separate panel below the native app recording.

The initial Android emulator OCR integration run took 4,488 ms. Demo observations
were 4,261 ms, 1,468 ms and 843 ms; cold/warm state, emulator load and image shape vary.
The assignment's sub-100ms target has not been demonstrated and is not guaranteed.

The release manifest removes Internet/network-state, microphone and broad storage
permissions inherited from dependencies. Only camera access is requested for the
optional viewfinder. Android automatic app backups are disabled.

Physical camera/flash/focus, gallery/crop behavior on a target phone, real-bank layouts
and iOS execution still need device validation. All published confirmation images
are synthetic; no real financial transactions were used.
