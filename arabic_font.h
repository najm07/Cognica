#ifndef ARABIC_FONT_H
#define ARABIC_FONT_H

#include "vga.h"

// Arabic font bitmap data (8x16 pixels per character)
// Each character is 16 bytes (one byte per row, 8 bits = 8 pixels)

// Font data is defined in arabic_font_data.c
// These are extern declarations
extern const uint8_t arabic_alif[16];
extern const uint8_t arabic_ba[16];
extern const uint8_t arabic_ta[16];
extern const uint8_t arabic_tha[16];
extern const uint8_t arabic_jeem[16];
extern const uint8_t arabic_ha[16];
extern const uint8_t arabic_kha[16];
extern const uint8_t arabic_dal[16];
extern const uint8_t arabic_thal[16];
extern const uint8_t arabic_ra[16];
extern const uint8_t arabic_zay[16];
extern const uint8_t arabic_seen[16];
extern const uint8_t arabic_sheen[16];
extern const uint8_t arabic_sad[16];
extern const uint8_t arabic_dad[16];
extern const uint8_t arabic_ta2[16];
extern const uint8_t arabic_za[16];
extern const uint8_t arabic_ain[16];
extern const uint8_t arabic_ghain[16];
extern const uint8_t arabic_fa[16];
extern const uint8_t arabic_qaf[16];
extern const uint8_t arabic_kaf[16];
extern const uint8_t arabic_lam[16];
extern const uint8_t arabic_meem[16];
extern const uint8_t arabic_noon[16];
extern const uint8_t arabic_ha2[16];
extern const uint8_t arabic_waw[16];
extern const uint8_t arabic_ya[16];

// Function to get Arabic font data
const uint8_t* get_arabic_font(uint8_t code);

#endif

