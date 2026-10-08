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
release_url = publication.get('release', repo_url + '/releases/tag/v1.1.0')
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
    c.setFont('ArialBold', 17 if page == 1 else 25)
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

y = start_page(1, 'MINI-PROJECT SHORT TECHNICAL REPORT', 'Completed course template - TransferLens 1.1.0 - transfer-image OCR and personal expense tracking.')
y = paragraph('<b>Course:</b> Cross-Platform Mobile App Development (VKU)<br/><b>Mini-Project Title:</b> Mini-Project 3 - TransferLens: OCR Expense Tracker &amp; Transfer Parser<br/><b>Team / Student Name:</b> Dương Bảo Đạt (individual project)<br/><b>Submission Date:</b> 09/10/2026 | <b>Application Version:</b> 1.1.0', MARGIN, y)
y = section('1. GENERAL INFORMATION &amp; DELIVERABLE LINKS', y)
y = paragraph('<b>Team Members:</b> Dương Bảo Đạt - <b>Student ID:</b> 23IT046<br/><b>Role:</b> Full-stack mobile developer (architecture, code, tests and documentation)<br/><b>Contribution:</b> 100%', MARGIN, y)
if publication.get('published'):
    asset_url = release_url.replace('/tag/', '/download/')
    y = paragraph(f'<b>Live Demo URL / Signed APK:</b> <link href="{asset_url}/app-release.apk" color="#176B58">Download app-release.apk</link><br/><b>GitHub Repository:</b> <link href="{repo_url}" color="#176B58">{repo_url}</link><br/><b>Video Demo:</b> <link href="{asset_url}/transfer-lens-demo.mp4" color="#176B58">Native walkthrough - 2 minutes 36 seconds</link><br/><b>Technical Report PDF:</b> <link href="{asset_url}/transfer-lens-report.pdf" color="#176B58">Download four-page report</link>', MARGIN, y)
else:
    y = paragraph('<b>Local deliverables:</b> app-release.apk; transfer-lens-demo.mp4; transfer-lens-report.pdf.<br/><b>Publication status:</b> GitHub repository creation returned HTTP 500 during preparation. Source and release assets are ready locally; public URLs are pending publication.', MARGIN, y)
y = paragraph('<b>Adapted scenario:</b> Instead of paper receipts, the user imports a completed bank-transfer image. The parser extracts amount, date, sender/recipient and description. A keyword rule suggests a category; unknown descriptions require manual selection. This scope change follows the student request and is documented for instructor review.', MARGIN, y)
y = section('2. FEATURE IMPLEMENTATION CHECKLIST', y)
y = table([
    ['#', 'Required Feature', 'Status', 'Implementation Details & Acceptance Level'],
    ['1', 'Image input + crop', 'Implemented', 'Gallery import, native crop/rotate; camera flash/focus/frame. Physical-device acceptance pending.'],
    ['2', 'On-device OCR', 'Validated', 'Bundled ML Kit Latin model; four native demo images. Sub-100ms target not demonstrated.'],
    ['3', 'Regex heuristics', 'Validated', 'VND, calendar date, explicit parties, description/reference; ambiguity and failure warnings.'],
    ['4', 'Category + review', 'Validated', 'Five categories plus Other; editable fields, confirmation and duplicate warning.'],
    ['5', 'Provider + SQLite CRUD', 'Validated', 'Database reopen tested; private original images, resized thumbnails and deletion cleanup.'],
    ['6', 'Canvas visualizations', 'Validated', 'Animated donut, weekly bars and daily income/expense trend; selection, replay, reduced motion.'],
    ['7', 'Material 3 + accessibility', 'Validated', 'Light/dark/system; phone/tablet, 200% text and reduced-motion widget checks.'],
    ['8', 'Submission package', 'Published', 'Signed APK, 2:36 native video and four-page PDF. Physical Android and iOS checks pending.'],
], [26, 106, 70, CW-202], y)
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
for i, (label, detail) in enumerate([('CANVAS', 'Donut / bars / trend'), ('DISPLAY', 'History + totals'), ('SHARED STATE', 'Provider'), ('LOCAL DATA', 'SQLite + images')]):
    x = MARGIN+i*(box_width+10)
    c.setFillColor(PALE)
    c.roundRect(x, y-62, box_width, 62, 10, fill=1, stroke=0)
    paragraph(f'<b>{label}</b><br/>{detail}', x+10, y-12, box_width-20, small)
    if i < 3:
        c.setFillColor(GREEN)
        c.setFont('ArialBold', 14)
        c.drawString(x+box_width+1, y-38, '<')
