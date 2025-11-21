#include "vga.h"
#include "io.h"

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

void kernel_main(unsigned long magic, struct multiboot_info* mbi) {
    // Initialize VGA text mode
    vga_initialize();
    
    // Clear screen
    vga_clear();
    
    // Print welcome message
    vga_set_color(VGA_COLOR_LIGHT_GREEN, VGA_COLOR_BLACK);
    vga_write_string("Welcome to Cognica OS Kernel!\n");
    vga_write_string("=============================\n\n");
    
    // Check multiboot magic number
    vga_set_color(VGA_COLOR_WHITE, VGA_COLOR_BLACK);
    if (magic == 0x36d76289) {
        vga_write_string("Multiboot magic number: OK\n");
    } else {
        vga_write_string("Multiboot magic number: FAILED\n");
        return;
    }
    
    // Display memory information if available
    if (mbi->flags & 0x01) {
        vga_set_color(VGA_COLOR_CYAN, VGA_COLOR_BLACK);
        vga_write_string("Memory: ");
        vga_write_string("Lower: ");
        vga_write_uint(mbi->mem_lower);
        vga_write_string(" KB, Upper: ");
        vga_write_uint(mbi->mem_upper);
        vga_write_string(" KB\n");
    }
    
    // Display kernel information
    vga_set_color(VGA_COLOR_YELLOW, VGA_COLOR_BLACK);
    vga_write_string("\nKernel Status: Running\n");
    vga_write_string("Version: 0.1.0\n");
    
    // Display system information
    vga_set_color(VGA_COLOR_LIGHT_BLUE, VGA_COLOR_BLACK);
    vga_write_string("\nSystem Information:\n");
    vga_write_string("- Architecture: x86 (32-bit)\n");
    vga_write_string("- Bootloader: GRUB (Multiboot 2)\n");
    vga_write_string("- VGA Mode: Text Mode (80x25)\n");
    
    // Test keyboard input (basic)
    vga_set_color(VGA_COLOR_WHITE, VGA_COLOR_BLACK);
    vga_write_string("\nKernel is ready. System halted.\n");
    
    // Infinite loop
    while (1) {
        asm volatile ("hlt");
    }
}

