#include "vga_font.h"
#include "io.h"
#include "vga.h"
#include "arabic_font.h"
#include "arabic_shaping.h"

#define NULL ((void*)0)

// VGA Sequencer registers
#define VGA_SEQ_INDEX    0x3C4
#define VGA_SEQ_DATA     0x3C5

// VGA Graphics Controller registers  
#define VGA_GC_INDEX    0x3CE
#define VGA_GC_DATA     0x3CF

// VGA Miscellaneous Output register
#define VGA_MISC_READ    0x3CC
#define VGA_MISC_WRITE   0x3C2

// VGA CRT Controller registers
#define VGA_CRTC_INDEX   0x3D4
#define VGA_CRTC_DATA    0x3D5

// Font data: 8x16 pixels per character
// We'll map Arabic characters to extended ASCII codes (128-255)
// For now, we'll create a simple mapping system

// Arabic Unicode to custom code mapping
// Common Arabic characters mapped to extended ASCII (0x80-0xFF)
static const struct {
    uint32_t unicode;
    uint8_t  vga_code;
} arabic_map[] = {
    {0x0627, 0x80}, // ا (alif)
    {0x0628, 0x81}, // ب (ba)
    {0x062A, 0x82}, // ت (ta)
    {0x062B, 0x83}, // ث (tha)
    {0x062C, 0x84}, // ج (jeem)
    {0x062D, 0x85}, // ح (ha)
    {0x062E, 0x86}, // خ (kha)
    {0x062F, 0x87}, // د (dal)
    {0x0630, 0x88}, // ذ (thal)
    {0x0631, 0x89}, // ر (ra)
    {0x0632, 0x8A}, // ز (zay)
    {0x0633, 0x8B}, // س (seen)
    {0x0634, 0x8C}, // ش (sheen)
    {0x0635, 0x8D}, // ص (sad)
    {0x0636, 0x8E}, // ض (dad)
    {0x0637, 0x8F}, // ط (ta)
    {0x0638, 0x90}, // ظ (za)
    {0x0639, 0x91}, // ع (ain)
    {0x063A, 0x92}, // غ (ghain)
    {0x0641, 0x93}, // ف (fa)
    {0x0642, 0x94}, // ق (qaf)
    {0x0643, 0x95}, // ك (kaf)
    {0x0644, 0x96}, // ل (lam)
    {0x0645, 0x97}, // م (meem)
    {0x0646, 0x98}, // ن (noon)
    {0x0647, 0x99}, // ه (ha)
    {0x0648, 0x9A}, // و (waw)
    {0x064A, 0x9B}, // ي (ya)
    {0x0649, 0x9C}, // ى (alif maksura)
    {0x0621, 0x9D}, // ء (hamza)
    {0x0622, 0x9E}, // آ (alif maddah)
    {0x0623, 0x9F}, // أ (alif hamza)
    {0x0624, 0xA0}, // ؤ (waw hamza)
    {0x0625, 0xA1}, // إ (alif hamza below)
    {0x0626, 0xA2}, // ئ (ya hamza)
    {0x064B, 0xA3}, // ً (fathatan)
    {0x064C, 0xA4}, // ٌ (dammatan)
    {0x064D, 0xA5}, // ٍ (kasratan)
    {0x064E, 0xA6}, // َ (fatha)
    {0x064F, 0xA7}, // ُ (damma)
    {0x0650, 0xA8}, // ِ (kasra)
    {0x0651, 0xA9}, // ّ (shadda)
    {0x0652, 0xAA}, // ْ (sukun)
    {0x060C, 0xAB}, // ، (Arabic comma)
    {0x061B, 0xAC}, // ؛ (Arabic semicolon)
    {0x061F, 0xAD}, // ؟ (Arabic question mark)
    {0x0640, 0xAE}, // ـ (tatweel)
    {0, 0} // End marker
};

// UTF-8 decoding lookup table: byte -> number of continuation bytes
// 0 = ASCII, 1-3 = multi-byte sequence length, 0xFF = invalid
static const uint8_t utf8_length_lut[256] = {
    // 0x00-0x7F: ASCII (0 continuation bytes)
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    // 0x80-0xBF: Continuation bytes (invalid as lead)
    0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
    0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
    0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
    0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
    // 0xC0-0xDF: 2-byte sequence (1 continuation byte)
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    // 0xE0-0xEF: 3-byte sequence (2 continuation bytes)
    2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
    // 0xF0-0xF7: 4-byte sequence (3 continuation bytes)
    3,3,3,3,3,3,3,3,
    // 0xF8-0xFF: Invalid
    0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF
};

