# Verification evidence - 09/10/2026 (v1.1.0)

- Cloudflare Pages web preview: category suggestion, unknown-description manual
  selection, grouped VND entry, expense/income totals and reset checked in browser.
  Layout has no horizontal overflow at 375px, 768px, 812px landscape and 1440px.
  Emulated reduced motion disables the donut animation. The web preview uses
  fictional data and does not perform native OCR or persist transactions.
- `flutter analyze`: no issues.
- `flutter test`: 41 passing unit/widget tests. Coverage includes 375px phones,
  landscape/tablet, light/dark, 200% text, review validation and chart selection.
- New trend tests cover calendar month isolation, leap days, per-day income/expense
  totals, interrupted transitions, replay, empty data and reduced motion.
- `integration_test/demo_test.dart`: updated native walkthrough passed. Four
  fictional images ran through actual ML Kit; expense and income totals matched
  reviewed data. Replay, date selection, edited amounts and dark mode were exercised.
- Earlier `integration_test/app_test.dart` (v1.0.0): native OCR extraction, edited
  saving, image/thumbnail caching, SQLite reopen, duplicates and deletion passed.
- Earlier signed release smoke (v1.0.0): real ML Kit/parser passed without Internet
  permission; measured recognition was 2,595 ms. Native dependencies/R8 rules remain
  the same in v1.1.0.
- Updated report: four pages, rendered and inspected, with full pipeline, OCR regex
  table and actual light/dark screenshots.
- Updated demo: 2-3 minutes, 720x1780 H.264. Vietnamese captions appear below the
  native app recording; path reveal is recorded with wall-time frame pacing.
- APK 1.1.0 (version code 2): release build and v2 signature verification passed;
  the RSA-2048 certificate matches v1.0.0 for normal app upgrades.
- The final signed main-entry APK installed and cold-launched on the emulator
  with Android activity launch status `ok`.
- PDF/PNG assets are explicitly binary in Git to preserve their bytes on Windows.

Latest emulator OCR observations from the recorded walkthrough:

```text
DEMO-0THER-003: 2632 ms
DEMO-FOOD-001: 7391 ms
DEMO-STUDY-002: 2996 ms
DEMO-INCOME-004: 3675 ms
```

These are emulator observations, not physical-device performance results. The
assignment's sub-100ms target has not been demonstrated and is not guaranteed.

The release manifest removes network, microphone and broad storage permissions.
Camera access supports the optional viewfinder. Android backups are disabled.
Physical camera/flash/focus, gallery/crop, real-bank layouts and iOS still require
validation on the target devices. All published transfer images are fictional.
