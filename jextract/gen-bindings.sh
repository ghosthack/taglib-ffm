#!/bin/sh
# Generate the complete portable TagLib C API and point its symbol lookup at
# the runtime loader. Run after build-natives/macos-arm64.sh.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
JX="$ROOT/tools/jextract-22/bin/jextract"
if [ ! -x "$JX" ] && [ -x "$ROOT/../ffmpeg-ffm/tools/jextract-22/bin/jextract" ]; then
  JX="$ROOT/../ffmpeg-ffm/tools/jextract-22/bin/jextract"
fi
PREFIX="$ROOT/build/prefix-macos-arm64"
OUT="$ROOT/core/src/main/java"
PKG="io.github.ghosthack.taglibffm.taglib"
SDK="$(xcrun --show-sdk-path)"

[ -x "$JX" ] || { echo "jextract 22 not found; see tools/README.md"; exit 1; }
[ -f "$PREFIX/include/taglib/tag_c.h" ] || { echo "run build-natives/macos-arm64.sh first"; exit 1; }

GEN_DIR="$OUT/$(echo "$PKG" | tr . /)"
if [ -d "$GEN_DIR" ]; then
  find "$GEN_DIR" -type f -delete
fi
mkdir -p "$GEN_DIR"

"$JX" --output "$OUT" -t "$PKG" \
  --header-class-name TagLib \
  -I "$SDK/usr/include" \
  -I "$PREFIX/include/taglib" \
  -l ":$PREFIX/lib/libtag.2.3.1.dylib" \
  -l ":$PREFIX/lib/libtag_c.2.3.1.dylib" \
  --include-function taglib_set_strings_unicode \
  --include-function taglib_set_string_management_enabled \
  --include-function taglib_free \
  --include-function taglib_memory_iostream_new \
  --include-function taglib_iostream_free \
  --include-function taglib_file_new \
  --include-function taglib_file_new_wchar \
  --include-function taglib_file_new_type \
  --include-function taglib_file_new_type_wchar \
  --include-function taglib_file_new_iostream \
  --include-function taglib_file_free \
  --include-function taglib_file_is_valid \
  --include-function taglib_file_tag \
  --include-function taglib_file_audioproperties \
  --include-function taglib_file_save \
  --include-function taglib_tag_title \
  --include-function taglib_tag_artist \
  --include-function taglib_tag_album \
  --include-function taglib_tag_comment \
  --include-function taglib_tag_genre \
  --include-function taglib_tag_year \
  --include-function taglib_tag_track \
  --include-function taglib_tag_set_title \
  --include-function taglib_tag_set_artist \
  --include-function taglib_tag_set_album \
  --include-function taglib_tag_set_comment \
  --include-function taglib_tag_set_genre \
  --include-function taglib_tag_set_year \
  --include-function taglib_tag_set_track \
  --include-function taglib_tag_free_strings \
  --include-function taglib_audioproperties_length \
  --include-function taglib_audioproperties_bitrate \
  --include-function taglib_audioproperties_samplerate \
  --include-function taglib_audioproperties_channels \
  --include-function taglib_id3v2_set_default_text_encoding \
  --include-function taglib_property_set \
  --include-function taglib_property_set_append \
  --include-function taglib_property_keys \
  --include-function taglib_property_get \
  --include-function taglib_property_free \
  --include-function taglib_complex_property_set \
  --include-function taglib_complex_property_set_append \
  --include-function taglib_complex_property_keys \
  --include-function taglib_complex_property_get \
  --include-function taglib_picture_from_complex_property \
  --include-function taglib_complex_property_free_keys \
  --include-function taglib_complex_property_free \
  --include-typedef TagLib_File \
  --include-typedef TagLib_Tag \
  --include-typedef TagLib_AudioProperties \
  --include-typedef TagLib_IOStream \
  --include-typedef TagLib_File_Type \
  --include-typedef TagLib_ID3v2_Encoding \
  --include-typedef TagLib_Variant_Type \
  --include-typedef TagLib_Variant \
  --include-typedef TagLib_Complex_Property_Attribute \
  --include-typedef TagLib_Complex_Property_Picture_Data \
  --include-constant TagLib_File_MPEG \
  --include-constant TagLib_File_OggVorbis \
  --include-constant TagLib_File_FLAC \
  --include-constant TagLib_File_MPC \
  --include-constant TagLib_File_OggFlac \
  --include-constant TagLib_File_WavPack \
  --include-constant TagLib_File_Speex \
  --include-constant TagLib_File_TrueAudio \
  --include-constant TagLib_File_MP4 \
  --include-constant TagLib_File_ASF \
  --include-constant TagLib_File_AIFF \
  --include-constant TagLib_File_WAV \
  --include-constant TagLib_File_APE \
  --include-constant TagLib_File_IT \
  --include-constant TagLib_File_Mod \
  --include-constant TagLib_File_S3M \
  --include-constant TagLib_File_XM \
  --include-constant TagLib_File_Opus \
  --include-constant TagLib_File_DSF \
  --include-constant TagLib_File_DSDIFF \
  --include-constant TagLib_File_SHORTEN \
  --include-constant TagLib_File_MATROSKA \
  --include-constant TagLib_ID3v2_Latin1 \
  --include-constant TagLib_ID3v2_UTF16 \
  --include-constant TagLib_ID3v2_UTF16BE \
  --include-constant TagLib_ID3v2_UTF8 \
  --include-constant TagLib_Variant_Void \
  --include-constant TagLib_Variant_Bool \
  --include-constant TagLib_Variant_Int \
  --include-constant TagLib_Variant_UInt \
  --include-constant TagLib_Variant_LongLong \
  --include-constant TagLib_Variant_ULongLong \
  --include-constant TagLib_Variant_Double \
  --include-constant TagLib_Variant_String \
  --include-constant TagLib_Variant_StringList \
  --include-constant TagLib_Variant_ByteVector \
  "$ROOT/jextract/taglib_api.h"

perl -0777 -pi -e \
  's/static final SymbolLookup SYMBOL_LOOKUP = .*?;/static final SymbolLookup SYMBOL_LOOKUP = io.github.ghosthack.taglibffm.TagLibLibs.lookup();/s' \
  "$GEN_DIR/TagLib.java"
perl -0777 -pi -e 's/\n+\z/\n/' "$GEN_DIR"/*.java

if grep -rn "$PREFIX" "$GEN_DIR" >/dev/null; then
  echo "ERROR: build-prefix paths survived in generated stubs"; exit 1
fi
grep -q "TagLibLibs.lookup()" "$GEN_DIR/TagLib.java" || { echo "ERROR: lookup patch did not apply"; exit 1; }

echo "Generated $(find "$GEN_DIR" -type f | wc -l | tr -d ' ') files into $GEN_DIR"
