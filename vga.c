#include "vga.h"

// Boolean type definition
typedef int bool;
#define true 1
#define false 0

static size_t terminal_row;
static size_t terminal_column;
static uint8_t terminal_color;
static uint16_t* terminal_buffer;
static enum vga_text_direction terminal_direction = VGA_DIRECTION_RTL;  // Default to RTL-native

// Convert logical column (RTL-native: 0=rightmost) to physical VGA column (0=leftmost)
static inline size_t logical_to_physical_col(size_t logical_col) {
    if (terminal_direction == VGA_DIRECTION_RTL) {
        // In RTL-native: logical 0 = physical 79, logical 79 = physical 0
        return (VGA_WIDTH - 1) - logical_col;
    } else {
        // In LTR: logical = physical
        return logical_col;
    }
}

// Convert physical VGA column to logical column
static inline size_t physical_to_logical_col(size_t physical_col) {
    if (terminal_direction == VGA_DIRECTION_RTL) {
        // In RTL-native: physical 0 = logical 79, physical 79 = logical 0
        return (VGA_WIDTH - 1) - physical_col;
    } else {
        // In LTR: logical = physical
        return physical_col;
    }
}

void vga_initialize(void) {
    terminal_row = 0;
    // In RTL-native mode, column 0 is the rightmost (start position)
    terminal_column = 0;  // Logical column 0 (rightmost in RTL-native)
    terminal_color = vga_entry_color(VGA_COLOR_LIGHT_GREY, VGA_COLOR_BLACK);
    terminal_buffer = (uint16_t*) 0xB8000;
    
    for (size_t y = 0; y < VGA_HEIGHT; y++) {
        for (size_t x = 0; x < VGA_WIDTH; x++) {
            const size_t index = y * VGA_WIDTH + x;
            terminal_buffer[index] = vga_entry(' ', terminal_color);
        }
    }
}

void vga_clear(void) {
    terminal_row = 0;
    terminal_column = 0;  // Logical column 0 (rightmost in RTL-native)
    for (size_t y = 0; y < VGA_HEIGHT; y++) {
        for (size_t x = 0; x < VGA_WIDTH; x++) {
            const size_t index = y * VGA_WIDTH + x;
            terminal_buffer[index] = vga_entry(' ', terminal_color);
        }
    }
}

void vga_set_color(enum vga_color fg, enum vga_color bg) {
    terminal_color = vga_entry_color(fg, bg);
}

void vga_putchar(char c) {
    if (c == '\n') {
        // Newline: go to column 0 (rightmost in RTL-native, leftmost in LTR)
        terminal_column = 0;
        if (++terminal_row == VGA_HEIGHT) {
            terminal_row = 0;
        }
        return;
    }
    
    if (c == '\r') {
        // Carriage return: go to column 0 (rightmost in RTL-native, leftmost in LTR)
        terminal_column = 0;
        return;
    }
    
    if (c == '\t') {
        // Tab handling: move forward (increment logical column)
        // In RTL-native, incrementing moves left visually, but logically forward
        terminal_column = (terminal_column + 4) & ~(4 - 1);
        if (terminal_column >= VGA_WIDTH) {
            terminal_column = 0;
            if (++terminal_row == VGA_HEIGHT) {
                terminal_row = 0;
            }
        }
        return;
    }
    
    // Write character at current position (convert logical to physical column)
    size_t physical_col = logical_to_physical_col(terminal_column);
    const size_t index = terminal_row * VGA_WIDTH + physical_col;
    terminal_buffer[index] = vga_entry(c, terminal_color);
    
    // Move cursor forward (increment logical column)
    // In RTL-native: incrementing logical column moves left visually
    if (++terminal_column == VGA_WIDTH) {
        terminal_column = 0;
        if (++terminal_row == VGA_HEIGHT) {
            terminal_row = 0;
        }
    }
}

void vga_write_string(const char* data) {
    size_t datalen = 0;
    while (data[datalen] != '\0') {
        datalen++;
    }
    
    for (size_t i = 0; i < datalen; i++) {
        vga_putchar(data[i]);
    }
}

void vga_write_uint(unsigned long num) {
    if (num == 0) {
        vga_putchar('0');
        return;
    }
    
    char buffer[32];
    size_t i = 0;
    
    while (num > 0) {
        buffer[i++] = '0' + (num % 10);
        num /= 10;
    }
    
    // Reverse the string
    for (size_t j = 0; j < i / 2; j++) {
        char temp = buffer[j];
        buffer[j] = buffer[i - 1 - j];
        buffer[i - 1 - j] = temp;
    }
    
    buffer[i] = '\0';
    vga_write_string(buffer);
}

size_t vga_get_row(void) {
    return terminal_row;
}

size_t vga_get_column(void) {
    return terminal_column;
}

void vga_set_cursor(size_t row, size_t column) {
    if (row >= VGA_HEIGHT) row = VGA_HEIGHT - 1;
    if (column >= VGA_WIDTH) column = VGA_WIDTH - 1;
    terminal_row = row;
    // Store logical column (0 = rightmost in RTL-native, 0 = leftmost in LTR)
    terminal_column = column;
}

// RTL support functions
void vga_set_text_direction(enum vga_text_direction direction) {
    // Convert current logical column to physical, then back to new logical
    size_t physical_col = logical_to_physical_col(terminal_column);
    terminal_direction = direction;
    terminal_column = physical_to_logical_col(physical_col);
}

enum vga_text_direction vga_get_text_direction(void) {
    return terminal_direction;
}

void vga_set_rtl_mode(int enabled) {
    vga_set_text_direction(enabled ? VGA_DIRECTION_RTL : VGA_DIRECTION_LTR);
}

