#pragma once
#include <stdint.h>
#include <stddef.h>

/* 0 = ok. Anything else = failed, and `error` holds a sentence (may be NULL). */
int32_t freepdf_scan_page(const char *photo_path, const char *out_page_path,
                          char *error, size_t error_size);

/* Every value the Adjust screen can move, in the order the recipe uses them.
   The switches are 0 for off, anything else for on. */
typedef struct {
    float corners[8];          /* the four paper corners as x, y pairs, in photo pixels */
    int32_t pull_the_sheet_flat;
    float straighten_degrees;  /* -10 to +10; 0 turns nothing */
    uint8_t black[3];          /* the black point, one value per colour */
    uint8_t white[3];          /* the white point */
    int32_t adjust_the_tones;
    float sharpen_radius;      /* 0 sharpens nothing */
    uint32_t crop_x, crop_y, crop_width, crop_height; /* page pixels; width or height 0 cuts nothing */
    uint32_t quarter_turns;    /* turns clockwise, 0 to 3 */
    int32_t grey;
} FreepdfAdjustments;

/* The adjusted case: the same recipe, with the user's values. Replaces
   freepdf_scan_page once the user has changed something. */
int32_t freepdf_adjust_page(const char *photo_path, const char *out_page_path,
                            const FreepdfAdjustments *values,
                            char *error, size_t error_size);
int32_t freepdf_pages_to_pdf(const char *const *page_paths, size_t page_count,
                             const char *out_pdf_path,
                             char *error, size_t error_size);
