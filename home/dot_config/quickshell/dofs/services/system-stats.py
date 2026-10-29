"""One shared /proc sampler: no shell commands, no third-party dependencies."""
import json
import pathlib
import shutil
import sys
import time


def cpu_sample():
    values = [int(v) for v in pathlib.Path('/proc/stat').read_text().splitlines()[0].split()[1:9]]
    return sum(values), values[3] + values[4]


def snapshot(previous=None):
    total, idle = cpu_sample()
    cpu = None
    if previous and total > previous[0]:
        cpu = round(100 * (1 - (idle - previous[1]) / (total - previous[0])))
    memory = dict(line.split(':', 1) for line in pathlib.Path('/proc/meminfo').read_text().splitlines())
    mem_total = int(memory['MemTotal'].split()[0])
    available = int(memory['MemAvailable'].split()[0])
    disk = shutil.disk_usage(pathlib.Path.home())
    brightness = None
    for device in sorted(pathlib.Path('/sys/class/backlight').glob('*')):
        try:
            maximum = int((device / 'max_brightness').read_text())
            brightness = round(100 * int((device / 'brightness').read_text()) / maximum)
            break
        except (OSError, ValueError, ZeroDivisionError):
            continue
    return {'cpu': cpu, 'memory': round(100 * (1 - available / mem_total)),
            'memoryUsedGiB': round((mem_total - available) / 1048576, 1),
            'memoryTotalGiB': round(mem_total / 1048576, 1),
            'storage': round(100 * disk.used / disk.total), 'brightness': brightness}, (total, idle)


if __name__ == '__main__':
    previous = None
    while True:
        try:
            result, previous = snapshot(previous)
            print(json.dumps(result), flush=True)
            if '--once' in sys.argv:
                break
            time.sleep(3)
        except BrokenPipeError:
            break
