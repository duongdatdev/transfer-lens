"""Stage the mobile-friendly demo site and selected native screenshots."""
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'output/site'
OUT.mkdir(parents=True, exist_ok=True)
shutil.copytree(ROOT / 'site', OUT, dirs_exist_ok=True)
(OUT / 'assets').mkdir(exist_ok=True)
for name in ('12_cash_flow_light.png', '03_ocr_review.png'):
    shutil.copy2(ROOT / 'docs/screenshots' / name, OUT / 'assets' / name)
video = ROOT / 'output/demo/transfer-lens-demo.mp4'
if video.exists():
    shutil.copy2(video, OUT / 'demo.mp4')
print(f'Staged demo site: {OUT}')
