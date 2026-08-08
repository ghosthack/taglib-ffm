#!/bin/sh
# Build unmodified TagLib with its C binding and stage relocatable dylibs.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${1:-$ROOT/build/taglib-2.3.1}"
BUILD="$ROOT/build/taglib-macos-arm64"
PREFIX="$ROOT/build/prefix-macos-arm64"
DEST="$ROOT/natives/src/main/resources/natives/macos-arm64"
VERSION="$(sed -En 's/^#define TAGLIB_(MAJOR|MINOR|PATCH)_VERSION[[:space:]]+([0-9]+).*/\2/p' "$SRC/taglib/toolkit/taglib.h" | paste -sd . -)"

cmake -S "$SRC" -B "$BUILD" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON \
  -DBUILD_TESTING=OFF -DBUILD_EXAMPLES=OFF -DBUILD_BINDINGS=ON \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_INSTALL_LIBDIR=lib
cmake --build "$BUILD" --parallel "$(sysctl -n hw.ncpu)"
cmake --install "$BUILD"

if [ -d "$DEST" ]; then
  find "$DEST" -type f -delete
else
  mkdir -p "$DEST"
fi

cp "$PREFIX/lib/libtag.$VERSION.dylib" "$DEST/libtag.2.dylib"
cp "$PREFIX/lib/libtag_c.$VERSION.dylib" "$DEST/libtag_c.2.dylib"
chmod 644 "$DEST"/*.dylib
install_name_tool -id '@loader_path/libtag.2.dylib' "$DEST/libtag.2.dylib"
install_name_tool -id '@loader_path/libtag_c.2.dylib' "$DEST/libtag_c.2.dylib"
install_name_tool -change "$PREFIX/lib/libtag.2.dylib" '@loader_path/libtag.2.dylib' "$DEST/libtag_c.2.dylib"

for library in "$DEST"/*.dylib; do
  if otool -L "$library" | tail -n +2 | grep -vE '@loader_path/|/usr/lib/|/System/Library/'; then
    echo "ERROR: $library has non-relocatable dependencies (above)"; exit 1
  fi
done

printf '%s\n' libtag.2.dylib libtag_c.2.dylib > "$DEST/manifest.txt"
cp "$SRC/COPYING.MPL" "$DEST/COPYING.MPL"
cp "$SRC/COPYING.LGPL" "$DEST/COPYING.LGPL"
cp "$SRC/3rdparty/utfcpp/LICENSE" "$DEST/LICENSE.utf8cpp"
{
  echo "TagLib $VERSION (macos-arm64), built from unmodified source"
  echo "Source: https://taglib.org/releases/taglib-$VERSION.tar.gz"
  echo "License: MPL-2.0 or LGPL-2.1 (see COPYING.MPL and COPYING.LGPL)"
  echo "Bundled header-only dependency: utfcpp (Boost Software License; see LICENSE.utf8cpp)"
  echo "CMake: BUILD_SHARED_LIBS=ON, BUILD_BINDINGS=ON, all formats enabled"
} > "$DEST/BUILD-INFO.txt"

echo "Staged $(find "$DEST" -type f | wc -l | tr -d ' ') files into $DEST"
