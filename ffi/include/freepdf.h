#pragma once
#include <stdint.h>
#include <stddef.h>

/* 0 = ok. Anything else = failed, and `error` holds a sentence (may be NULL). */
int32_t freepdf_scan_page(const char *photo_path, const char *out_page_path,
                          char *error, size_t error_size);
int32_t freepdf_pages_to_pdf(const char *const *page_paths, size_t page_count,
                             const char *out_pdf_path,
                             char *error, size_t error_size);
