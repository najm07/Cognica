# Testing Guide for Arabic Support Implementation

## Prerequisites

1. **Build Tools:**
   - `gcc` (GCC compiler)
   - `nasm` (Netwide Assembler)
   - `ld` (GNU linker)
   - `grub-mkrescue` (for ISO creation)
   - `qemu-system-x86_64` (for emulation)

2. **Python 3** (for font generation scripts)

3. **Installation (Ubuntu/Debian):**
   ```bash
   sudo apt-get update
   sudo apt-get install build-essential nasm grub-pc-bin qemu-system-x86
   ```

## Building the System

### Option 1: Build with GRUB (Current System)
```bash
# Build kernel
make clean
make

# Create bootable ISO
make iso

# Run in QEMU
make run
```

### Option 2: Build with Custom Bootloader
```bash
# Build kernel and bootloader
make clean
make all

# Generate font binary
python3 embed_fonts.py arabic_font_data.c build/fonts.bin

# Create bootable disk image
make disk

# Run disk image in QEMU
qemu-system-x86_64 -drive file=build/disk.img,format=raw -m 128M
```

## Testing Phases

### Phase 1: Basic UTF-8 Decoding Test

**Test ASCII characters:**
The kernel already prints ASCII text. Verify it displays correctly.

**Test Arabic UTF-8:**
Modify `kernel.c` to add test strings:

```c
// In kernel_main(), add:
vga_write_utf8_string("Test: مرحبا\n");
vga_write_utf8_string("Hello مرحبا World\n");
```

**Expected Result:**
- ASCII characters display normally
- Arabic characters display (may show as placeholders if fonts not loaded)

### Phase 2: Font Loading Test

**With Custom Bootloader:**
1. Build bootloader: `make bootloader`
2. Check bootloader size: Should be ≤ 512 bytes
3. Run with QEMU and watch for boot messages:
   - "Loading fonts..."
   - "Fonts loaded!"

**With GRUB (Current):**
Fonts are loaded in kernel via `vga_load_arabic_font()`. Check if Arabic characters render correctly.

### Phase 3: Form Selection Test

Create a test function in `kernel.c`:

```c
void test_arabic_forms(void) {
    // Test isolated form (single character)
    vga_write_utf8_string("ب\n");  // Should use isolated form
    
    // Test initial form (first in word)
    vga_write_utf8_string("بسم\n");  // ب should use initial form
    
    // Test medial form (middle of word)
    vga_write_utf8_string("كتب\n");  // ت should use medial form
    
    // Test final form (last in word)
    vga_write_utf8_string("كتاب\n");  // ب should use final form
}
```

**Expected Result:**
Each character should display in the correct form based on its position.

### Phase 4: Ligature Test

```c
void test_ligatures(void) {
    // Test lam-alef ligature
    vga_write_utf8_string("لا\n");  // Should render as ligature
    
    // Test lam-alef with maddah
    vga_write_utf8_string("لآ\n");  // Should render as ligature F1
    
    // Test in context
    vga_write_utf8_string("السلام\n");  // لا should be ligature
}
```

**Expected Result:**
Lam-alef combinations should render as single ligature characters.

### Phase 5: Mixed Text Test

```c
void test_mixed_text(void) {
    vga_write_utf8_string("Hello مرحبا World\n");
    vga_write_utf8_string("Arabic: مرحبا | English: Hello\n");
    vga_write_utf8_string("Numbers: 12345\n");
    vga_write_utf8_string("Mixed: Hello123مرحبا456\n");
}
```

**Expected Result:**
- Arabic renders right-to-left
- English renders left-to-right
- Numbers render correctly
- Mixed text handles direction correctly

## Quick Test Script

Create `test-arabic.sh`:

```bash
#!/bin/bash

echo "Building kernel..."
make clean
make

echo "Creating ISO..."
make iso

echo "Running in QEMU..."
echo "Look for Arabic text rendering in the output"
qemu-system-x86_64 -cdrom build/cognica-os.iso -m 128M -boot d -no-reboot
```

Make it executable:
```bash
chmod +x test-arabic.sh
./test-arabic.sh
```

## Debugging Tips

### 1. Check Font Data
```bash
# Verify font binary was created
ls -lh build/fonts.bin

# Check font data in C file
grep "arabic_0627" arabic_font_data.c
```

###2. Debug Bootloader
```bash
# Build bootloader only
make bootloader

# Check size (must be ≤ 512 bytes)
ls -lh build/bootloader.bin

# Disassemble to verify
objdump -D -b binary -m i8086 build/bootloader.bin | head -50
```

### 3. QEMU Debug Options
```bash
# Run with debug output
qemu-system-x86_64 -cdrom build/cognica-os.iso -m 128M -d int

# Run with serial output
qemu-system-x86_64 -cdrom build/cognica-os.iso -m 128M -serial stdio

# Run with GDB
qemu-system-x86_64 -cdrom build/cognica-os.iso -m 128M -s -S
# Then in another terminal:
gdb -ex "target remote localhost:1234"
```

### 4. Check Kernel Output
The kernel prints Arabic text on boot. Look for:
- "مرحباً بك في نواة نظام Cognica"
- "حالة النواة"
- "معلومات النظام"

If these display correctly, UTF-8 decoding and basic rendering work.

## Expected Output

When working correctly, you should see:

```
مرحباً بك في نواة نظام Cognica
=============================

:تم
:رقم Multiboot السحري

:الذاكرة - السفلي
 KB، العلوي: [memory amount] KB

:حالة النواة
:تعمل
(64-bit) 0.2.0:الإصدار

:معلومات النظام
(64-bit) x86-64:المعمارية -
(Multiboot 2) GRUB:محمل الإقلاع -
(80x25) وضع النص:وضع VGA -
(64-bit) الوضع الطويل:الوضع -

:النواة جاهزة
:تم إيقاف النظام
.
```

## Troubleshooting

### Problem: Arabic characters show as "?"
**Solution:** Fonts not loaded. Check:
- Bootloader loaded fonts correctly
- Font data is in correct format
- Character codes match between shaping and font data

### Problem: Characters don't connect properly
**Solution:** Form selection not working. Check:
- `select_form()` function logic
- Connectivity table is correct
- Context (prev/next) is passed correctly

### Problem: Ligatures don't work
**Solution:** Ligature detection issue. Check:
- `check_ligature()` function
- Unicode mapping for lam and alef variants
- Ligature codes (0xF0-0xF3) are correct

### Problem: Build fails
**Solution:** Check dependencies:
```bash
# Verify tools
which gcc nasm ld grub-mkrescue qemu-system-x86_64
python3 --version
```

## Performance Testing

To benchmark UTF-8 decoding:
```c
// Add timing code around vga_write_utf8_string()
// Measure time for decoding + rendering
```

## Next Steps

1. **Generate Real Fonts:** Install Pillow and generate actual font bitmaps
2. **Add More Characters:** Extend to support more Arabic characters
3. **Improve Rendering:** Optimize rendering performance
4. **Add Diacritics:** Support Arabic diacritical marks
