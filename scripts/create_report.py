"""Build a four-page technical report following the supplied course template."""
from pathlib import Path
from xml.sax.saxutils import escape
import json
import shutil
import sys
from reportlab.pdfgen import canvas
from reportlab.lib.colors import HexColor, white
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import Paragraph, Table, TableStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from PIL import Image

sys.stdout.reconfigure(encoding='utf-8')
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'output/pdf/transfer-lens-report.pdf'
OUT.parent.mkdir(parents=True, exist_ok=True)
pdfmetrics.registerFont(TTFont('Arial', 'C:/Windows/Fonts/arial.ttf'))
pdfmetrics.registerFont(TTFont('ArialBold', 'C:/Windows/Fonts/arialbd.ttf'))
pdfmetrics.registerFontFamily('Arial', normal='Arial', bold='ArialBold')
GREEN = HexColor('#176B58')
INK = HexColor('#18332A')
MUTED = HexColor('#56695F')
PALE = HexColor('#EDF5F0')
WIDTH, HEIGHT = A4
MARGIN = 42
CW = WIDTH - MARGIN * 2
publication_file = ROOT / 'docs/publication.json'
publication = json.loads(publication_file.read_text('utf-8')) if publication_file.exists() else {'published': False}
repo_url = publication.get('repository', 'https://github.com/duongdatdev/transfer-lens')
release_url = publication.get('release', repo_url + '/releases/tag/v1.0.0')
metrics_file = ROOT / 'docs/screenshots/metrics.txt'
metrics = metrics_file.read_text('utf-8') if metrics_file.exists() else 'See on-screen measured OCR durations in the demonstration.'
style = ParagraphStyle('Body', fontName='Arial', fontSize=9.5, leading=14, textColor=INK)
small = ParagraphStyle('Small', parent=style, fontSize=8, leading=11)
heading = ParagraphStyle('Heading', parent=style, fontName='ArialBold', fontSize=14, leading=19, textColor=GREEN)
c = canvas.Canvas(str(OUT), pagesize=A4)
c.setTitle('TransferLens - Mini-Project 3 Technical Report')
c.setAuthor('Dương Bảo Đạt - 23IT046')

def paragraph(text, x, y, width=CW, kind=style):
    p = Paragraph(text, kind)
    _, height = p.wrap(width, 1000)
    p.drawOn(c, x, y-height)
    return y-height-8

def section(title, y):
    return paragraph(title, MARGIN, y, kind=heading)-3

def start_page(page, title, subtitle):
    c.setFillColor(GREEN)
    c.rect(0, HEIGHT-16, WIDTH, 16, fill=1, stroke=0)
    c.setFont('ArialBold', 10)
    c.drawString(MARGIN, HEIGHT-44, 'TRANSFERLENS  /  MINI-PROJECT #3')
    c.setFillColor(INK)
    c.setFont('ArialBold', 25)
    c.drawString(MARGIN, HEIGHT-81, title)
    paragraph(subtitle, MARGIN, HEIGHT-94, kind=small)
    c.setStrokeColor(HexColor('#D9E5DD'))
    c.line(MARGIN, 35, WIDTH-MARGIN, 35)
    c.setFillColor(MUTED)
    c.setFont('Arial', 8)
    c.drawString(MARGIN, 22, 'Dương Bảo Đạt · 23IT046 · Cross-Platform Mobile App Development (VKU)')
    c.drawRightString(WIDTH-MARGIN, 22, f'{page} / 4')
    return HEIGHT-137

