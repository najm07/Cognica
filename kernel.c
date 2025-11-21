#include "vga.h"
#include "io.h"
#include "vga_font.h"

// Multiboot header structure
struct multiboot_info {
    unsigned long flags;
    unsigned long mem_lower;
    unsigned long mem_upper;
    unsigned long boot_device;
    unsigned long cmdline;
    unsigned long mods_count;
    unsigned long mods_addr;
    unsigned long syms[4];
    unsigned long mmap_length;
    unsigned long mmap_addr;
    unsigned long drives_length;
    unsigned long drives_addr;
    unsigned long config_table;
    unsigned long boot_loader_name;
    unsigned long apm_table;
    unsigned long vbe_control_info;
    unsigned long vbe_mode_info;
    unsigned long vbe_mode;
    unsigned long vbe_interface_seg;
    unsigned long vbe_interface_off;
    unsigned long vbe_interface_len;
};

// 64-bit kernel main - System V AMD64 calling convention
// RDI = magic, RSI = mbi
void kernel_main(unsigned long magic, struct multiboot_info* mbi) {
    // Initialize VGA text mode (RTL-native by default: column 0 = rightmost)
    vga_initialize();
    
    // Load Arabic fonts (font loading in 32-bit mode was causing hangs)
    // Try to load fonts in 64-bit mode instead
    vga_load_arabic_font();
    
    // To switch to LTR mode (column 0 = leftmost), use:
    // vga_set_rtl_mode(0);
    
    // Clear screen
    vga_clear();
    
    // Print welcome message in Arabic (using UTF-8)
    vga_set_color(VGA_COLOR_LIGHT_GREEN, VGA_COLOR_BLACK);
    vga_write_string("\n");
    vga_write_utf8_string("!مرحباً بك في نواة نظام Cognica\n");
    vga_write_string("=============================\n\n");
    
    // Check multiboot magic number
    vga_set_color(VGA_COLOR_WHITE, VGA_COLOR_BLACK);
    if (magic == 0x36d76289) {
        vga_write_utf8_string(":تم\n");
        vga_write_utf8_string(":رقم Multiboot السحري\n");
    } else {
        vga_write_utf8_string(":فشل\n");
        vga_write_utf8_string(":رقم Multiboot السحري\n");
        return;
    }
    
    // Display memory information if available
    if (mbi->flags & 0x01) {
        vga_set_color(VGA_COLOR_CYAN, VGA_COLOR_BLACK);
        vga_write_string(" KB\n");
        vga_write_uint(mbi->mem_upper);
        vga_write_utf8_string(" KB، العلوي: ");
        vga_write_uint(mbi->mem_lower);
        vga_write_utf8_string(":الذاكرة - السفلي\n");
    }
    
    // Display kernel information
    vga_set_color(VGA_COLOR_YELLOW, VGA_COLOR_BLACK);
    vga_write_string("\n");
    vga_write_utf8_string("(64-bit) 0.2.0:الإصدار\n");
    vga_write_utf8_string(":تعمل\n");
    vga_write_utf8_string(":حالة النواة\n");
    
    // Display system information
    vga_set_color(VGA_COLOR_LIGHT_BLUE, VGA_COLOR_BLACK);
    vga_write_string("\n");
    vga_write_utf8_string("(64-bit) الوضع الطويل:الوضع -\n");
    vga_write_utf8_string("(80x25) وضع النص:وضع VGA -\n");
    vga_write_utf8_string("(Multiboot 2) GRUB:محمل الإقلاع -\n");
    vga_write_utf8_string("(64-bit) x86-64:المعمارية -\n");
    vga_write_utf8_string(":معلومات النظام\n");
    
    // Test keyboard input (basic)
    vga_set_color(VGA_COLOR_WHITE, VGA_COLOR_BLACK);
    vga_write_string("\n");
    vga_write_string(".\n");
    vga_write_utf8_string(":تم إيقاف النظام\n");
    vga_write_utf8_string(":النواة جاهزة\n");
    
    // Infinite loop
    while (1) {
        asm volatile ("hlt");
    }
}

