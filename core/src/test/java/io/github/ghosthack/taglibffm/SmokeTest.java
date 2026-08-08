package io.github.ghosthack.taglibffm;

import io.github.ghosthack.taglibffm.taglib.TagLib;
import org.junit.jupiter.api.Test;

import java.lang.foreign.Arena;
import java.lang.foreign.MemorySegment;
import java.lang.foreign.ValueLayout;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** End-to-end checks for bundled native loading, metadata, properties and memory I/O. */
class SmokeTest {

    @Test
    void readsAudioPropertiesFromMemory() {
        byte[] wav = silentWav();
        try (Arena arena = Arena.ofConfined()) {
            MemorySegment bytes = arena.allocateFrom(ValueLayout.JAVA_BYTE, wav);
            MemorySegment stream = TagLib.taglib_memory_iostream_new(bytes, wav.length);
            assertNotEquals(MemorySegment.NULL, stream);
            try {
                MemorySegment file = TagLib.taglib_file_new_iostream(stream);
                assertNotEquals(MemorySegment.NULL, file);
                try {
                    assertEquals(1, TagLib.taglib_file_is_valid(file));
                    MemorySegment properties = TagLib.taglib_file_audioproperties(file);
                    assertNotEquals(MemorySegment.NULL, properties);
                    assertEquals(1, TagLib.taglib_audioproperties_length(properties));
                    assertEquals(8_000, TagLib.taglib_audioproperties_samplerate(properties));
                    assertEquals(1, TagLib.taglib_audioproperties_channels(properties));
                    assertEquals(64, TagLib.taglib_audioproperties_bitrate(properties));
                } finally {
                    TagLib.taglib_file_free(file);
                }
            } finally {
                TagLib.taglib_iostream_free(stream);
            }
        }
    }

    @Test
    void writesAndReopensUnicodeMetadataAndProperties() throws Exception {
        Path fixture = Files.createTempFile("taglib-ffm-sample", ".wav");
        Files.write(fixture, silentWav());
        try {
            try (Arena arena = Arena.ofConfined()) {
                MemorySegment file = TagLib.taglib_file_new(arena.allocateFrom(fixture.toString()));
                assertNotEquals(MemorySegment.NULL, file);
                try {
                    MemorySegment tag = TagLib.taglib_file_tag(file);
                    assertNotEquals(MemorySegment.NULL, tag);
                    TagLib.taglib_tag_set_title(tag, arena.allocateFrom("Jóga"));
                    TagLib.taglib_tag_set_artist(tag, arena.allocateFrom("Björk"));
                    TagLib.taglib_tag_set_album(tag, arena.allocateFrom("Homogenic"));
                    TagLib.taglib_tag_set_year(tag, 1997);
                    TagLib.taglib_tag_set_track(tag, 5);

                    TagLib.taglib_property_set(file, arena.allocateFrom("COMMENT"),
                            arena.allocateFrom("FFM smoke test"));
                    MemorySegment comments = TagLib.taglib_property_get(file, arena.allocateFrom("COMMENT"));
                    assertNotEquals(MemorySegment.NULL, comments);
                    try {
                        assertEquals("FFM smoke test", firstString(comments));
                    } finally {
                        TagLib.taglib_property_free(comments);
                    }
                    assertEquals(1, TagLib.taglib_file_save(file));
                } finally {
                    TagLib.taglib_file_free(file);
                }
            }

            try (Arena arena = Arena.ofConfined()) {
                MemorySegment file = TagLib.taglib_file_new_type(arena.allocateFrom(fixture.toString()),
                        TagLib.TagLib_File_WAV());
                assertNotEquals(MemorySegment.NULL, file);
                try {
                    MemorySegment tag = TagLib.taglib_file_tag(file);
                    assertEquals("Jóga", string(TagLib.taglib_tag_title(tag)));
                    assertEquals("Björk", string(TagLib.taglib_tag_artist(tag)));
                    assertEquals("Homogenic", string(TagLib.taglib_tag_album(tag)));
                    assertEquals(1997, TagLib.taglib_tag_year(tag));
                    assertEquals(5, TagLib.taglib_tag_track(tag));
                    assertTrue(Files.size(fixture) > silentWav().length, "metadata was appended to the WAV");
                } finally {
                    TagLib.taglib_file_free(file);
                    TagLib.taglib_tag_free_strings();
                }
            }
        } finally {
            Files.deleteIfExists(fixture);
        }
    }

    private static String firstString(MemorySegment array) {
        MemorySegment first = array.reinterpret(ValueLayout.ADDRESS.byteSize())
                .get(ValueLayout.ADDRESS, 0);
        return string(first);
    }

    private static String string(MemorySegment pointer) {
        assertNotEquals(MemorySegment.NULL, pointer);
        return pointer.reinterpret(4_096).getString(0);
    }

    private static byte[] silentWav() {
        int sampleRate = 8_000;
        int dataSize = sampleRate;
        ByteBuffer buffer = ByteBuffer.allocate(44 + dataSize).order(ByteOrder.LITTLE_ENDIAN);
        putAscii(buffer, "RIFF");
        buffer.putInt(36 + dataSize);
        putAscii(buffer, "WAVE");
        putAscii(buffer, "fmt ");
        buffer.putInt(16);
        buffer.putShort((short) 1);
        buffer.putShort((short) 1);
        buffer.putInt(sampleRate);
        buffer.putInt(sampleRate);
        buffer.putShort((short) 1);
        buffer.putShort((short) 8);
        putAscii(buffer, "data");
        buffer.putInt(dataSize);
        while (buffer.hasRemaining()) {
            buffer.put((byte) 0x80);
        }
        return buffer.array();
    }

    private static void putAscii(ByteBuffer buffer, String value) {
        for (int i = 0; i < value.length(); i++) {
            buffer.put((byte) value.charAt(i));
        }
    }
}
