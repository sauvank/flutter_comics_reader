"""Capture the production UI with demo books on the connected Android device.

Only the dedicated storepreview package is used. Always run `restore` afterward.
"""
import json
import os
import subprocess
import sys
import time
from pathlib import Path

CONFIG = Path(os.environ.get('COMICSTREAM_CAPTURE_CONFIG', '/tmp/comicstream-capture-config.json'))
config = json.loads(CONFIG.read_text()) if CONFIG.exists() else {}
ADB = [config.get('adb', 'adb')]
if config.get('port'):
    ADB += ['-P', str(config['port'])]
if config.get('serial'):
    ADB += ['-s', config['serial']]
PACKAGE = 'com.sauvank.comicstream.storepreview'
STATE = Path('/tmp/comicstream-store-device-state.json')
DEST = Path(__file__).resolve().parent.parent / 'captures'


def adb(*args):
    return subprocess.check_output(ADB + list(args), text=True).strip()


def setting(key):
    return adb('shell', 'settings', 'get', 'global', key)


def setup(kind):
    if not STATE.exists():
        STATE.write_text(json.dumps({
            'size': adb('shell', 'wm', 'size'),
            'density': adb('shell', 'wm', 'density'),
            'policy_control': setting('policy_control'),
        }, indent=2))
    adb('shell', 'wm', 'size', '1080x1920' if kind == 'phone' else '1200x1920')
    adb('shell', 'wm', 'density', '400' if kind == 'phone' else '240')
    adb('shell', 'settings', 'put', 'global', 'policy_control', f'immersive.full={PACKAGE}')
    print(kind)


def restore():
    state = json.loads(STATE.read_text())
    for name in ['size', 'density']:
        override = [line.split(':', 1)[1].strip() for line in state[name].splitlines()
                    if line.startswith('Override')]
        adb('shell', 'wm', name, override[0] if override else 'reset')
    value = state['policy_control']
    if value == 'null':
        adb('shell', 'settings', 'delete', 'global', 'policy_control')
    else:
        adb('shell', 'settings', 'put', 'global', 'policy_control', value)
    STATE.unlink()
    print('Original display settings restored')


command = sys.argv[1]
if command == 'setup':
    setup(sys.argv[2])
elif command == 'restore':
    restore()
elif command == 'capture':
    time.sleep(2)  # Let Flutter transitions, image decoding and touch ripples settle.
    target = DEST / (sys.argv[2] + '.png')
    target.parent.mkdir(parents=True, exist_ok=True)
    focus = adb('shell', 'dumpsys', 'window', 'windows')
    focused = [line for line in focus.splitlines() if 'mCurrentFocus=' in line]
    if not any(PACKAGE in line for line in focused):
        raise RuntimeError('The preview app is not in the foreground; refusing capture')
    adb('shell', 'screencap', '-p', '/sdcard/comicstream-store.png')
    win = (subprocess.check_output(['wslpath', '-w', str(target)], text=True).strip()
           if ADB[0].endswith('.exe') else str(target))
    adb('pull', '/sdcard/comicstream-store.png', win)
    print(target)
elif command == 'tap':
    adb('shell', 'input', 'tap', sys.argv[2], sys.argv[3])
elif command == 'swipe':
    adb('shell', 'input', 'swipe', *sys.argv[2:6], '450')
elif command == 'back':
    adb('shell', 'input', 'keyevent', '4')
elif command == 'launch':
    adb('shell', 'am', 'start', '-W', '-n', f'{PACKAGE}/com.sauvank.comicstream.MainActivity')
