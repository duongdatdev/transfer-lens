TransferLens 1.1.0 adds animated daily cash flow to the offline OCR expense tracker.

- Inspect income and expense lines by calendar day, with dashed/solid styling.
- Replay a 900 ms reveal; record edits/removals interpolate smoothly over 500 ms.
- View exact daily VND amounts and monthly income minus expenses.
- Use date buttons, large text, dark mode and reduced motion.
- Try a new fictional incoming-transfer image through real native ML Kit OCR.
- Retain import/crop, review, categories, SQLite CRUD, thumbnails, donut and weekly bars.
- Updated native demo and four-page report with pipeline and OCR regex table.

Assets:

- `app-release.apk`: Android API 24+, universal APK signed with the existing release key.
- `transfer-lens-demo.mp4`: 2-3 minute native walkthrough, fictional data, real OCR.
- `transfer-lens-report.pdf`: four-page technical report following the supplied VKU template.
- `SHA256SUMS.txt`: file checksums for the release assets.

Student: Dương Bảo Đạt - 23IT046. Individual project, 100% contribution.

Validated with Flutter 3.47.5/Dart 3.13.4 and 41 unit/widget tests.
OCR timing is shown in the app; emulator latency does not establish a sub-100ms physical-device claim.
iOS source is configured but needs a macOS/Xcode build and device validation.
Camera/flash/focus and gallery/crop still require testing on the target physical phone.
