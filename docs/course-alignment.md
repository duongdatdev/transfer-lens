# Week 7-8 course alignment

Reference material supplied by the student: **Week-07-Flutter-Part1 (1).pdf**
and **Week-08-Flutter-Part2.pdf**. These slides describe the original receipt
scenario; the agreed project input remains successful bank-transfer images.

| Course topic | TransferLens implementation |
| --- | --- |
| Week 7: composition, lifecycle, Material 3 | Responsive screens composed from Flutter widgets; camera/OCR/controllers disposed; light/dark/system themes |
| Week 7 p.42: Provider or Riverpod and SQLite | Provider ExpenseStore, repository-based SQLite CRUD and private thumbnails |
| Week 8: local versus shared state | Selection and animation live inside chart widgets; transactions and theme live in Provider |
| Week 8 pp.30-34: CustomPainter and animation | Canvas donut, weekly bars, daily income/expense lines and area; AnimationController + AnimatedBuilder for trend reveal and data transitions |
| Week 8 p.41: review before persistence | Editable amount/date/parties/description/category; explicit completion confirmation before SQLite save |
| Week 8 p.42: monetary regex tuning | Strict integer VND grouping, labeled amount scoring and manual fallback; fee/balance/account exclusion |
| Week 8 p.43: submission package | Signed APK, 2-3 minute native demo, public source and four-page PDF with pipeline, regex table, light/dark screenshots and limitations |

Provider satisfies the Week 7 rubric and remains the shared-state implementation.
The Riverpod sample in Week 8 is a teaching alternative. Routing uses Flutter's
Navigator for the project's small screen hierarchy.

Physical-phone camera/crop testing remains outstanding. The video uses fictional
transfer images with real native OCR, consistent with the requested scope adaptation.
Emulator latency does not demonstrate sub-100ms OCR.
