"""Add Vietnamese captions below the native screen recording without obscuring the UI."""
from pathlib import Path
import re
import subprocess
import sys
import textwrap
import imageio_ffmpeg

sys.stdout.reconfigure(encoding='utf-8')
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'output/demo'
video = OUT / 'transfer-lens-demo.mp4'
raw = OUT / 'transfer-lens-demo-raw.mp4'
if video.exists() and not raw.exists(): video.replace(raw)
subtitle = (OUT / 'demo.srt').read_text('utf-8')
header = '''[Script Info]
ScriptType: v4.00+
PlayResX: 720
PlayResY: 1780
WrapStyle: 0

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Default,Arial,28,&H00FFFFFF,&H00FFFFFF,&H00101A17,&H00101A17,0,0,0,0,100,100,0,0,1,1,0,2,24,24,42,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
'''
events = []
for start, end, label in re.findall(r'(\d\d:\d\d:\d\d,\d{3}) --> (\d\d:\d\d:\d\d,\d{3})\n([^\n]+)', subtitle):
    def ass_time(value): return value[1:].replace(',', '.')[:-1]
    text = r'\N'.join(textwrap.wrap(label, width=48)).replace('{', '').replace('}', '')
    events.append(f'Dialogue: 0,{ass_time(start)},{ass_time(end)},Default,,0,0,0,,{text}\n')
(OUT / 'demo.ass').write_text(header + ''.join(events), 'utf-8')
command = [imageio_ffmpeg.get_ffmpeg_exe(), '-y', '-i', raw.name, '-vf', 'pad=720:1780:0:0:color=0x101a17,ass=demo.ass', '-r', '30', '-c:v', 'libx264', '-crf', '23', '-preset', 'fast', '-pix_fmt', 'yuv420p', '-movflags', '+faststart', video.name]
with (ROOT / 'tmp/video-encode.log').open('w', encoding='utf-8') as log:
    subprocess.run(command, cwd=OUT, stdout=log, stderr=subprocess.STDOUT, check=True)
probe = subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(), '-i', str(video)], capture_output=True, text=True)
print('\n'.join(line.strip() for line in probe.stderr.splitlines() if 'Duration:' in line))
print(f'Captioned video: {video}')