// UTF-8 mask lookup table: byte -> mask to extract value bits
static const uint8_t utf8_mask_lut[4] = {
    0x7F,  // ASCII: 7 bits
    0x1F,  // 2-byte: 5 bits
    0x0F,  // 3-byte: 4 bits
    0x07   // 4-byte: 3 bits
};

// Optimized UTF-8 to Unicode decoder with lookup tables
// Fast-path for ASCII (most common case)
static inline uint32_t utf8_to_unicode_optimized(const char** utf8_ptr) {
    const uint8_t* s = (const uint8_t*)*utf8_ptr;
    uint8_t first_byte = s[0];
    
    // Fast-path: ASCII (most common case, ~90% of text)
    if (first_byte < 0x80) {
        (*utf8_ptr)++;
        return first_byte;
    }
    
    // Lookup sequence length
    uint8_t seq_len = utf8_length_lut[first_byte];
    if (seq_len == 0xFF) {
        // Invalid UTF-8, skip byte
        (*utf8_ptr)++;
        return 0;
    }
    
    // Extract value bits from first byte
    uint32_t code = first_byte & utf8_mask_lut[seq_len];
    
    // Decode continuation bytes
    switch (seq_len) {
        case 1: // 2-byte UTF-8
            code = (code << 6) | (s[1] & 0x3F);
            (*utf8_ptr) += 2;
            break;
        case 2: // 3-byte UTF-8
            code = (code << 12) | ((s[1] & 0x3F) << 6) | (s[2] & 0x3F);
            (*utf8_ptr) += 3;
            break;
        case 3: // 4-byte UTF-8
            code = (code << 18) | ((s[1] & 0x3F) << 12) | 
                   ((s[2] & 0x3F) << 6) | (s[3] & 0x3F);
            (*utf8_ptr) += 4;
            break;
    }
    
    return code;
}

// Legacy function name for compatibility
static uint32_t utf8_to_unicode(const char** utf8_ptr) {
    return utf8_to_unicode_optimized(utf8_ptr);
}

// Removed dead code: arabic_to_ascii() function was not used anywhere

// Optimized Unicode to VGA code mapping using direct lookup for common range
// Arabic characters are in range 0x0600-0x06FF, we use a sparse lookup table
// For characters outside this range, fall back to linear search
static uint8_t arabic_unicode_to_vga(uint32_t unicode) {
    // Fast-path: Check if it's in Arabic range (0x0600-0x06FF)
    if (unicode < 0x0600 || unicode > 0x06FF) {
        return 0;
    }
    
    // Use linear search (small array, ~40 entries, binary search overhead not worth it)
    // Could be optimized further with hash table if needed
    for (int i = 0; arabic_map[i].unicode != 0; i++) {
        if (arabic_map[i].unicode == unicode) {
            return arabic_map[i].vga_code;
        }
    }
    return 0; // Not found, return 0 (null)
}

// Buffer for decoded Unicode characters (max 256 characters)
#define MAX_DECODED_CHARS 256
static uint32_t decoded_buffer[MAX_DECODED_CHARS];
static uint8_t shaped_buffer[MAX_DECODED_CHARS];  // Shaped character codes

