#include "arabic_shaping.h"

#define NULL ((void*)0)

// Connectivity table: which Arabic letters connect left/right
// Most Arabic letters connect both ways, but some don't:
// - Alif, Dal, Thal, Ra, Zay, Waw don't connect to the right
// - All letters can connect from the left (except in isolated form)
static const uint8_t arabic_connectivity[28] = {
    // 0x80-0x9B: Base codes
    0x00,  // 0x80: ا (alif) - doesn't connect right
    0x03,  // 0x81: ب (ba) - connects both
    0x03,  // 0x82: ت (ta) - connects both
    0x03,  // 0x83: ث (tha) - connects both
    0x03,  // 0x84: ج (jeem) - connects both
    0x03,  // 0x85: ح (ha) - connects both
    0x03,  // 0x86: خ (kha) - connects both
    0x00,  // 0x87: د (dal) - doesn't connect right
    0x00,  // 0x88: ذ (thal) - doesn't connect right
    0x00,  // 0x89: ر (ra) - doesn't connect right
    0x00,  // 0x8A: ز (zay) - doesn't connect right
    0x03,  // 0x8B: س (seen) - connects both
    0x03,  // 0x8C: ش (sheen) - connects both
    0x03,  // 0x8D: ص (sad) - connects both
    0x03,  // 0x8E: ض (dad) - connects both
    0x03,  // 0x8F: ط (ta) - connects both
    0x03,  // 0x90: ظ (za) - connects both
    0x03,  // 0x91: ع (ain) - connects both
    0x03,  // 0x92: غ (ghain) - connects both
    0x03,  // 0x93: ف (fa) - connects both
    0x03,  // 0x94: ق (qaf) - connects both
    0x03,  // 0x95: ك (kaf) - connects both
    0x03,  // 0x96: ل (lam) - connects both
    0x03,  // 0x97: م (meem) - connects both
    0x03,  // 0x98: ن (noon) - connects both
    0x03,  // 0x99: ه (ha) - connects both
    0x00,  // 0x9A: و (waw) - doesn't connect right
    0x03,  // 0x9B: ي (ya) - connects both
};

// Get connectivity flags for a base character code
uint8_t get_arabic_connectivity(uint8_t base_code) {
    if (!is_arabic_base_code(base_code)) {
        return 0;  // Not an Arabic character
    }
    
    int index = base_code - 0x80;
    if (index >= 0 && index < 28) {
        return arabic_connectivity[index];
    }
    
    return 0;
}

// Select appropriate form based on context
arabic_form_t select_form(uint8_t prev_code, uint8_t current_code, uint8_t next_code) {
    // Check if current character is Arabic
    if (!is_arabic_base_code(current_code)) {
        return ARABIC_FORM_ISOLATED;  // Non-Arabic characters are always isolated
    }
    
    uint8_t prev_conn = 0;
    uint8_t next_conn = 0;
    
    // Check if previous character connects to the right
    if (is_arabic_base_code(prev_code)) {
        prev_conn = get_arabic_connectivity(prev_code);
        if (prev_conn & ARABIC_CONNECTS_RIGHT) {
            prev_conn = ARABIC_CONNECTS_RIGHT;
        } else {
            prev_conn = 0;
        }
    }
    
    // Check if current character connects to the right
    uint8_t curr_conn = get_arabic_connectivity(current_code);
    if (curr_conn & ARABIC_CONNECTS_RIGHT) {
        next_conn = ARABIC_CONNECTS_RIGHT;
    } else {
        next_conn = 0;
    }
    
    // Check if next character connects from the left
    if (is_arabic_base_code(next_code)) {
        uint8_t next_char_conn = get_arabic_connectivity(next_code);
        if (next_char_conn & ARABIC_CONNECTS_LEFT) {
            // Next character can connect from left, so current can connect right
            // (already set above)
        } else {
            next_conn = 0;  // Next character doesn't connect from left
        }
    } else {
        next_conn = 0;  // Next character is not Arabic
    }
    
    // Select form based on connectivity
    if (prev_conn && next_conn) {
        return ARABIC_FORM_MEDIAL;  // Connected both ways
    } else if (prev_conn && !next_conn) {
        return ARABIC_FORM_FINAL;    // Connected from left only
    } else if (!prev_conn && next_conn) {
        return ARABIC_FORM_INITIAL;  // Connected to right only
    } else {
        return ARABIC_FORM_ISOLATED; // Not connected
    }
}

// Map base code + form to form code (0x80-0xEF)
uint8_t get_form_code(uint8_t base_code, arabic_form_t form) {
    if (!is_arabic_base_code(base_code)) {
        return base_code;  // Not Arabic, return as-is
    }
    
    // Base codes are 0x80-0x9B (28 codes)
    // Forms: isolated=+0, initial=+28, medial=+56, final=+84
    // Result: 0x80-0xEF (112 codes total)
    
    uint8_t form_offset = form * 28;
    uint8_t form_code = base_code + form_offset;
    
    // Validate form code is in range
    if (form_code >= 0x80 && form_code <= 0xEF) {
        return form_code;
    }
    
    // Fallback: return base code
    return base_code;
}

// Check for lam-alef ligature
// Returns ligature code (0xF0-0xF3) if found, 0 otherwise
uint8_t check_ligature(uint8_t lam_code, uint8_t alef_code) {
    // Check if first character is lam (0x96)
    if (lam_code != ARABIC_BASE_LAM) {
        return 0;
    }
    
    // Check alef variants and return corresponding ligature code
    switch (alef_code) {
        case ARABIC_BASE_ALIF:  // ا
            return ARABIC_LIGATURE_LAM_ALIF;
        case 0x9E:  // آ (alif maddah) - mapped to 0x9E in our system
            return ARABIC_LIGATURE_LAM_ALIF_MADDAH;
        case 0x9F:  // أ (alif hamza above) - mapped to 0x9F
            return ARABIC_LIGATURE_LAM_ALIF_HAMZA_ABOVE;
        case 0xA1:  // إ (alif hamza below) - mapped to 0xA1
            return ARABIC_LIGATURE_LAM_ALIF_HAMZA_BELOW;
        default:
            return 0;  // Not a lam-alef ligature
    }
}
