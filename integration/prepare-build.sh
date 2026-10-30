#!/usr/bin/env bash
# Assemble the same tree described by README 5.2; use the original image builders.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(realpath -m -- "${1:-$ROOT/.build/ios165}")"
case "$WORK" in
    "$ROOT"|"$ROOT/src"|"$ROOT/src/"*|"$ROOT/boot"|"$ROOT/boot/"*)
        echo "Choose a separate generated build directory." >&2; exit 1 ;;
esac
if [ -d "$WORK" ] && [ ! -f "$WORK/.ios-alioth-build-tree" ] && [ -n "$(ls -A "$WORK")" ]; then
    echo "Refusing to overwrite an unrelated directory: $WORK" >&2; exit 1
fi
mkdir -p "$WORK"
printf '%s\n' "$ROOT" > "$WORK/.ios-alioth-build-tree"
cp -a --reflink=auto "$ROOT/src/hackios-xnu-kernel-main/." "$WORK/"
for name in ios165 userland prebuilt; do
    cp -a --reflink=auto "$ROOT/src/hackios-xnu-userland-main/$name" "$WORK/"
done
cp -a --reflink=auto "$ROOT/src/hackios-xnu-userland-main/tools/." "$WORK/tools/"
printf 'Prepared existing upstream build scripts at %s\n' "$WORK"
