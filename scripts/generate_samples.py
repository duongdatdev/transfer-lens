"""Generate fictional transfer confirmations and the app icon for demos."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import os

ROOT = Path(__file__).resolve().parents[1]
FONT = Path(os.environ.get('TRANSFERLENS_FONT', 'C:/Windows/Fonts/arial.ttf'))
BOLD = FONT.with_name('arialbd.ttf') if FONT.with_name('arialbd.ttf').exists() else FONT

def font(size, bold=False):
    return ImageFont.truetype(str(BOLD if bold else FONT), size)

def sample(name, amount, recipient, description, ref):
    image = Image.new('RGB', (1080, 1740), '#f5f7f4')
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle((48, 48, 1032, 1692), 48, fill='white')
    draw.text((92, 94), 'TRANSFERLENS / DEMO', fill='#176b58', font=font(28, True))
    draw.ellipse((464, 176, 616, 328), fill='#dcefe6')
    draw.line((505, 252, 533, 280, 578, 224), fill='#176b58', width=12)
    draw.text((540, 376), 'Chuyển khoản thành công', anchor='mm', fill='#172c25', font=font(49, True))
    draw.text((540, 484), amount + ' VND', anchor='mm', fill='#176b58', font=font(74, True))
    rows = [('Số tiền', amount + ' VND'), ('Người gửi', 'NGUYEN VAN AN'), ('Người nhận', recipient), ('Nội dung', description), ('Ngày giao dịch', '07/10/2026 12:30'), ('Mã giao dịch', ref), ('Phí giao dịch', '0 VND')]
    y = 586
    for label, value in rows:
        draw.text((96, y), label, fill='#55675e', font=font(31))
        draw.text((96, y + 44), value, fill='#172c25', font=font(37, True))
        draw.line((96, y + 100, 984, y + 100), fill='#e5eae6', width=2)
        y += 134
    draw.text((540, 1620), 'DỮ LIỆU GIẢ - KHÔNG PHẢI CHỨNG TỪ NGÂN HÀNG', anchor='mm', fill='#64776b', font=font(25))
    target = ROOT / 'assets/samples' / f'{name}.png'
    target.parent.mkdir(parents=True, exist_ok=True)
    image.save(target)

sample('food', '150.000', 'TRAN THI BINH', 'Thanh toan an trua', 'DEMO-FOOD-001')
sample('study', '450,000', 'TRUNG TAM HOC TAP', 'Dong hoc phi thang 10', 'DEMO-STUDY-002')
sample('unknown', '200.000', 'LE MINH HOA', 'Chuyen tien', 'DEMO-OTHER-003')

icon = Image.new('RGB', (1024, 1024), '#176b58')
draw = ImageDraw.Draw(icon)
draw.rounded_rectangle((224, 144, 800, 880), 100, fill='#edf7f1')
for y, width in [(316, 304), (432, 220), (548, 150)]:
    draw.rounded_rectangle((328, y, 328 + width, y + 40), 20, fill='#176b58')
draw.ellipse((554, 616, 866, 928), fill='#bcebd1')
draw.line((624, 766, 694, 836, 804, 704), fill='#176b58', width=32)
for bucket, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]:
    icon.resize((size, size), Image.Resampling.LANCZOS).save(ROOT / f'android/app/src/main/res/mipmap-{bucket}/ic_launcher.png')
icon.save(ROOT / 'assets/app_icon.png')
print('Generated three fictional OCR fixtures and launcher artwork.')
