#!/bin/sh
# Build unmodified TagLib with its C binding and stage relocatable ELF libs.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${1:-$ROOT/build/taglib-2.3.1}"
BUILD="$ROOT/build/taglib-linux-x64"
PREFIX="$ROOT/build/prefix-linux-x64"
DEST="$ROOT/natives/src/main/resources/natives/linux-x64"
VERSION="$(sed -En 's/^#define TAGLIB_(MAJOR|MINOR|PATCH)_VERSION[[:space:]]+([0-9]+).*/\2/p' "$SRC/taglib/toolkit/taglib.h" | paste -sd . -)"

cmake -S "$SRC" -B "$BUILD" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON \
  -DBUILD_TESTING=OFF -DBUILD_EXAMPLES=OFF -DBUILD_BINDINGS=ON \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_INSTALL_LIBDIR=lib
cmake --build "$BUILD" --parallel "$(nproc)"
cmake --install "$BUILD"

if [ -d "$DEST" ]; then
  find "$DEST" -type f -delete
else
  mkdir -p "$DEST"
fi

cp "$PREFIX/lib/libtag.so.$VERSION" "$DEST/libtag.so.2"
cp "$PREFIX/lib/libtag_c.so.$VERSION" "$DEST/libtag_c.so.2"
chmod 644 "$DEST"/*.so.*
patchelf --set-soname libtag.so.2 --set-rpath '$ORIGIN' "$DEST/libtag.so.2"
patchelf --set-soname libtag_c.so.2 --set-rpath '$ORIGIN' "$DEST/libtag_c.so.2"

for library in "$DEST"/*.so.*; do
  if readelf -d "$library" | awk '/NEEDED/ {print $NF}' | tr -d '[]' \
      | grep -vE '^(libtag|libstdc\+\+|libgcc_s|libz|libm|libc|libpthread|libdl|librt)\.so|^ld-linux'; then
    echo "ERROR: $library has non-relocatable dependencies (above)"; exit 1
  fi
done

printf '%s\n' libtag.so.2 libtag_c.so.2 > "$DEST/manifest.txt"
cp "$SRC/COPYING.MPL" "$DEST/COPYING.MPL"
cp "$SRC/COPYING.LGPL" "$DEST/COPYING.LGPL"
cp "$SRC/3rdparty/utfcpp/LICENSE" "$DEST/LICENSE.utf8cpp"
{
  echo "TagLib $VERSION (linux-x64), built from unmodified source"
  echo "Source: https://taglib.org/releases/taglib-$VERSION.tar.gz"
  echo "License: MPL-2.0 or LGPL-2.1 (see COPYING.MPL and COPYING.LGPL)"
  echo "Bundled header-only dependency: utfcpp (Boost Software License; see LICENSE.utf8cpp)"
  echo "CMake: BUILD_SHARED_LIBS=ON, BUILD_BINDINGS=ON, all formats enabled"
} > "$DEST/BUILD-INFO.txt"

echo "Staged $(find "$DEST" -type f | wc -l | tr -d ' ') files into $DEST"
