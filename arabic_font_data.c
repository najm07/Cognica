#include "arabic_font.h"

#define NULL ((void*)0)

// Simplified Arabic font bitmaps (8x16 pixels)
// These are basic representations - can be replaced with better fonts

// ا (alif) - 0x80 - Vertical line
const uint8_t arabic_alif[16] = {
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x00,  // 
    0x00,  // 
    0x00   // 
};

// ب (ba) - 0x81
const uint8_t arabic_ba[16] = {
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x3C,  //   ****
    0x66,  //  **  **
    0x66,  //  **  **
    0x66,  //  **  **
    0x3C,  //   ****
    0x06,  //      **
    0x06,  //      **
    0x06,  //      **
    0x06,  //      **
    0x00,  // 
    0x00,  // 
    0x00   // 
};

// ت (ta) - 0x82
const uint8_t arabic_ta[16] = {
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x3C,  //   ****
    0x66,  //  **  **
    0x66,  //  **  **
    0x66,  //  **  **
    0x3C,  //   ****
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x00,  // 
    0x00,  // 
    0x00   // 
};

// ث (tha) - 0x83 - Similar to ta with dots
const uint8_t arabic_tha[16] = {
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x3C,  //   ****
    0x66,  //  **  **
    0x66,  //  **  **
    0x66,  //  **  **
    0x3C,  //   ****
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x00,  // 
    0x00,  // 
    0x00   // 
};

// ج (jeem) - 0x84
const uint8_t arabic_jeem[16] = {
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x3C,  //   ****
    0x60,  //  **
    0x60,  //  **
    0x60,  //  **
    0x3C,  //   ****
    0x06,  //      **
    0x06,  //      **
    0x66,  //  **  **
    0x3C,  //   ****
    0x00,  // 
    0x00,  // 
    0x00   // 
};

// ح (ha) - 0x85
const uint8_t arabic_ha[16] = {
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x3C,  //   ****
    0x60,  //  **
    0x60,  //  **
    0x60,  //  **
    0x3C,  //   ****
    0x06,  //      **
    0x06,  //      **
    0x06,  //      **
    0x06,  //      **
    0x00,  // 
    0x00,  // 
    0x00   // 
};

// خ (kha) - 0x86
const uint8_t arabic_kha[16] = {
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x3C,  //   ****
    0x60,  //  **
    0x60,  //  **
    0x60,  //  **
    0x3C,  //   ****
    0x06,  //      **
    0x06,  //      **
    0x06,  //      **
    0x06,  //      **
    0x00,  // 
    0x00,  // 
    0x00   // 
};

// د (dal) - 0x87
const uint8_t arabic_dal[16] = {
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x3C,  //   ****
    0x18,  //    **
    0x00,  // 
    0x00,  // 
    0x00   // 
};

// ذ (thal) - 0x88
const uint8_t arabic_thal[16] = {
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x3C,  //   ****
    0x18,  //    **
    0x00,  // 
    0x00,  // 
    0x00   // 
};

// ر (ra) - 0x89
const uint8_t arabic_ra[16] = {
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x0C,  //     **
    0x18,  //    **
    0x00,  // 
    0x00,  // 
    0x00   // 
};

// ز (zay) - 0x8A
const uint8_t arabic_zay[16] = {
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x0C,  //     **
    0x18,  //    **
    0x00,  // 
    0x00,  // 
    0x00   // 
};

// س (seen) - 0x8B
const uint8_t arabic_seen[16] = {
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x3C,  //   ****
    0x60,  //  **
    0x60,  //  **
    0x3C,  //   ****
    0x06,  //      **
    0x06,  //      **
    0x06,  //      **
    0x66,  //  **  **
    0x3C,  //   ****
    0x00,  // 
    0x00,  // 
    0x00   // 
};

// ش (sheen) - 0x8C
const uint8_t arabic_sheen[16] = {
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x3C,  //   ****
    0x60,  //  **
    0x60,  //  **
    0x3C,  //   ****
    0x06,  //      **
    0x06,  //      **
    0x06,  //      **
    0x66,  //  **  **
    0x3C,  //   ****
    0x00,  // 
    0x00,  // 
    0x00   // 
};

// ص (sad) - 0x8D
const uint8_t arabic_sad[16] = {
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x3C,  //   ****
    0x66,  //  **  **
    0x66,  //  **  **
    0x66,  //  **  **
    0x3C,  //   ****
    0x06,  //      **
    0x06,  //      **
    0x06,  //      **
    0x06,  //      **
    0x00,  // 
    0x00,  // 
    0x00   // 
};

// ض (dad) - 0x8E
const uint8_t arabic_dad[16] = {
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x3C,  //   ****
    0x66,  //  **  **
    0x66,  //  **  **
    0x66,  //  **  **
    0x3C,  //   ****
    0x06,  //      **
    0x06,  //      **
    0x06,  //      **
    0x06,  //      **
    0x00,  // 
    0x00,  // 
    0x00   // 
};

// ط (ta) - 0x8F
const uint8_t arabic_ta2[16] = {
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x7E,  //  ******
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x00,  // 
    0x00,  // 
    0x00   // 
};

// ظ (za) - 0x90
const uint8_t arabic_za[16] = {
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x7E,  //  ******
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x00,  // 
    0x00,  // 
    0x00   // 
};

