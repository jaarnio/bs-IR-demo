#!/usr/bin/env bash
# Generates the 15 demo clips in app/videos/ (1920x1080, 30 fps, 12 s, H.265, no audio).
# Each clip shows its item number on a panel in the same color as its menu box.
# Background cycles through: solid color + sweeping bar, testsrc2, SMPTE HD bars.
#
# Requires ffmpeg built with libx265 and libfreetype (drawtext).
# Usage: tools/make-videos.sh   (run from the repo root)
set -euo pipefail

# Keep in sync with boxColors in app/assets.js
COLORS=(bd2828 bd6428 bda028 a0bd28 64bd28 28bd28 28bd64 28bda0 28a0bd 2864bd 2828bd 6428bd a028bd bd28a0 bd2864)
FONT="${FONT:-/System/Library/Fonts/Supplemental/Arial Bold.ttf}"
DUR=12
OUT=app/videos

mkdir -p "$OUT"

for i in $(seq 1 15); do
  n=$(printf "%02d" "$i")
  c="0x${COLORS[$((i - 1))]}"

  case $((i % 3)) in
    1) bg="color=c=${c}:s=1920x1080:r=30:d=${DUR}" ;;
    2) bg="testsrc2=s=1920x1080:r=30:d=${DUR}" ;;
    0) bg="smptehdbars=s=1920x1080:r=30:d=${DUR}" ;;
  esac

  ffmpeg -hide_banner -loglevel error -y \
    -f lavfi -i "$bg" \
    -f lavfi -i "color=c=white:s=160x1080:r=30:d=${DUR}" \
    -f lavfi -i "color=c=white:s=1920x16:r=30:d=${DUR}" \
    -filter_complex "
      [1]format=rgba,colorchannelmixer=aa=0.35[sweep];
      [0][sweep]overlay=x='mod(t*480,W+w)-w':y=0[a];
      [a][2]overlay=x='-w+w*t/${DUR}':y=H-h[b];
      [b]drawbox=x=(iw-720)/2:y=(ih-560)/2:w=720:h=560:color=${c}:t=fill,
         drawbox=x=(iw-720)/2:y=(ih-560)/2:w=720:h=560:color=white:t=10,
         drawtext=fontfile='${FONT}':text='${n}':fontsize=380:fontcolor=white:
           x=(w-text_w)/2:y=(h-text_h)/2-30:shadowcolor=black@0.5:shadowx=6:shadowy=6,
         drawtext=fontfile='${FONT}':text='ITEM ${n}':fontsize=48:fontcolor=white:
           x=(w-text_w)/2:y=(h+560)/2-90,
         drawtext=fontfile='${FONT}':text='%{pts\:hms}':fontsize=36:fontcolor=white:
           x=w-text_w-40:y=h-text_h-40:box=1:boxcolor=black@0.5:boxborderw=10,
         format=yuv420p[v]" \
    -map "[v]" -an \
    -c:v libx265 -preset slow -crf 30 -tag:v hvc1 -x265-params log-level=error \
    -movflags +faststart \
    "$OUT/item${n}.mp4"

  echo "$OUT/item${n}.mp4"
done
