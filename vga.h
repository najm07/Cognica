#ifndef VGA_H
#define VGA_H

// Type definitions for kernel (no stdlib)
typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned long uint32_t;
typedef unsigned long size_t;

// VGA text mode constants
#define VGA_WIDTH  80
#define VGA_HEIGHT 25

// VGA color palette
enum vga_color {
    VGA_COLOR_BLACK = 0,
    VGA_COLOR_BLUE = 1,
    VGA_COLOR_GREEN = 2,
    VGA_COLOR_CYAN = 3,
    VGA_COLOR_RED = 4,
    VGA_COLOR_MAGENTA = 5,
    VGA_COLOR_BROWN = 6,
    VGA_COLOR_LIGHT_GREY = 7,
    VGA_COLOR_DARK_GREY = 8,
    VGA_COLOR_LIGHT_BLUE = 9,
    VGA_COLOR_LIGHT_GREEN = 10,
    VGA_COLOR_LIGHT_CYAN = 11,
    VGA_COLOR_LIGHT_RED = 12,
    VGA_COLOR_LIGHT_MAGENTA = 13,
    VGA_COLOR_YELLOW = 14,
    VGA_COLOR_WHITE = 15,
};

// VGA memory address
static inline uint8_t vga_entry_color(enum vga_color fg, enum vga_color bg) {
    return fg | bg << 4;
}

static inline uint16_t vga_entry(unsigned char uc, uint8_t color) {
    return (uint16_t) uc | (uint16_t) color << 8;
}

// Initialize VGA text mode
void vga_initialize(void);

// Clear the screen
void vga_clear(void);

// Set the color for subsequent writes
void vga_set_color(enum vga_color fg, enum vga_color bg);

// Write a character at current position
void vga_putchar(char c);

// Write a string
void vga_write_string(const char* data);

// Write an unsigned integer
void vga_write_uint(unsigned long num);

// Get current row
size_t vga_get_row(void);

// Get current column
size_t vga_get_column(void);

// Set cursor position
void vga_set_cursor(size_t row, size_t column);

#endif

