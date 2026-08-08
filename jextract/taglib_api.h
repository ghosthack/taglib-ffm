/* Complete TagLib C API handed to jextract. */
#include <tag_c.h>

/*
 * These symbols are exported only on Windows and are hidden by tag_c.h when
 * generation runs on macOS. Redeclaring them here keeps one generated Java API
 * for every platform. Their ABI is pointer-only, so wchar_t width does not
 * affect the function descriptor; callers allocate UTF-16 wchar_t buffers on
 * Windows.
 */
#ifndef _WIN32
TagLib_File *taglib_file_new_wchar(const wchar_t *filename);
TagLib_File *taglib_file_new_type_wchar(const wchar_t *filename, TagLib_File_Type type);
#endif
