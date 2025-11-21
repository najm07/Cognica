#!/usr/bin/env python3
"""
Extract font data from arabic_font_data.c and create a binary file
that can be embedded in the bootloader.
"""

import re
import sys

def extract_font_data(c_file):
    """Extract font data from C file and return as list of bytes."""
    fonts = {}
    
    with open(c_file, 'r') as f:
        content = f.read()
    
    # Find all font arrays: const uint8_t name[16] = { ... };
    pattern = r'const uint8_t (\w+)\[16\]\s*=\s*\{([^}]+)\};'
    matches = re.findall(pattern, content)
    
    for var_name, data_str in matches:
        # Extract hex values
        hex_values = re.findall(r'0x([0-9A-Fa-f]{2})', data_str)
        if len(hex_values) == 16:
            bytes_data = [int(h, 16) for h in hex_values]
            fonts[var_name] = bytes_data
    
    return fonts

def get_font_code_from_name(var_name):
    """Extract character code from variable name."""
    # Pattern: arabic_0627_isolated -> code based on unicode and form
    # Or: arabic_ligature_F0 -> 0xF0
    
    if 'ligature' in var_name:
        # Extract hex code
        match = re.search(r'F([0-9A-Fa-f])', var_name)
        if match:
            return 0xF0 + int(match.group(1), 16)
    else:
        # Extract unicode and form
        match = re.search(r'arabic_([0-9A-Fa-f]{4})_(isolated|initial|medial|final)', var_name)
        if match:
            unicode_val = int(match.group(1), 16)
            form = match.group(2)
            
            # Map unicode to base code (0x80-0x9B)
            unicode_to_base = {
                0x0627: 0x80, 0x0628: 0x81, 0x062A: 0x82, 0x062B: 0x83,
                0x062C: 0x84, 0x062D: 0x85, 0x062E: 0x86, 0x062F: 0x87,
                0x0630: 0x88, 0x0631: 0x89, 0x0632: 0x8A, 0x0633: 0x8B,
                0x0634: 0x8C, 0x0635: 0x8D, 0x0636: 0x8E, 0x0637: 0x8F,
                0x0638: 0x90, 0x0639: 0x91, 0x063A: 0x92, 0x0641: 0x93,
                0x0642: 0x94, 0x0643: 0x95, 0x0644: 0x96, 0x0645: 0x97,
                0x0646: 0x98, 0x0647: 0x99, 0x0648: 0x9A, 0x064A: 0x9B,
            }
            
            base_code = unicode_to_base.get(unicode_val)
            if base_code:
                form_offset = {'isolated': 0, 'initial': 28, 'medial': 56, 'final': 84}[form]
                return base_code + form_offset
    
    return None

def create_font_binary(fonts, output_file):
    """Create binary font file ordered by character code."""
    # Create mapping: code -> font data
    font_map = {}
    for var_name, font_data in fonts.items():
        code = get_font_code_from_name(var_name)
        if code is not None:
            font_map[code] = font_data
    
    # Write binary file: 112 forms (0x80-0xEF) + 4 ligatures (0xF0-0xF3) = 116 characters
    # Each character is 16 bytes
    with open(output_file, 'wb') as f:
        # Write forms 0x80-0xEF (112 characters)
        for code in range(0x80, 0xF0):
            if code in font_map:
                f.write(bytes(font_map[code]))
            else:
                f.write(bytes([0] * 16))  # Padding
        
        # Write ligatures 0xF0-0xF3 (4 characters)
        for code in range(0xF0, 0xF4):
            if code in font_map:
                f.write(bytes(font_map[code]))
            else:
                f.write(bytes([0] * 16))  # Padding
    
    print(f"Created {output_file}: {len(font_map)} fonts, {116 * 16} bytes total")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 embed_fonts.py <input.c> <output.bin>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    fonts = extract_font_data(input_file)
    print(f"Extracted {len(fonts)} font definitions")
    create_font_binary(fonts, output_file)
