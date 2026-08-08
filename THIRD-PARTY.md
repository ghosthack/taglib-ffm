# Third-party notices

## TagLib

The `taglib-ffm-natives` classifier jars contain shared libraries built from
**unmodified TagLib source** (https://taglib.org), dual-licensed under the
**Mozilla Public License 2.0** or the **GNU Lesser General Public License 2.1**.

- Both license texts ship in each classifier jar as `COPYING.MPL` and
  `COPYING.LGPL`.
- Corresponding source is available from
  `https://taglib.org/releases/taglib-<version>.tar.gz`; the exact version is
  recorded in `BUILD-INFO.txt`.
- Libraries are dynamically loaded and user-replaceable. Set
  `TAGLIB_FFM_LIBDIR` or `-Dtaglibffm.libdir` to select compatible replacement
  libraries.

## utfcpp

TagLib includes the header-only utfcpp library, licensed under the Boost
Software License 1.0. Its license ships as `LICENSE.utf8cpp` in each native
classifier jar.

The Java binding and loader code contains no TagLib source and is MIT licensed.