def table(rows, widths, y):
    header_style = ParagraphStyle('Header', parent=small, textColor=white, fontName='ArialBold')
    data = [[Paragraph(escape(str(cell)), header_style if i == 0 else small) for cell in row] for i, row in enumerate(rows)]
    t = Table(data, colWidths=widths, hAlign='LEFT')
    t.setStyle(TableStyle([('BACKGROUND', (0,0), (-1,0), GREEN), ('TEXTCOLOR', (0,0), (-1,0), white), ('ROWBACKGROUNDS', (0,1), (-1,-1), [PALE, white]), ('VALIGN', (0,0), (-1,-1), 'TOP'), ('LEFTPADDING', (0,0), (-1,-1), 9), ('RIGHTPADDING', (0,0), (-1,-1), 9), ('TOPPADDING', (0,0), (-1,-1), 8), ('BOTTOMPADDING', (0,0), (-1,-1), 8), ('LINEBELOW', (0,0), (-1,0), .5, GREEN)]))
    _, h = t.wrap(CW, 1000)
    t.drawOn(c, MARGIN, y-h)
    return y-h-12

y = start_page(1, 'Short technical report', 'Official template: general information, feature checklist, architecture, empirical evidence and challenges.')
y = section('1. GENERAL INFORMATION &amp; DELIVERABLE LINKS', y)
y = paragraph('<b>Course:</b> Cross-Platform Mobile App Development (VKU)<br/><b>Mini-Project Title:</b> Mini-Project 3 - OCR Expense Tracker &amp; Transfer Parser<br/><b>Student:</b> Dương Bảo Đạt | <b>Student ID:</b> 23IT046<br/><b>Team:</b> Individual | <b>Role:</b> Full-stack mobile developer | <b>Contribution:</b> 100%<br/><b>Submission date:</b> 07/10/2026', MARGIN, y)
if publication.get('published'):
    y = paragraph(f'<b>GitHub:</b> <link href="{repo_url}" color="#176B58">{repo_url}</link><br/><b>APK + video:</b> <link href="{release_url}" color="#176B58">GitHub Release v1.0.0 - download all deliverables</link><br/><b>PDF:</b> transfer-lens-report.pdf (this report)', MARGIN, y)
else:
    y = paragraph('<b>Local deliverables:</b> app-release.apk; transfer-lens-demo.mp4; transfer-lens-report.pdf.<br/><b>Publication status:</b> GitHub repository creation returned HTTP 500 during preparation. Source and release assets are ready locally; public URLs are pending publication.', MARGIN, y)
y = paragraph('<b>Adapted scenario:</b> Instead of paper receipts, the user imports a completed bank-transfer image. The parser extracts amount, date, sender/recipient and description. A keyword rule suggests a category; unknown descriptions require manual selection. This scope change follows the student request and is documented for instructor review.', MARGIN, y)
y = section('2. FEATURE IMPLEMENTATION CHECKLIST', y)
y = table([
    ['Required feature', 'Status', 'Implementation / acceptance'],
    ['Image input + crop', 'Implemented', 'Gallery screenshot import, native crop/rotate; optional camera with flash, focus and frame.'],
    ['On-device OCR', 'Validated', 'Bundled ML Kit Latin model; native Android OCR exercised on fictional image assets.'],
    ['Regex heuristics', 'Validated', 'VND, calendar date, explicit parties, description/reference; ambiguity and failure warnings.'],
    ['Category + review', 'Validated', 'Five mapped categories plus Other; editable fields, confirmation and duplicate warning.'],
    ['Provider + SQLite CRUD', 'Validated', 'Local records survive database reopen; full-size images and resized thumbnails cached privately.'],
    ['Canvas visualizations', 'Validated', 'Animated, interactive CustomPainter donut and weekly bars; no chart package.'],
    ['Material 3 + accessibility', 'Validated', 'Light/dark/system, responsive layout, large-text and reduced-motion widget checks.'],
    ['Release + report', 'Prepared', 'Signed APK, native walkthrough video, four-page report; online publication status shown above.'],
], [132, 67, CW-199], y)
if y < 45: raise RuntimeError('Page 1 overflow')
c.showPage()

