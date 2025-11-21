#include "vga_font.h"
#include "io.h"
#include "vga.h"
#include "arabic_font.h"

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

// Convert UTF-8 to Unicode code point
static uint32_t utf8_to_unicode(const char** utf8_ptr) {
    const char* s = *utf8_ptr;
    uint32_t code = 0;
    
    if ((s[0] & 0x80) == 0) {
        // ASCII character
        code = (uint8_t)s[0];
        (*utf8_ptr)++;
    } else if ((s[0] & 0xE0) == 0xC0) {
        // 2-byte UTF-8
        code = ((s[0] & 0x1F) << 6) | (s[1] & 0x3F);
        (*utf8_ptr) += 2;
    } else if ((s[0] & 0xF0) == 0xE0) {
        // 3-byte UTF-8
        code = ((s[0] & 0x0F) << 12) | ((s[1] & 0x3F) << 6) | (s[2] & 0x3F);
        (*utf8_ptr) += 3;
    } else if ((s[0] & 0xF8) == 0xF0) {
        // 4-byte UTF-8
        code = ((s[0] & 0x07) << 18) | ((s[1] & 0x3F) << 12) | 
               ((s[2] & 0x3F) << 6) | (s[3] & 0x3F);
        (*utf8_ptr) += 4;
    } else {
        // Invalid UTF-8, skip byte
        (*utf8_ptr)++;
        return 0;
    }
    
    return code;
}

// Map Unicode Arabic character to ASCII transliteration
// Returns pointer to static string or NULL if not found
static const char* arabic_to_ascii(uint32_t unicode) {
    // Common Arabic characters mapped to ASCII transliteration
    // Using a comprehensive mapping for proper display
    switch (unicode) {
        // Letters
        case 0x0627: return "a";  // ا (alif)
        case 0x0628: return "b";  // ب (ba)
        case 0x062A: return "t";  // ت (ta)
        case 0x062B: return "th"; // ث (tha)
        case 0x062C: return "j";  // ج (jeem)
        case 0x062D: return "H";  // ح (ha)
        case 0x062E: return "kh"; // خ (kha)
        case 0x062F: return "d";  // د (dal)
        case 0x0630: return "dh"; // ذ (thal)
        case 0x0631: return "r";  // ر (ra)
        case 0x0632: return "z";  // ز (zay)
        case 0x0633: return "s";  // س (seen)
        case 0x0634: return "sh"; // ش (sheen)
        case 0x0635: return "S";  // ص (sad)
        case 0x0636: return "D";  // ض (dad)
        case 0x0637: return "T";  // ط (ta)
        case 0x0638: return "Z";  // ظ (za)
        case 0x0639: return "'";  // ع (ain)
        case 0x063A: return "gh"; // غ (ghain)
        case 0x0641: return "f";  // ف (fa)
        case 0x0642: return "q";  // ق (qaf)
        case 0x0643: return "k";  // ك (kaf)
        case 0x0644: return "l";  // ل (lam)
        case 0x0645: return "m";  // م (meem)
        case 0x0646: return "n";  // ن (noon)
        case 0x0647: return "h";  // ه (ha)
        case 0x0648: return "w";  // و (waw)
        case 0x064A: return "y";  // ي (ya)
        case 0x0649: return "a";  // ى (alif maksura)
        case 0x0629: return "h";  // ة (ta marbuta)
        // Diacritics and punctuation
        case 0x064B: return "an"; // ً (fathatan)
        case 0x064C: return "un";  // ٌ (dammatan)
        case 0x064D: return "in";  // ٍ (kasratan)
        case 0x064E: return "a";   // َ (fatha)
        case 0x064F: return "u";   // ُ (damma)
        case 0x0650: return "i";   // ِ (kasra)
        case 0x0651: return "";    // ّ (shadda - no transliteration)
        case 0x0652: return "";    // ْ (sukun - no transliteration)
        case 0x060C: return ",";   // ، (Arabic comma)
        case 0x061B: return ";";   // ؛ (Arabic semicolon)
        case 0x061F: return "?";   // ؟ (Arabic question mark)
        case 0x0640: return "-";   // ـ (tatweel)
        // Hamza variants
        case 0x0621: return "'";   // ء (hamza)
        case 0x0622: return "aa";  // آ (alif maddah)
        case 0x0623: return "a";   // أ (alif hamza)
        case 0x0624: return "w";   // ؤ (waw hamza)
        case 0x0625: return "i";   // إ (alif hamza below)
        case 0x0626: return "y";   // ئ (ya hamza)
        default: return NULL;      // Not found
    }
    return NULL; // Fallback
}

// Map Unicode Arabic character to VGA code (for future font support)
static uint8_t arabic_unicode_to_vga(uint32_t unicode) {
    for (int i = 0; arabic_map[i].unicode != 0; i++) {
        if (arabic_map[i].unicode == unicode) {
            return arabic_map[i].vga_code;
        }
    }
    return 0; // Not found, return 0 (null)
}

// Write UTF-8 string with Arabic support (maps to custom font codes)
void vga_write_utf8_string(const char* utf8_string) {
    const char* ptr = utf8_string;
    
    while (*ptr != '\0') {
        uint32_t unicode = utf8_to_unicode(&ptr);
        
        if (unicode < 128) {
            // ASCII character, write directly
            vga_putchar((char)unicode);
        } else {
            // Try to map Arabic Unicode to VGA font code
            uint8_t vga_code = arabic_unicode_to_vga(unicode);
            if (vga_code != 0) {
                vga_putchar((char)vga_code);
            } else {
                // Character not in mapping, write '?' as fallback
                vga_putchar('?');
            }
        }
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

