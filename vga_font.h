#ifndef VGA_FONT_H
#define VGA_FONT_H

#include "vga.h"

// VGA font loading functions
void vga_load_custom_font(void);
void vga_load_arabic_font(void);

// UTF-8 support
void vga_write_utf8_string(const char* utf8_string);

#endif