y = start_page(2, 'Architecture & validation', 'A modular Flutter application with local data ownership and transparent parsing rules.')
y = section('3. TECHNICAL ARCHITECTURE &amp; PROJECT STRUCTURE', y)
steps = [('IMAGE', 'Gallery / camera'), ('ON DEVICE', 'ML Kit OCR'), ('DART', 'Heuristic parser'), ('HUMAN', 'Review + category')]
box_width = (CW-30)/4
for i, (label, detail) in enumerate(steps):
    x = MARGIN+i*(box_width+10)
    c.setFillColor(PALE)
    c.roundRect(x, y-62, box_width, 62, 10, fill=1, stroke=0)
    paragraph(f'<b>{label}</b><br/>{detail}', x+10, y-12, box_width-20, small)
    if i < 3:
        c.setFillColor(GREEN)
        c.setFont('ArialBold', 14)
        c.drawString(x+box_width+1, y-38, '>')
y -= 80
y = paragraph('<b>Approved review → Provider ExpenseStore → SQLite repository + private image storage → history + CustomPainter charts.</b><br/>The app never initiates a transfer. Direction defaults to expense and remains editable. Income is recorded separately and excluded from spending charts.', MARGIN, y)
y = table([
    ['Directory', 'Responsibility'],
    ['lib/domain', 'Immutable transaction model; integer VND normalization; label/date/status rules; accent-insensitive description keywords.'],
    ['lib/data + lib/state', 'Repository abstraction, schema constraints/indexes, parameterized CRUD, Provider state, duplicate warning and persistent theme.'],
    ['lib/services', 'Native recognizer lifetime and visual reading order; private original images; thumbnail resizing in a background isolate.'],
    ['lib/ui + widgets', 'Import, camera, review, history and settings; interactive donut/bar painters with reduced-motion support.'],
    ['test + integration_test', 'Parser edge cases, real SQLite reopen, adaptive UI, native OCR and end-to-end review/cache/delete flow.'],
], [130, CW-130], y)
y = paragraph('<b>Failure handling:</b> Missing/ambiguous fields remain editable. Database writes happen after review and image caching. If a write fails, new cache files are cleaned up. Delete the row before cleaning its images. Camera lifecycle and OCR resources are disposed. Android backups are disabled; local files are not additionally encrypted.', MARGIN, y)
y = section('Measured verification', y)
y = paragraph('<b>Toolchain:</b> Flutter 3.47.5, Dart 3.13.4, Android SDK 36, Java 21. Android API 24+ is the release target. iOS 15.5+ is configured but untested on Windows.<br/><b>Checks:</b> Formatting and analyzer; 31 unit/widget tests; native Android review/cache/CRUD integration. A signed optimized release also recognized the sample without Internet permission (2,595 ms).<br/><b>OCR cold run:</b> 4,488 ms on the emulator in the initial integration test. Further demo observations are below. These are observations, not a physical-device performance claim.', MARGIN, y)
y = paragraph(escape(metrics).replace('\n', '<br/>'), MARGIN+12, y, CW-24, small)
if y < 45: raise RuntimeError('Page 2 overflow')
c.showPage()