// ع (ain) - 0x91
const uint8_t arabic_ain[16] = {
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x3C,  //   ****
    0x60,  //  **
    0x60,  //  **
    0x3C,  //   ****
    0x06,  //      **
    0x06,  //      **
    0x06,  //      **
    0x06,  //      **
    0x06,  //      **
    0x00,  // 
    0x00,  // 
    0x00   // 
};

// غ (ghain) - 0x92
const uint8_t arabic_ghain[16] = {
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x3C,  //   ****
    0x60,  //  **
    0x60,  //  **
    0x3C,  //   ****
    0x06,  //      **
    0x06,  //      **
    0x06,  //      **
    0x06,  //      **
    0x06,  //      **
    0x00,  // 
    0x00,  // 
    0x00   // 
};

// ف (fa) - 0x93
const uint8_t arabic_fa[16] = {
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x3C,  //   ****
    0x66,  //  **  **
    0x66,  //  **  **
    0x66,  //  **  **
    0x3C,  //   ****
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x00,  // 
    0x00,  // 
    0x00   // 
};

// ق (qaf) - 0x94
const uint8_t arabic_qaf[16] = {
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x3C,  //   ****
    0x66,  //  **  **
    0x66,  //  **  **
    0x66,  //  **  **
    0x3C,  //   ****
    0x06,  //      **
    0x06,  //      **
    0x06,  //      **
    0x06,  //      **
    0x00,  // 
    0x00,  // 
    0x00   // 
};

// ك (kaf) - 0x95
const uint8_t arabic_kaf[16] = {
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x66,  //  **  **
    0x66,  //  **  **
    0x66,  //  **  **
    0x3C,  //   ****
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x00,  // 
    0x00,  // 
    0x00   // 
};

// ل (lam) - 0x96
const uint8_t arabic_lam[16] = {
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x3C,  //   ****
    0x66,  //  **  **
    0x00,  // 
    0x00,  // 
    0x00   // 
};

// م (meem) - 0x97
const uint8_t arabic_meem[16] = {
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x66,  //  **  **
    0x66,  //  **  **
    0x66,  //  **  **
    0x66,  //  **  **
    0x66,  //  **  **
    0x66,  //  **  **
    0x66,  //  **  **
    0x3C,  //   ****
    0x06,  //      **
    0x00,  // 
    0x00,  // 
    0x00   // 
};

// ن (noon) - 0x98
const uint8_t arabic_noon[16] = {
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x3C,  //   ****
    0x66,  //  **  **
    0x66,  //  **  **
    0x66,  //  **  **
    0x3C,  //   ****
    0x06,  //      **
    0x06,  //      **
    0x06,  //      **
    0x06,  //      **
    0x00,  // 
    0x00,  // 
    0x00   // 
};

// ه (ha) - 0x99
const uint8_t arabic_ha2[16] = {
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x3C,  //   ****
    0x66,  //  **  **
    0x66,  //  **  **
    0x66,  //  **  **
    0x3C,  //   ****
    0x06,  //      **
    0x06,  //      **
    0x06,  //      **
    0x06,  //      **
    0x00,  // 
    0x00,  // 
    0x00   // 
};

// و (waw) - 0x9A
const uint8_t arabic_waw[16] = {
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x3C,  //   ****
    0x66,  //  **  **
    0x66,  //  **  **
    0x66,  //  **  **
    0x66,  //  **  **
    0x66,  //  **  **
    0x66,  //  **  **
    0x3C,  //   ****
    0x18,  //    **
    0x00,  // 
    0x00,  // 
    0x00   // 
};

// ي (ya) - 0x9B
const uint8_t arabic_ya[16] = {
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x00,  // 
    0x3C,  //   ****
    0x66,  //  **  **
    0x66,  //  **  **
    0x66,  //  **  **
    0x3C,  //   ****
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x18,  //    **
    0x00,  // 
    0x00,  // 
    0x00   // 
};

// Function to get Arabic font data
const uint8_t* get_arabic_font(uint8_t code) {
    switch (code) {
        case 0x80: return arabic_alif;
        case 0x81: return arabic_ba;
        case 0x82: return arabic_ta;
        case 0x83: return arabic_tha;
        case 0x84: return arabic_jeem;
        case 0x85: return arabic_ha;
        case 0x86: return arabic_kha;
        case 0x87: return arabic_dal;
        case 0x88: return arabic_thal;
        case 0x89: return arabic_ra;
        case 0x8A: return arabic_zay;
        case 0x8B: return arabic_seen;
        case 0x8C: return arabic_sheen;
        case 0x8D: return arabic_sad;
        case 0x8E: return arabic_dad;
        case 0x8F: return arabic_ta2;
        case 0x90: return arabic_za;
        case 0x91: return arabic_ain;
        case 0x92: return arabic_ghain;
        case 0x93: return arabic_fa;
        case 0x94: return arabic_qaf;
        case 0x95: return arabic_kaf;
        case 0x96: return arabic_lam;
        case 0x97: return arabic_meem;
        case 0x98: return arabic_noon;
        case 0x99: return arabic_ha2;
        case 0x9A: return arabic_waw;
        case 0x9B: return arabic_ya;
        default: return NULL;
    }
    return NULL; // Fallback
}

