#!/usr/bin/env bash

set -euo pipefail

readonly DIR="$1"
readonly DARKTABLE_STYLE="linear"

pushd "$DIR" > /dev/null

echo "=== Clean Old Files ==="
rm -fv *.tif

echo "=== RAF -> TIFF ==="
for f_raf in *.RAF; do
    base="$(basename "$f_raf" .RAF)"
    f_tif="${base}_converted.tif"
    echo "$f_raf -> $f_tif"
    darktable-cli \
        "$f_raf" "$f_tif" \
        --style "$DARKTABLE_STYLE" \
        --core \
        --configdir ~/.config/darktable \
        --conf "plugins/imageio/format/tiff/bpp=32"
done

echo "=== Align Images ==="
align_image_stack \
    -a aligned_ \
    -C \
    --cor=0.95 \
    -v \
    *_converted.tif
