#!/usr/bin/env python3

import argparse
import os
import signal
import subprocess
import sys
import tempfile


# Theme palettes
PALETTES = {
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


def build_ramp_list(style, chars=""):
    if style == "braille":
        return [
            "⠁",
            "⠃",
            "⠇",
            "⡇",
            "⡏",
            "⡟",
            "⡿",
            "⣇",
            "⣏",
            "⣟",
            "⣯",
            "⣷",
            "⣾",
            "⣽",
            "⣻",
            "⣿",
        ]
    if style == "blocks":
        return ["▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"]
    if style == "custom":
        return (list(chars)) if chars else ["▏", "▎", "▍", "▌", "▋", "▊", "▉"]
    return ["▁", "▂", "▃", "▄", "▅"]


def cleanup(sig, frame):
    try:
        os.remove(cava_conf)
        cava_proc.kill()
        self_proc.kill()
    except:
        pass
    sys.exit(0)


def interpolate_color(color1, color2, factor):
    """Interpolate between two hex colors."""

    def hex_to_rgb(hex_color):
        return tuple(int(hex_color[i : i + 2], 16) for i in (0, 2, 4))

    def rgb_to_hex(rgb):
        return f"{rgb[0]:02X}{rgb[1]:02X}{rgb[2]:02X}"

    rgb1 = hex_to_rgb(color1)
    rgb2 = hex_to_rgb(color2)
    interpolated = tuple(int(rgb1[i] + (rgb2[i] - rgb1[i]) * factor) for i in range(3))
    return rgb_to_hex(interpolated)


if len(sys.argv) > 1 and sys.argv[1] == "--subproc":
    # Define styles
    style = sys.argv[2]

    chars = sys.argv[3] if len(sys.argv) > 3 else ""
    ramp_list = build_ramp_list(style, chars)

    # Use selected palette colors
    colors = PALETTES.get(sys.argv[4], PALETTES["sakura"]) if len(sys.argv) > 4 else PALETTES["sakura"]

    while True:
        try:
            line = sys.stdin.readline()
            if not line:
                break
            cava_input = line.strip().split()
            cava_input = [int(i) for i in cava_input]
            output = ""
            for bar in cava_input:
                if bar < len(ramp_list):
                    char = ramp_list[bar]
                else:
                    char = ramp_list[-1]

                # Apply gradient colors
                if colors:
                    # Map the bar intensity to a color in the gradient
                    color_index = min(bar, len(ramp_list) - 1)
                    gradient_factor = color_index / (len(ramp_list) - 1)
                    num_colors = len(colors)
                    segment = int(gradient_factor * (num_colors - 1))
                    segment_factor = gradient_factor * (num_colors - 1) - segment
                    color1 = colors[segment]
                    color2 = (
                        colors[segment + 1]
                        if segment + 1 < num_colors
                        else colors[segment]
                    )
                    color = interpolate_color(color1, color2, segment_factor)
                    # Changed Polybar format to Waybar Pango markup
                    output += f'<span color="#{color}">{char}</span>'
                else:
                    output += char
            print(output, flush=True)
        except (ValueError, IndexError):
            continue
        except EOFError:
            break

    sys.exit(0)

parser = argparse.ArgumentParser()
parser.add_argument(
    "-f",
    "--framerate",
    type=int,
    default=60,
    help="Framerate to be used by cava, default is 60",
)
parser.add_argument(
    "-b", "--bars", type=int, default=8, help="Amount of bars, default is 8"
)
parser.add_argument(
    "-c",
    "--channels",
    choices=["stereo", "left", "right", "average"],
    default="stereo",
    help="Audio channels to be used, defaults to stereo",
)
parser.add_argument(
    "-s",
    "--style",
    choices=[
        "classic",
        "blocks",
        "waves",
        "circles",
        "arrows",
        "stars",
        "hearts",
        "bars",
        "dots",
        "petals",
        "braille",
        "custom",
    ],
    default="petals",
    help="Visual style for the bars, defaults to blocks",
)
parser.add_argument(
    "--chars", default="", help='Custom characters for the "custom" style'
)
parser.add_argument(
    "--palette",
    choices=sorted(PALETTES.keys()),
    default="sakura",
    help="Color palette for the bars",
)

opts = parser.parse_args()

conf_channels = ""
if opts.channels != "stereo":
    conf_channels = "channels=mono\n" f"mono_option={opts.channels}"

ramp_list = build_ramp_list(opts.style, opts.chars)
conf_ascii_max_range = max(len(ramp_list) - 1, 1)
cava_conf = tempfile.mkstemp("", "polybar-cava-conf.")[1]
with open(cava_conf, "w") as cava_conf_file:
    cava_conf_file.write(
        "[general]\n"
        f"framerate={opts.framerate}\n"
        f"bars={opts.bars}\n"
        "[input]\n"
        "method = pulse\n"
        "source = auto\n"
        "[output]\n"
        "method=raw\n"
        "data_format=ascii\n"
        f"ascii_max_range={conf_ascii_max_range}\n"
        "bar_delimiter=32\n" + conf_channels
    )

try:
    cava_proc = subprocess.Popen(["cava", "-p", cava_conf], stdout=subprocess.PIPE, text=True)
    # Ensure __file__ is absolute
    script_path = os.path.abspath(__file__)
    self_proc = subprocess.Popen(
        [
            sys.executable,
            script_path,
            "--subproc",
            opts.style,
            opts.chars,
            opts.palette,
        ],
        stdin=cava_proc.stdout,
    )

    signal.signal(signal.SIGTERM, cleanup)
    signal.signal(signal.SIGINT, cleanup)

    self_proc.wait()
finally:
    cleanup(None, None)
