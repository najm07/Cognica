#ifndef ARABIC_SHAPING_H
#define ARABIC_SHAPING_H

#include "vga.h"

// Arabic character forms
typedef enum {
    ARABIC_FORM_ISOLATED = 0,
    ARABIC_FORM_INITIAL = 1,
    ARABIC_FORM_MEDIAL = 2,
    ARABIC_FORM_FINAL = 3
} arabic_form_t;

// Character connectivity flags
#define ARABIC_CONNECTS_RIGHT 0x01  // Connects to next character (right)
#define ARABIC_CONNECTS_LEFT  0x02   // Connects to previous character (left)
#define ARABIC_CONNECTS_BOTH  0x03   // Connects both ways

// Base character codes (0x80-0x9B)
// These map to Unicode Arabic characters
#define ARABIC_BASE_ALIF   0x80  // ا
#define ARABIC_BASE_BA     0x81  // ب
#define ARABIC_BASE_TA     0x82  // ت
#define ARABIC_BASE_THA    0x83  // ث
#define ARABIC_BASE_JEEM   0x84  // ج
#define ARABIC_BASE_HA     0x85  // ح
#define ARABIC_BASE_KHA    0x86  // خ
#define ARABIC_BASE_DAL    0x87  // د
#define ARABIC_BASE_THAL   0x88  // ذ
#define ARABIC_BASE_RA     0x89  // ر
#define ARABIC_BASE_ZAY    0x8A  // ز
#define ARABIC_BASE_SEEN   0x8B  // س
#define ARABIC_BASE_SHEEN  0x8C  // ش
#define ARABIC_BASE_SAD    0x8D  // ص
#define ARABIC_BASE_DAD    0x8E  // ض
#define ARABIC_BASE_TA2    0x8F  // ط
#define ARABIC_BASE_ZA     0x90  // ظ
#define ARABIC_BASE_AIN    0x91  // ع
#define ARABIC_BASE_GHAIN  0x92  // غ
#define ARABIC_BASE_FA     0x93  // ف
#define ARABIC_BASE_QAF    0x94  // ق
#define ARABIC_BASE_KAF    0x95  // ك
#define ARABIC_BASE_LAM    0x96  // ل
#define ARABIC_BASE_MEEM   0x97  // م
#define ARABIC_BASE_NOON   0x98  // ن
#define ARABIC_BASE_HA2    0x99  // ه
#define ARABIC_BASE_WAW    0x9A  // و
#define ARABIC_BASE_YA      0x9B  // ي

// Ligature codes
#define ARABIC_LIGATURE_LAM_ALIF      0xF0  // لا
#define ARABIC_LIGATURE_LAM_ALIF_MADDAH 0xF1  // لا (with maddah)
#define ARABIC_LIGATURE_LAM_ALIF_HAMZA_ABOVE 0xF2  // لأ
#define ARABIC_LIGATURE_LAM_ALIF_HAMZA_BELOW 0xF3  // لإ

// Check if a character code is Arabic (base code range)
static inline int is_arabic_base_code(uint8_t code) {
    return (code >= 0x80 && code <= 0x9B);
}

// Check if a character code is an Arabic form code
static inline int is_arabic_form_code(uint8_t code) {
    return (code >= 0x80 && code <= 0xEF);
}

// Check if a character code is an Arabic ligature
static inline int is_arabic_ligature(uint8_t code) {
    return (code >= 0xF0 && code <= 0xF3);
}

// Get connectivity flags for a base character code
uint8_t get_arabic_connectivity(uint8_t base_code);

// Select appropriate form based on context
arabic_form_t select_form(uint8_t prev_code, uint8_t current_code, uint8_t next_code);

// Map base code + form to form code (0x80-0xEF)
uint8_t get_form_code(uint8_t base_code, arabic_form_t form);

// Check for lam-alef ligature
// Returns ligature code (0xF0-0xF3) if found, 0 otherwise
uint8_t check_ligature(uint8_t lam_code, uint8_t alef_code);

#endif // ARABIC_SHAPING_H