c.setStrokeColor(GREEN)
c.line(WIDTH-MARGIN-box_width/2, y+18, WIDTH-MARGIN-box_width/2, y+3)
c.line(WIDTH-MARGIN-box_width/2, y+3, WIDTH-MARGIN-box_width/2-3, y+8)
c.line(WIDTH-MARGIN-box_width/2, y+3, WIDTH-MARGIN-box_width/2+3, y+8)
y -= 76
y = paragraph('<b>Approved review → Provider ExpenseStore → SQLite repository + private image storage → history + CustomPainter charts.</b><br/>Direction defaults to expense and remains editable. The donut/bars exclude income; the daily trend separates income and expenses. It shows recorded cash flow, not the bank balance.', MARGIN, y)
y = table([
    ['Directory', 'Responsibility'],
    ['lib/domain', 'Transaction model, VND/date/status rules, description keywords, calendar-day cash-flow aggregation.'],
    ['lib/data + state', 'SQLite repository and constraints; Provider transactions, duplicate warning and persistent theme.'],
    ['lib/services', 'Native OCR lifetime; private originals; isolate-based thumbnail resizing.'],
    ['lib/ui + widgets', 'Import/review/history; donut, bars and trend painters; localized animation and reduced motion.'],
], [130, CW-130], y)
y = paragraph('<b>Failure handling:</b> Uncertain fields remain editable. Review and image caching precede database writes; failed writes clean new images. Deletion removes the row before files. Camera/OCR resources are disposed; Android backup is disabled.', MARGIN, y)
y = section('Measured verification', y)
y = paragraph('<b>Toolchain:</b> Flutter 3.47.5, Dart 3.13.4, SDK 36, Java 21; Android API 24+.<br/><b>Checks:</b> Analyzer; 41 unit/widget tests; native Android walkthrough. Trend tests cover leap years, month boundaries, totals, interrupted transitions, replay, 200% text and reduced motion.<br/><b>OCR:</b> v1.0.0 signed release: 2,595 ms offline; initial emulator cold run: 4,488 ms. Latest demo measurements follow; these are not physical-device latency claims.', MARGIN, y)
y = paragraph(escape(metrics).replace('\n', '<br/>'), MARGIN+12, y, CW-24, small)
if y < 45: raise RuntimeError('Page 2 overflow')
c.showPage()

y = start_page(3, 'Empirical evidence', 'Actual screenshots from the Android emulator; the banking confirmations contain fictional demo data.')
y = section('4. EMPIRICAL EVIDENCE &amp; SCREENSHOTS', y)
shots = [
    ('03_ocr_review.png', 'A. Native OCR review', 'The imported image, measured OCR duration and editable amount appear before saving.'),
    ('06_manual_category.png', 'B. Manual classification', 'A generic transfer description has no confident keyword match, so a category must be selected.'),
    ('12_cash_flow_light.png', 'C. Animated daily trend', 'Real saved records form income (dashed) and expense (solid) series. Select a date or replay the reveal.'),
    ('13_cash_flow_dark.png', 'D. Dark mode + updates', 'Edited amounts change the trend and monthly net. Theme changes retain the same financial data.'),
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
y = paragraph('<b>1. Financial ambiguity and native builds:</b> Amount labels outrank currency-only values; balance, fee, account and reference fields are excluded. Conflicts require review; parties require labels. R8 preserves ML Kit registrar constructors; cross-drive Kotlin incremental caching is disabled.<br/><b>2. Animation correctness and recording:</b> Daily values interpolate from the current frame; PathMetric reveals the line. Calendar indexes handle leap years. Reduced motion shows final values. Host-side ADB screenshots preserve live animation during recording.', MARGIN, y)
y = section('OCR regex and heuristic table', y)
y = table([
    ['Field', 'Rule / regex after normalization', 'Fallback'],
    ['VND amount', r'\d{1,3}(?:[.,]\d{3})+ or plain digits; prioritize so tien / amount labels.', 'Reject malformed grouping; manual amount.'],
    ['Date', r'(\d{1,2})[/.-](\d{1,2})[/.-](\d{4}); validate calendar + 2000-2100.', 'Invalid/conflicting dates: date picker.'],
    ['Parties / content', 'Label prefixes: nguoi gui, nguoi nhan, noi dung; read adjacent lines.', 'Missing fields remain editable.'],
    ['Category', 'Accent-free whole phrases: an trua, hoc phi, taxi, mua sam, xem phim.', 'No unique match: manual category.'],
    ['Completion', 'thanh cong | successful | completed; failed/pending override success.', 'Always require human confirmation.'],
], [65, 278, CW-343], y)
y = section('Acceptance scope and remaining checks', y)
y = paragraph('<b>Physical-device follow-up:</b> Camera flash/focus, gallery/crop and real-bank image accuracy still require a target phone. The sub-100ms target has not been demonstrated. iOS requires macOS/Xcode validation.<br/><b>Privacy:</b> No cloud OCR or bank API. SQLite, images and raw text stay local; backups are disabled, with no additional file encryption. Records are user-confirmed and do not prove payment.', MARGIN, y)
y = section('Build and demonstrate', y)
y = paragraph('<b>Setup:</b> flutter pub get; flutter run -d &lt;android-device&gt;.<br/><b>Quality:</b> flutter analyze; flutter test. Native tests: integration_test/app_test.dart and demo_test.dart.<br/><b>Release:</b> Set private android/key.properties; flutter build apk --release.<br/><b>Video:</b> Actual native screens, real ML Kit and fictional data; reproducible integration-test recording.', MARGIN, y)
y = section('References', y)
for label, url in [
    ('Google ML Kit: bundled Android text-recognition model', 'https://developers.google.com/ml-kit/vision/text-recognition/v2/android'),
    ('Flutter ML Kit plugin: mobile platforms and model setup', 'https://pub.dev/packages/google_mlkit_text_recognition'),
    ('Flutter CustomPainter: canvas rendering API', 'https://api.flutter.dev/flutter/rendering/CustomPainter-class.html'),
    ('Course slides: Week 7 Part 1 (rubric p.42); Week 8 Part 2 (canvas pp.30-34, checklist p.43)', None),
]:
    text = f'<link href="{url}" color="#176B58">{escape(label)}</link>' if url else escape(label)
    y = paragraph(text, MARGIN, y, kind=small)
if y < 45: raise RuntimeError('Page 4 overflow')
c.save()
shutil.copy2(OUT, ROOT / 'docs/transfer-lens-report.pdf')
print(f'Created {OUT} (4 pages).')
