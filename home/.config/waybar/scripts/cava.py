#!/usr/bin/env python3

import os
import signal
import subprocess
import sys
import tempfile


RAMP = ["⠀", "⣀", "⣄", "⣆", "⣇", "⣧", "⣷", "⣿"]

PALETTES = {
    "default": [
        "f38ba8",
        "a6e3a1",
        "f9e2af",
        "89b4fa",
        "f5c2e7",
        "94e2d5",
        "bac2de",
        "e7e3ff",
    ],
    "kanagawa": [
        "7E9CD8",
        "957FB8",
        "D27E99",
        "C8C093",
        "E46876",
        "76946A",
        "E6C384",
        "FFA066",
    ],
    "sakura": [
        "E9D5FF",
        "EECFFC",
        "F4CFE7",
        "F7D6D0",
        "FBE3C4",
    ],
    "mist": [
        "D8E4FF",
        "DDE7F7",
        "E3E9F2",
        "EAEFF2",
    ],
}


def parse_args(argv):
    bars = 5
    framerate = 48
    palette = "default"
    for i, arg in enumerate(argv):
        if arg == "--bars" and i + 1 < len(argv):
            bars = int(argv[i + 1])
        if arg == "--framerate" and i + 1 < len(argv):
            framerate = int(argv[i + 1])
        if arg == "--palette" and i + 1 < len(argv):
            palette = argv[i + 1]
    return bars, framerate, palette


def interpolate_color(c1, c2, t):
    r1, g1, b1 = int(c1[0:2], 16), int(c1[2:4], 16), int(c1[4:6], 16)
    r2, g2, b2 = int(c2[0:2], 16), int(c2[2:4], 16), int(c2[4:6], 16)
    r = int(r1 + (r2 - r1) * t)
    g = int(g1 + (g2 - g1) * t)
    b = int(b1 + (b2 - b1) * t)
    return f"{r:02X}{g:02X}{b:02X}"


def color_for_level(level, max_level, palette):
    colors = PALETTES.get(palette, PALETTES["default"])
    if max_level <= 0 or len(colors) == 1:
        return colors[0]

    t = level / max_level
    span = t * (len(colors) - 1)
    i = int(span)
    if i >= len(colors) - 1:
        return colors[-1]
    return interpolate_color(colors[i], colors[i + 1], span - i)


def write_cava_config(path, bars, framerate):
    with open(path, "w", encoding="utf-8") as f:
        f.write(
            "[general]\n"
            f"framerate={framerate}\n"
            f"bars={bars}\n"
            "[input]\n"
            "method = pulse\n"
            "source = auto\n"
            "[output]\n"
            "method=raw\n"
            "data_format=ascii\n"
            "ascii_max_range=100\n"
            "bar_delimiter=32\n"
        )


def main():
    bars, framerate, palette = parse_args(sys.argv[1:])

    cava_conf = tempfile.mkstemp(prefix="waybar-cava-", suffix=".conf")[1]
    write_cava_config(cava_conf, bars, framerate)

    cava_proc = None

    def cleanup(*_args):
        try:
            if cava_proc and cava_proc.poll() is None:
                cava_proc.terminate()
        except Exception:
            pass
        try:
            os.remove(cava_conf)
        except Exception:
            pass
        raise SystemExit(0)

    signal.signal(signal.SIGTERM, cleanup)
    signal.signal(signal.SIGINT, cleanup)

    try:
        cava_proc = subprocess.Popen(
            ["cava", "-p", cava_conf],
            stdout=subprocess.PIPE,
            text=True,
        )

        peak = 1.0
        decay = 0.97

        for line in cava_proc.stdout:
            parts = line.strip().split()
            if not parts:
                continue

            try:
                values = [int(v) for v in parts]
            except ValueError:
                continue

            frame_max = max(values) if values else 0
            peak = max(peak * decay, float(frame_max), 1.0)

            out = []
            for v in values:
                x = v / peak
                lvl = int((x**0.65) * (len(RAMP) - 1))
                if lvl < 0:
                    lvl = 0
                if lvl >= len(RAMP):
                    lvl = len(RAMP) - 1
                ch = RAMP[lvl]
                color = color_for_level(lvl, len(RAMP) - 1, palette)
                out.append(f'<span color="#{color}">{ch}</span>')

            print("".join(out), flush=True)
    finally:
        cleanup()


if __name__ == "__main__":
    main()
