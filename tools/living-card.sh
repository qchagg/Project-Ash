#!/usr/bin/env bash
# Turns a portrait loop (an MP4 with a flat background) into the three living-card files:
#   <name>-live.webm     animated cutout with transparency, ping-pong loop (4★ break-out, cut-ins)
#   <name>-breathe.webm  animated with its background, ping-pong loop (3★ breathing card)
#   <name>-cutout.webp   still transparent cutout from the first frame (fallback, posters)
# Needs ffmpeg with libvpx-vp9 and Python with rembg: pip install "rembg[cpu]"
# Usage: tools/living-card.sh path/to/loop.mp4 ilse art/ilse
set -euo pipefail
src="$1"; name="$2"; out="$3"
work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT
mkdir -p "$out" "$work/frames" "$work/cut"

ffmpeg -loglevel error -y -i "$src" "$work/frames/%04d.png"

# isnet-anime keeps hair strands that a colour key or a general model loses.
python3 - "$work/frames" "$work/cut" <<'EOF'
import os, sys
from PIL import Image
from rembg import remove, new_session
session = new_session('isnet-anime')
src, dst = sys.argv[1], sys.argv[2]
for f in sorted(os.listdir(src)):
    remove(Image.open(os.path.join(src, f)).convert('RGB'), session=session).save(os.path.join(dst, f))
EOF

# Most generated loops do not end where they start, so play forward then backward for a seamless loop.
pingpong="[0]split[a][b];[b]reverse,trim=start_frame=1,setpts=PTS-STARTPTS[r];[a][r]concat=n=2:v=1"
fps="$(ffprobe -v error -select_streams v -show_entries stream=r_frame_rate -of csv=p=0 "$src")"
ffmpeg -loglevel error -y -framerate "$fps" -i "$work/cut/%04d.png" -filter_complex "$pingpong,format=yuva420p" \
  -c:v libvpx-vp9 -pix_fmt yuva420p -b:v 0 -crf 38 -row-mt 1 -an "$out/$name-live.webm"
ffmpeg -loglevel error -y -i "$src" -filter_complex "$pingpong" -c:v libvpx-vp9 -b:v 0 -crf 40 -row-mt 1 -an "$out/$name-breathe.webm"
python3 -c "from PIL import Image; Image.open('$work/cut/0001.png').save('$out/$name-cutout.webp', quality=88, method=6)"
ls -la "$out"