y = start_page(3, 'Empirical evidence', 'Actual screenshots from the Android emulator; the banking confirmations contain fictional demo data.')
y = section('4. EMPIRICAL EVIDENCE &amp; SCREENSHOTS', y)
shots = [
    ('03_ocr_review.png', 'A. Native OCR review', 'The imported image, measured OCR duration and editable amount appear before saving.'),
    ('06_manual_category.png', 'B. Manual classification', 'A generic transfer description has no confident keyword match, so a category must be selected.'),
    ('07_donut.png', 'C. Canvas analytics', 'Saved expenses feed the category donut. Selected categories expose exact VND amounts.'),
    ('10_dark_history.png', 'D. Persistent history', 'Searchable records with thumbnails, category/date labels and amounts; Material 3 dark mode.'),
]
cell_width = (CW-20)/2
for i, (filename, title, annotation) in enumerate(shots):
    x = MARGIN+(i%2)*(cell_width+20)
    top = y-(i//2)*305
    paragraph(f'<b>{title}</b>', x, top, cell_width, small)
    path = ROOT / 'docs/screenshots' / filename
    if not path.exists(): raise FileNotFoundError(path)
    w,h = Image.open(path).size
    image_height = 258
    image_width = image_height*w/h
    c.drawImage(str(path), x, top-20-image_height, image_width, image_height, preserveAspectRatio=True, mask='auto')
    paragraph(annotation, x+image_width+10, top-25, cell_width-image_width-10, small)
c.showPage()

y = start_page(4, 'Challenges & resolutions', 'Design decisions, validation limits and the practical submission handoff.')
y = section('5. TECHNICAL CHALLENGES &amp; RESOLUTIONS', y)
y = paragraph('<b>Challenge 1 - Financial numbers and banking layouts.</b><br/>A confirmation can contain a balance, fee, reference and account number, all near the real amount. The parser scores explicit amount labels above currency-only values and excludes unrelated fields. It validates calendar dates, treats conflicting candidates as unresolved, and reads only explicitly labeled parties. Names and missing data remain editable. Classification uses only description keywords with phrase boundaries, avoiding accidental matches inside names or unrelated words.', MARGIN, y)
y = paragraph('<b>Challenge 2 - Native release build and adaptive UI.</b><br/>Windows Kotlin caches failed across different drives; incremental compilation was disabled. R8 required narrowly scoped rules for unused ML Kit scripts and explicit preservation of reflectively created component-registrar constructors. A signed release smoke test confirmed OCR without Internet permission after the fix. Large-text tests found overflowing summary labels and chart centers; flexible text layout resolved the failures.', MARGIN, y)
y = section('Acceptance scope and remaining checks', y)
y = paragraph('<b>Validated:</b> Android native OCR on fictional confirmations, reviewed saving, SQLite persistence, image/thumbnail lifecycle, category fallback, duplicate detection, canvas selection, responsive light/dark layouts and release signing.<br/><b>Physical-device follow-up:</b> Verify camera flash/focus, photo-picker/crop flow, bank-specific image accuracy and latency on the target phone. Emulator OCR measurements do not establish the assignment\'s sub-100ms target.<br/><b>iOS:</b> Source permissions, Podfile and deployment target are prepared; a macOS/Xcode device build is still required.<br/><b>Privacy:</b> No account, cloud OCR or bank integration. Images, raw text and transactions remain local. This app is a personal record and does not prove that money was transferred.', MARGIN, y)
y = section('Build and demonstrate', y)
y = paragraph('<b>Setup:</b> flutter pub get; flutter run -d &lt;android-device&gt;.<br/><b>Quality:</b> flutter analyze; flutter test; flutter test integration_test/app_test.dart -d &lt;android-device&gt;.<br/><b>Signed release:</b> Set private android/key.properties, then flutter build apk --release.<br/><b>Video:</b> Actual Flutter screens and real ML Kit processing, automated using integration_test with fictional data. The source includes a reproducible walkthrough and recording script.', MARGIN, y)
y = section('References', y)
for label, url in [
    ('Google ML Kit: bundled Android text-recognition model', 'https://developers.google.com/ml-kit/vision/text-recognition/v2/android'),
    ('Flutter ML Kit plugin: mobile platforms and model setup', 'https://pub.dev/packages/google_mlkit_text_recognition'),
    ('Flutter CustomPainter: canvas rendering API', 'https://api.flutter.dev/flutter/rendering/CustomPainter-class.html'),
    ('Image Cropper: native configuration', 'https://pub.dev/packages/image_cropper'),
    ('Original report structure: supplied Mini-Project-3-Report-Template.md', None),
]:
    text = f'<link href="{url}" color="#176B58">{escape(label)}</link>' if url else escape(label)
    y = paragraph(text, MARGIN, y, kind=small)
if y < 45: raise RuntimeError('Page 4 overflow')
c.save()
shutil.copy2(OUT, ROOT / 'docs/transfer-lens-report.pdf')
print(f'Created {OUT} (4 pages).')
