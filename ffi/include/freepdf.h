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
    /* The cut, as fractions 0…1 of the image the engine holds right before cropping -
       the one this recipe made, after the corners, the straightening, the 3000 px cap
       and the turn. A width or height of 0, or one too thin to reach one pixel, cuts
       nothing. */
    float crop_x, crop_y, crop_width, crop_height;
    uint32_t quarter_turns;    /* turns clockwise, 0 to 3 */
    int32_t grey;
} FreepdfAdjustments;

/* What the engine would have chosen by itself for this photo, so every control on
   the Adjust screen can open on the engine's answer instead of a neutral default.
   `values` is handed straight back to freepdf_adjust_page after the user has
   fine-tuned it. */
typedef struct {
    FreepdfAdjustments values;
    int32_t found_a_sheet;         /* 0 = no sheet found, and values.corners are all zero */
    int32_t fills_the_whole_photo; /* the sheet fills the frame, nothing to cut away */
    int32_t runs_off_the_picture;  /* the sheet leaves the frame */
} FreepdfSuggestion;

/* Asks the engine what it would do on its own. Writes no file.
   values.corners are in the photo's own upright full size pixels - the photo after
   its EXIF orientation was applied, which is the space the app draws it in. They are
   NOT page pixels: the page is pulled flat, straightened and capped first. */
int32_t freepdf_suggest_adjustments(const char *photo_path,
                                    FreepdfSuggestion *out_suggestion,
                                    char *error, size_t error_size);

/* The adjusted case: the same recipe, with the user's values. Replaces
   freepdf_scan_page once the user has changed something. */
int32_t freepdf_adjust_page(const char *photo_path, const char *out_page_path,
                            const FreepdfAdjustments *values,
                            char *error, size_t error_size);
int32_t freepdf_pages_to_pdf(const char *const *page_paths, size_t page_count,
                             const char *out_pdf_path,
                             char *error, size_t error_size);
