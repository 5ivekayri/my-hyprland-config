#!/usr/bin/env python3
import fcntl
import json
import os
import subprocess
import sys

PROFILE = 'KAYRI_NET'

def nm(*args):
    return subprocess.run(['nmcli', '--wait', '20', *args], capture_output=True, text=True)

def active():
    result = nm('-t', '-f', 'NAME', 'connection', 'show', '--active')
    return PROFILE in result.stdout.splitlines()

if len(sys.argv) > 1 and sys.argv[1] == 'toggle':
    lock = open(os.path.join(os.environ.get('XDG_RUNTIME_DIR', '/tmp'), 'hyprland-hotspot.lock'), 'w')
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        sys.exit(0)
    was_active = active()
    result = nm('connection', 'down' if was_active else 'up', 'id', PROFILE)
    message = ('Точка доступа выключена' if was_active else 'Точка доступа включена') if result.returncode == 0 else result.stderr.strip()
    subprocess.run(['notify-send', 'KAYRI_NET', message], check=False)
    sys.exit(result.returncode)

is_active = active()
print(json.dumps({'text': '󰖩 Hotspot', 'class': 'active' if is_active else 'inactive', 'tooltip': 'KAYRI_NET — ' + ('включена' if is_active else 'выключена') + '\nНажмите, чтобы ' + ('выключить' if is_active else 'включить')}, ensure_ascii=False))
