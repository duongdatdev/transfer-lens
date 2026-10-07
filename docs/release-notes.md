TransferLens 1.0.0 adapts Mini-Project #3 to successful bank-transfer confirmation images.

- Import/crop an image, run native on-device ML Kit OCR, and review amount/date/parties.
- Suggest an expense category from the transfer description or choose it manually.
- Save expenses/income and private images locally with SQLite and Provider.
- Explore animated interactive CustomPainter donut and weekly spending charts.
- Edit/delete transactions, search/filter history, and switch light/dark/system themes.

Assets:

- `app-release.apk`: Android API 24+, universal APK signed with a dedicated release key.
- `transfer-lens-demo.mp4`: native app walkthrough using fictional transfer images and real OCR.
- `transfer-lens-report.pdf`: four-page technical report following the supplied VKU template.
- `SHA256SUMS.txt`: file checksums for the release assets.

Student: Dương Bảo Đạt - 23IT046. Individual project, 100% contribution.

Validated with Flutter 3.47.5/Dart 3.13.4, 31 unit/widget tests and Android native integration testing.
OCR timing is shown in the app; emulator latency does not establish a sub-100ms physical-device claim.
iOS source is configured but needs a macOS/Xcode build and device validation.
