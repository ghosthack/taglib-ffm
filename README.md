# taglib-ffm

Panama FFM (jextract) bindings for TagLib with bundled, from-source native
libraries. One Maven coordinate, no JNI and no user-installed TagLib.

| Artifact | Contents | License |
|---|---|---|
| `io.github.ghosthack:taglib-ffm` | Complete portable TagLib C API + runtime loader (pure Java, JDK 22+) | MIT |
| `io.github.ghosthack:taglib-ffm-natives` (`macos-arm64`, `windows-x64`, `linux-x64`) | Unmodified TagLib 2.3.1 shared libraries | MPL 2.0 or LGPL 2.1 |

The generated surface covers files, simple tags, audio properties, textual
property maps, complex properties (including cover art), memory streams, all
public C enums/structures, and the Windows-only `wchar_t` filename constructors.
Those two methods should only be called on Windows, with a native UTF-16 buffer.

## Use

```xml
<dependency>
  <groupId>io.github.ghosthack</groupId>
  <artifactId>taglib-ffm</artifactId>
  <version>2.3.1-0.1.0-SNAPSHOT</version>
</dependency>
<dependency>
  <groupId>io.github.ghosthack</groupId>
  <artifactId>taglib-ffm-natives</artifactId>
  <version>2.3.1-0.1.0-SNAPSHOT</version>
  <classifier>macos-arm64</classifier> <!-- or windows-x64 / linux-x64 -->
  <scope>runtime</scope>
</dependency>
```

On the module path, declare `requires taglib.ffm;` and run with
`--enable-native-access=taglib.ffm`. On the class path, use
`--enable-native-access=ALL-UNNAMED`.

```java
import io.github.ghosthack.taglibffm.taglib.TagLib;
import java.lang.foreign.Arena;
import java.lang.foreign.MemorySegment;

try (Arena arena = Arena.ofConfined()) {
    MemorySegment file = TagLib.taglib_file_new(arena.allocateFrom("song.flac"));
    if (file.equals(MemorySegment.NULL)) {
        throw new IllegalArgumentException("unsupported or unreadable file");
    }
    try {
        MemorySegment tag = TagLib.taglib_file_tag(file);
        String title = TagLib.taglib_tag_title(tag).reinterpret(4096).getString(0);
        TagLib.taglib_tag_set_title(tag, arena.allocateFrom("New title"));
        if (TagLib.taglib_file_save(file) == 0) {
            throw new IllegalStateException("save failed");
        }
    } finally {
        TagLib.taglib_file_free(file);
        TagLib.taglib_tag_free_strings();
    }
}
```

`core/src/test/java/io/github/ghosthack/taglibffm/SmokeTest.java` demonstrates
file and memory-stream parsing, audio properties, Unicode tag writing, and the
property-map API.

### Library resolution

1. `-Dtaglibffm.libdir=<dir>` or `TAGLIB_FFM_LIBDIR` uses an existing compatible
   TagLib installation;
2. bundled natives extract once to
   `~/.cache/taglib-ffm/<artifact-version>-<platform>/`;
3. symbols already loaded by the host process are used as a fallback.

The explicit directory is also the native-library substitution mechanism for
applications choosing TagLib's LGPL license.

## Build

Fetch the matching unmodified source archive first:

```sh
mkdir -p build
curl -sfL https://taglib.org/releases/taglib-2.3.1.tar.gz | tar xz -C build
```

Then on macOS arm64:

```sh
build-natives/macos-arm64.sh
jextract/gen-bindings.sh
mvn clean install
```

The Linux and Windows scripts build and stage their platform libraries in the
same way. Their prerequisite packages are documented in the script headers and
CI workflow. Generated bindings are checked in; jextract is only required when
regenerating them. Native staging directories are build outputs and are not
committed.
