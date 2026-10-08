"""Record a Flutter integration walkthrough on a dedicated Android emulator."""
from pathlib import Path
import os
import subprocess
import time
import sys
import re
import imageio_ffmpeg

sys.stdout.reconfigure(encoding='utf-8')

ROOT = Path(__file__).resolve().parents[1]
SDK = Path(os.environ.get('ANDROID_HOME', 'D:/Android'))
ADB = str(SDK / 'platform-tools/adb.exe')
FLUTTER = str(Path(os.environ.get('FLUTTER_HOME', 'C:/Users/DuongDat/develop/flutter')) / 'bin/flutter.bat')
APP = 'dev.duongdat.transfer_lens'
OUT = ROOT / 'output/demo'
OUT.mkdir(parents=True, exist_ok=True)
LOG = ROOT / 'tmp/demo-test.log'
LOG.parent.mkdir(parents=True, exist_ok=True)

def adb(*args, **kwargs):
    return subprocess.run([ADB, '-s', 'emulator-5554', *args], check=True, **kwargs)

recording = None
timeline = []
seen_steps = set()
recording_start = None
recording_end = None
captured = set()
screens = ROOT / 'docs/screenshots'
screens.mkdir(parents=True, exist_ok=True)
def stop_recording():
    if recording is not None and recording.poll() is None:
        pid = adb('shell', 'pidof', 'screenrecord', capture_output=True, text=True).stdout.strip()
        if pid: adb('shell', 'kill', '-2', pid)
        recording.wait(timeout=15)

def export_screens():
    data = adb('exec-out', 'run-as', APP, 'cat', 'app_flutter/demo_screenshots/metrics.txt', capture_output=True).stdout
    (screens / 'metrics.txt').write_bytes(data)
    return len(captured) + 1

with LOG.open('w', encoding='utf-8') as log:
    command = [FLUTTER, 'test', 'integration_test/demo_test.dart', '-d', 'emulator-5554', '--dart-define=CAPTURE_VIA_ADB=true']
    if '--fast' in sys.argv: command.append('--dart-define=FAST_DEMO=true')
    test = subprocess.Popen(command, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT)
    started = time.monotonic()
    while test.poll() is None:
        content = LOG.read_text(encoding='utf-8', errors='replace')
        if recording is None and 'DEMO_RECORDING_START' in content:
            recording = subprocess.Popen([ADB, '-s', 'emulator-5554', 'shell', 'screenrecord', '--size', '720x1600', '--bit-rate', '3000000', '--time-limit', '180', '/sdcard/transfer-lens-demo.mp4'], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
            print('Recording the actual app walkthrough...', flush=True)
            recording_start = time.monotonic()
        for label in re.findall(r'DEMO_STEP: (.+)', content):
            if label not in seen_steps and recording_start is not None:
                timeline.append((time.monotonic() - recording_start, label))
                seen_steps.add(label)
        for name in re.findall(r'DEMO_CAPTURE: ([a-zA-Z0-9_]+)', content):
            if name not in captured:
                data = adb('exec-out', 'screencap', '-p', capture_output=True).stdout
                if not data.startswith(b'\x89PNG\r\n\x1a\n'):
                    raise RuntimeError('ADB did not return a PNG screenshot')
                (screens / f'{name}.png').write_bytes(data)
                adb('shell', 'run-as', APP, 'touch', f'app_flutter/demo_screenshots/{name}.done')
                captured.add(name)
        if recording is not None and 'DEMO_RECORDING_END' in content:
            recording_end = time.monotonic()
            stop_recording()
            exported = export_screens()
            break
        if time.monotonic() - started > 900:
            test.terminate()
            raise TimeoutError('Demo test exceeded 15 minutes')
        time.sleep(0.1)
    code = test.wait(timeout=30)
stop_recording()
if code:
    print(LOG.read_text(encoding='utf-8', errors='replace')[-6000:])
    raise SystemExit(code)
if recording is None:
    raise RuntimeError('The test never signaled recording start')
raw = OUT / 'transfer-lens-demo-raw.mp4'
adb('pull', '/sdcard/transfer-lens-demo.mp4', str(raw), stdout=subprocess.DEVNULL)
probe = subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(), '-i', str(raw)], capture_output=True, text=True)
duration_match = re.search(r'Duration: (\d+):(\d+):(\d+\.\d+)', probe.stderr)
if not duration_match: raise RuntimeError('Cannot read the captured video duration')
hours, minutes, seconds = duration_match.groups()
duration = int(hours) * 3600 + int(minutes) * 60 + float(seconds)
startup_delay = max(0, recording_end - recording_start - duration)
timeline = [(max(0, start - startup_delay), label) for start, label in timeline]
def timestamp(seconds):
    millis = max(0, int(seconds * 1000))
    return f'{millis // 3600000:02}:{millis // 60000 % 60:02}:{millis // 1000 % 60:02},{millis % 1000:03}'
end_time = duration
segments = []
for i, (start, label) in enumerate(timeline):
    end = timeline[i+1][0] if i+1 < len(timeline) else end_time
    segments.append(f'{i+1}\n{timestamp(start)} --> {timestamp(max(start + 1, end))}\n{label}\n')
(OUT / 'demo.srt').write_text('\n'.join(segments), encoding='utf-8')
print(f'Saved video and {exported} native screenshots/metrics.', flush=True)
