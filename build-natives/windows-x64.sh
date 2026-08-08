#!/bin/sh
# Build TagLib on MSYS2 MINGW64 and stage it with its MinGW runtime DLLs.
# Prerequisites:
#   pacman -S --needed mingw-w64-x86_64-toolchain mingw-w64-x86_64-cmake \
#     mingw-w64-x86_64-ninja mingw-w64-x86_64-zlib
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${1:-$ROOT/build/taglib-2.3.1}"
BUILD="$ROOT/build/taglib-windows-x64"
PREFIX="$ROOT/build/prefix-windows-x64"
DEST="$ROOT/natives/src/main/resources/natives/windows-x64"
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
: > "$DEST/manifest.txt"

for runtime in libwinpthread-1.dll libgcc_s_seh-1.dll libstdc++-6.dll zlib1.dll; do
  if [ -f "/mingw64/bin/$runtime" ]; then
    cp "/mingw64/bin/$runtime" "$DEST/$runtime"
    echo "$runtime" >> "$DEST/manifest.txt"
  fi
done

TAG_DLL="$(find "$PREFIX/bin" -maxdepth 1 -type f -iname '*tag.dll' ! -iname '*tag_c.dll' | head -1)"
TAG_C_DLL="$(find "$PREFIX/bin" -maxdepth 1 -type f -iname '*tag_c.dll' | head -1)"
[ -n "$TAG_DLL" ] && [ -n "$TAG_C_DLL" ] || { echo "TagLib DLLs not found in $PREFIX/bin"; exit 1; }
cp "$TAG_DLL" "$DEST/$(basename "$TAG_DLL")"
cp "$TAG_C_DLL" "$DEST/$(basename "$TAG_C_DLL")"
echo "$(basename "$TAG_DLL")" >> "$DEST/manifest.txt"
echo "$(basename "$TAG_C_DLL")" >> "$DEST/manifest.txt"

ALLOWED='tag|tag_c|libwinpthread|libgcc_s_seh|libstdc\+\+|zlib1|KERNEL32|USER32|ADVAPI32|SHELL32|ole32|OLEAUT32|SHLWAPI|bcrypt|msvcrt|ntdll|api-ms-|VCRUNTIME|ucrtbase'
for library in "$DEST"/*.dll; do
  if objdump -p "$library" | awk '/DLL Name:/{print $3}' | grep -viE "^($ALLOWED)"; then
    echo "ERROR: $library imports from unexpected DLLs (above)"; exit 1
  fi
done

cp "$SRC/COPYING.MPL" "$DEST/COPYING.MPL"
cp "$SRC/COPYING.LGPL" "$DEST/COPYING.LGPL"
cp "$SRC/3rdparty/utfcpp/LICENSE" "$DEST/LICENSE.utf8cpp"
{
  echo "TagLib $VERSION (windows-x64), built from unmodified source with MSYS2 mingw-w64"
  echo "Source: https://taglib.org/releases/taglib-$VERSION.tar.gz"
  echo "License: MPL-2.0 or LGPL-2.1 (see COPYING.MPL and COPYING.LGPL)"
  echo "Bundled header-only dependency: utfcpp (Boost Software License; see LICENSE.utf8cpp)"
  echo "CMake: BUILD_SHARED_LIBS=ON, BUILD_BINDINGS=ON, all formats enabled"
} > "$DEST/BUILD-INFO.txt"

echo "Staged $(find "$DEST" -type f | wc -l | tr -d ' ') files into $DEST"