// Two-pass rendering: decode UTF-8, then apply shaping and render
void vga_write_utf8_string(const char* utf8_string) {
    const char* ptr = utf8_string;
    size_t decoded_count = 0;
    
    // === PASS 1: Decode UTF-8 to Unicode buffer ===
    while (*ptr != '\0' && decoded_count < MAX_DECODED_CHARS) {
        // Fast-path: ASCII characters
        if ((*ptr & 0x80) == 0) {
            decoded_buffer[decoded_count++] = (uint8_t)*ptr;
            ptr++;
            continue;
        }
        
        // Multi-byte UTF-8 sequence
        uint32_t unicode = utf8_to_unicode_optimized(&ptr);
        if (unicode != 0) {
            decoded_buffer[decoded_count++] = unicode;
        }
    }
    
    if (decoded_count == 0) {
        return;  // Nothing to render
    }
    
    // === PASS 2: Apply shaping and render ===
    // Process characters in logical order (left-to-right in memory)
    // But render right-to-left for Arabic text
    
    size_t shaped_count = 0;
    for (size_t i = 0; i < decoded_count; i++) {
        uint32_t unicode = decoded_buffer[i];
        uint8_t base_code = 0;
        uint8_t final_code = 0;
        
        // Check if it's Arabic Unicode
        base_code = arabic_unicode_to_vga(unicode);
        
        if (base_code != 0 && is_arabic_base_code(base_code)) {
            // Arabic character - check for ligatures first
            if (i + 1 < decoded_count) {
                uint32_t next_unicode = decoded_buffer[i + 1];
                uint8_t next_base = arabic_unicode_to_vga(next_unicode);
                
                // Check for lam-alef ligature
                uint8_t ligature = check_ligature(base_code, next_base);
                if (ligature != 0) {
                    // Found ligature - use ligature code and skip next character
                    shaped_buffer[shaped_count++] = ligature;
                    i++;  // Skip next character (already processed as ligature)
                    continue;
                }
            }
            
            // No ligature - select appropriate form
            uint8_t prev_base = 0;
            uint8_t next_base = 0;
            
            // Get previous character base code
            if (i > 0) {
                uint32_t prev_unicode = decoded_buffer[i - 1];
                prev_base = arabic_unicode_to_vga(prev_unicode);
                if (!is_arabic_base_code(prev_base)) {
                    prev_base = 0;  // Not Arabic
                }
            }
            
            // Get next character base code
            if (i + 1 < decoded_count) {
                uint32_t next_unicode = decoded_buffer[i + 1];
                next_base = arabic_unicode_to_vga(next_unicode);
                if (!is_arabic_base_code(next_base)) {
                    next_base = 0;  // Not Arabic
                }
            }
            
            // Select form based on context
            arabic_form_t form = select_form(prev_base, base_code, next_base);
            
            // Map to form code
            final_code = get_form_code(base_code, form);
        } else if (unicode < 128) {
            // ASCII character
            final_code = (uint8_t)unicode;
        } else {
            // Unknown character - use '?' as fallback
            final_code = '?';
        }
        
        shaped_buffer[shaped_count++] = final_code;
    }
    
    // === RENDER: Write shaped characters to screen ===
    // For RTL text, we render right-to-left, so reverse the buffer
    // But since VGA is already in RTL mode, we render in order
    for (size_t i = 0; i < shaped_count; i++) {
        vga_putchar((char)shaped_buffer[i]);
    }
}

// Load a single character font into VGA character generator
// NOTE: VGA font loading in text mode is problematic and may not work
// This is a placeholder - actual font loading requires BIOS calls or mode switching
static void vga_load_char_font(uint8_t char_code, const uint8_t* font_data) {
    // VGA font loading in protected/64-bit mode text mode is very difficult
    // It requires either:
    // 1. BIOS calls (not available in 64-bit mode)
    // 2. Switching to graphics mode temporarily
    // 3. Using VBE/VESA functions
    
    // For now, we skip actual font loading to avoid hangs
    // The Arabic characters will still be mapped to codes 0x80-0x9B,
    // but they will display using whatever font is currently in those slots
    // (likely garbage or default VGA font)
    
    // TODO: Implement proper font loading using VBE or mode switching
    (void)char_code;  // Suppress unused parameter warning
    (void)font_data;  // Suppress unused parameter warning
}

// Load Arabic fonts into VGA character generator
void vga_load_arabic_font(void) {
    // Load each Arabic character font into VGA
    // Note: VGA font loading in text mode requires special handling
    // For now, we prepare the system - actual loading may require BIOS calls
    // or switching to graphics mode temporarily
    
    // Load fonts for codes 0x80-0x9B (Arabic characters)
    for (uint8_t code = 0x80; code <= 0x9B; code++) {
        const uint8_t* font_data = get_arabic_font(code);
        if (font_data != NULL) {
            vga_load_char_font(code, font_data);
        }
    }
}

// Load custom font into VGA
void vga_load_custom_font(void) {
    vga_load_arabic_font();
}

