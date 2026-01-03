#!/usr/bin/env python3

import argparse
import os
import signal
import subprocess
import sys
import tempfile


# Hardcoded Kanagawa theme colors
KANAGAWA_COLORS = [
    "7E9CD8",
    "957FB8",
    "D27E99",
    "C8C093",
    "E46876",
    "76946A",
    "E6C384",
    "FFA066",
]


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

    if style == "dots":
        ramp_list = [" ", "·", "•", "●", "○", "◎", "◉", "⬤"]
    elif style == "braille":
        # Centered expansion: middle -> middle-block -> full-bottom -> full
        ramp_list = [" ", "⠒", "⠖", "⠶", "⡶", "⣶", "⣾", "⣿"]
    elif style == "blocks":
        ramp_list = [" ", "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"]
    elif style == "waves":
        # Wave emoji pattern
        ramp_list = [" ", "🌊", "🌊", "🌊", "🌊", "🌊", "🌊", "🌊", "🌊"]
    elif style == "circles":
        # Circle emoji pattern
        ramp_list = [" ", "⚪", "⚪", "⚫", "⚫", "⚫", "⚫", "⚫", "⚫"]
    elif style == "arrows":
        ramp_list = [" ", "↑", "↗", "→", "↘", "↓", "↙", "←", "↖"]
    elif style == "stars":
        # Star emoji pattern
        ramp_list = [" ", "⭐", "⭐", "🌟", "🌟", "🌟", "🌟", "🌟", "🌟"]
    elif style == "hearts":
        # Heart emoji pattern
        ramp_list = [" ", "💙", "💜", "💗", "💗", "💗", "💗", "💗", "💗"]
    elif style == "bars":
        ramp_list = [" ", "│", "│", "┃", "┃", "┃", "┃", "┃", "┃"]
    elif style == "points":
        # Dot emoji pattern
        ramp_list = [" ", "🔹", "🔹", "🔷", "🔷", "🔷", "🔷", "🔷", "🔷"]
    elif style == "custom":
        ramp_list = (
            [" "] + list(sys.argv[3])
            if len(sys.argv) > 3
            else [" ", "▏", "▎", "▍", "▌", "▋", "▊", "▉"]
        )
    else:
        ramp_list = [" ", "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"]  # Default to blocks

    # Use hardcoded Kanagawa colors
    colors = KANAGAWA_COLORS

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
        "braille",
        "custom",
    ],
    default="blocks",
    help="Visual style for the bars, defaults to blocks",
)
parser.add_argument(
    "--chars", default="", help='Custom characters for the "custom" style'
)

opts = parser.parse_args()

conf_channels = ""
if opts.channels != "stereo":
    conf_channels = "channels=mono\n" f"mono_option={opts.channels}"

conf_ascii_max_range = 8 + len(KANAGAWA_COLORS)
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
        [sys.executable, script_path, "--subproc", opts.style],
        stdin=cava_proc.stdout,
    )

    signal.signal(signal.SIGTERM, cleanup)
    signal.signal(signal.SIGINT, cleanup)

    self_proc.wait()
finally:
    cleanup(None, None)
