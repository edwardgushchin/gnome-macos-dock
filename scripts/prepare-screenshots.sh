#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
source "$ROOT_DIR/scripts/lib.sh"

(($# == 1)) || die "Usage: scripts/prepare-screenshots.sh INPUT.png"
require_command magick

source_image=$(realpath -e "$1")
asset_dir="$ROOT_DIR/assets/screenshots"
install -d -m 0755 "$asset_dir"

dimensions=$(magick identify -format '%wx%h' "$source_image")
[[ "$dimensions" == 1920x1080 ]] ||
    die "Expected a 1920x1080 reference screenshot, got $dimensions"

magick "$source_image" -strip \
    +set date:create +set date:modify +set date:timestamp \
    -define png:exclude-chunks=date,time -define png:compression-level=9 \
    "$asset_dir/desktop-preview.png"
magick "$source_image" -crop 1040x150+440+930 +repage -strip \
    +set date:create +set date:modify +set date:timestamp \
    -define png:exclude-chunks=date,time -define png:compression-level=9 \
    "$asset_dir/dock-close-up.png"
magick -size 1280x640 xc:'#15141b' \
    \( "$source_image" -strip -resize 1120x630 \) \
    -gravity center -composite -strip \
    +set date:create +set date:modify +set date:timestamp \
    -define png:exclude-chunks=date,time -define png:compression-level=9 \
    "$asset_dir/social-preview.png"

chmod 0644 "$asset_dir"/*.png
success "README and social preview images updated"
