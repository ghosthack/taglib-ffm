# tools/

Not committed. `jextract/gen-bindings.sh` first reuses the jextract 22 install
from `../ffmpeg-ffm/tools/jextract-22` when available, or expects it here as
`tools/jextract-22`:

```sh
mkdir -p tools
curl -sfL https://download.java.net/java/early_access/jextract/22/6/openjdk-22-jextract+6-47_macos-aarch64_bin.tar.gz | tar xz -C tools/
```

jextract 22 targets the finalized FFM API, so its output compiles on every
JDK 22 or newer.
