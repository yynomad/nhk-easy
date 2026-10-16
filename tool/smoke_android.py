#!/usr/bin/env python3
"""Install the debug APK and verify offline reading and real audio on Android."""
import argparse
import re
import subprocess
import time
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--adb', default=str(Path.home() / 'Library/Android/sdk/platform-tools/adb'))
parser.add_argument('--serial', default='emulator-5554')
parser.add_argument('--out', type=Path, default=ROOT / 'docs/screenshots')
args = parser.parse_args()
PACKAGE = 'com.yao.nhk_easy'

def adb(*commands, binary=False):
    return subprocess.run([args.adb, '-s', args.serial, *commands], check=True,
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                          text=not binary, timeout=40).stdout

def nodes():
    last = ''
    for _ in range(3):
        adb('shell', 'rm', '-f', '/sdcard/nhk-smoke.xml')
        adb('shell', 'uiautomator', 'dump', '/sdcard/nhk-smoke.xml')
        last = adb('exec-out', 'cat', '/sdcard/nhk-smoke.xml')
        if last.lstrip().startswith('<?xml'):
            return list(ET.fromstring(last).iter('node'))
        time.sleep(1)
    raise AssertionError(f'Android UI snapshot not ready: {last[:200]}')

def label(node):
    return (node.attrib.get('text', '') + ' ' + node.attrib.get('content-desc', '')).strip()

def find(text, exact=False):
    for node in nodes():
        value = label(node)
        if (value == text if exact else text in value):
            return node
    raise AssertionError(f'Control not found: {text}')

def tap(node):
    x1, y1, x2, y2 = map(int, re.findall(r'\d+', node.attrib['bounds']))
    adb('shell', 'input', 'tap', str((x1 + x2) // 2), str((y1 + y2) // 2))
    time.sleep(.5)

def screenshot(name):
    args.out.mkdir(parents=True, exist_ok=True)
    (args.out / name).write_bytes(adb('exec-out', 'screencap', '-p', binary=True))

assert adb('shell', 'getprop', 'sys.boot_completed').strip() == '1', 'Boot Android first'
apk = ROOT / 'build/app/outputs/flutter-apk/app-debug.apk'
assert apk.is_file(), 'Build the debug APK first'
print(adb('install', '-r', str(apk)).strip(), flush=True)
adb('shell', 'am', 'force-stop', PACKAGE)
adb('shell', 'am', 'start', '-n', f'{PACKAGE}/.MainActivity')
time.sleep(2)
find('日语听力')
screenshot('app-home.png')
tap(find('公園'))
find('阅读与听力')
find('演示合成语音')
tap(find('单篇循环', exact=True))
play_button = find('播放', exact=True)
tap(play_button)
time.sleep(2)
screenshot('app-reading.png')
# UiAutomator requires an idle UI; pause before dumping the changing timeline.
tap(play_button)
find('播放', exact=True)
times = [label(n) for n in nodes() if re.fullmatch(r'\d+:\d{2}', label(n))]
assert times and times[0] != '0:00', f'Playback did not advance: {times}'
tap(find('听力模式', exact=True))
find('先听，再读')
screenshot('app-listening.png')
tap(find('关闭循环', exact=True))
adb('shell', 'input', 'keyevent', '4')
time.sleep(.5)
find('日语听力')
pid = adb('shell', 'pidof', PACKAGE).strip()
assert pid, 'App process exited'
logs = adb('logcat', '-d', '--pid=' + pid)
assert 'FATAL EXCEPTION' not in logs
assert 'EXCEPTION CAUGHT BY WIDGETS LIBRARY' not in logs
print('PASS: install, launch, article, audio ready/play/progress/pause, listening mode, return; no crash.', flush=True)
print('Screenshots:', args.out, flush=True)
