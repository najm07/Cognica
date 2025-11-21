// Test functions for Arabic support
// Add these to kernel.c for testing

#include "vga.h"
#include "vga_font.h"
#include "arabic_shaping.h"

// Test UTF-8 decoding with various inputs
void test_utf8_decoding(void) {
    vga_set_color(VGA_COLOR_CYAN, VGA_COLOR_BLACK);
    vga_write_string("\n=== UTF-8 Decoding Test ===\n");
    vga_set_color(VGA_COLOR_WHITE, VGA_COLOR_BLACK);
    
    // Test ASCII
    vga_write_string("ASCII: Hello World\n");
    
    // Test Arabic
    vga_write_utf8_string("Arabic: مرحبا\n");
    
    // Test mixed
    vga_write_utf8_string("Mixed: Hello مرحبا World\n");
    
    // Test numbers
    vga_write_string("Numbers: 1234567890\n");
}

// Test Arabic form selection
void test_arabic_forms(void) {
    vga_set_color(VGA_COLOR_YELLOW, VGA_COLOR_BLACK);
    vga_write_string("\n=== Arabic Form Selection Test ===\n");
    vga_set_color(VGA_COLOR_WHITE, VGA_COLOR_BLACK);
    
    // Isolated form (single character)
    vga_write_utf8_string("Isolated: ب\n");
    
    // Initial form (first character)
    vga_write_utf8_string("Initial: بسم\n");
    
    // Medial form (middle character)
    vga_write_utf8_string("Medial: كتب\n");
    
    // Final form (last character)
    vga_write_utf8_string("Final: كتاب\n");
    
    // All forms in one word
    vga_write_utf8_string("All forms: كتاب\n");
}

// Test ligatures
void test_ligatures(void) {
    vga_set_color(VGA_COLOR_LIGHT_GREEN, VGA_COLOR_BLACK);
    vga_write_string("\n=== Ligature Test ===\n");
    vga_set_color(VGA_COLOR_WHITE, VGA_COLOR_BLACK);
    
    // Lam-alef ligature
    vga_write_utf8_string("Lam-Alif: لا\n");
    
    // Lam-alef with maddah
    vga_write_utf8_string("Lam-Alif Maddah: لآ\n");
    
    // Lam-alef in context
    vga_write_utf8_string("In word: السلام\n");
    vga_write_utf8_string("In word: الله\n");
}

// Test connectivity
void test_connectivity(void) {
    vga_set_color(VGA_COLOR_LIGHT_BLUE, VGA_COLOR_BLACK);
    vga_write_string("\n=== Connectivity Test ===\n");
    vga_set_color(VGA_COLOR_WHITE, VGA_COLOR_BLACK);
    
    // Characters that don't connect right
    vga_write_utf8_string("Non-connecting: ا د ذ ر ز و\n");
    
    // Characters that connect
    vga_write_utf8_string("Connecting: ب ت ث ج ح خ\n");
    
    // Mixed connectivity
    vga_write_utf8_string("Mixed: ا ب ت د ر\n");
}

// Test RTL rendering
void test_rtl_rendering(void) {
    vga_set_color(VGA_COLOR_LIGHT_MAGENTA, VGA_COLOR_BLACK);
    vga_write_string("\n=== RTL Rendering Test ===\n");
    vga_set_color(VGA_COLOR_WHITE, VGA_COLOR_BLACK);
    
    // Pure Arabic (RTL)
    vga_write_utf8_string("RTL: مرحبا بالعالم\n");
    
    // Pure English (LTR)
    vga_write_string("LTR: Hello World\n");
    
    // Mixed direction
    vga_write_utf8_string("Mixed: Hello مرحبا World\n");
    
    // Numbers (should follow context)
    vga_write_utf8_string("Numbers: 123 مرحبا 456\n");
}

// Comprehensive test
void run_all_arabic_tests(void) {
    vga_clear();
    vga_set_color(VGA_COLOR_LIGHT_GREEN, VGA_COLOR_BLACK);
    vga_write_string("========================================\n");
    vga_write_string("  Arabic Support Test Suite\n");
    vga_write_string("========================================\n");
    
    test_utf8_decoding();
    test_arabic_forms();
    test_ligatures();
    test_connectivity();
    test_rtl_rendering();
    
    vga_set_color(VGA_COLOR_LIGHT_GREEN, VGA_COLOR_BLACK);
    vga_write_string("\n========================================\n");
    vga_write_string("  Tests Complete\n");
    vga_write_string("========================================\n");
}

// To use in kernel.c, add this to kernel_main():
// run_all_arabic_tests();
