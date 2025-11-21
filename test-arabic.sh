#!/bin/bash

# Quick test script for Arabic support

set -e

echo "=========================================="
echo "Arabic Support Testing Script"
echo "=========================================="
echo ""

# Check dependencies
echo "Checking dependencies..."
command -v gcc >/dev/null 2>&1 || { echo "Error: gcc not found"; exit 1; }
command -v nasm >/dev/null 2>&1 || { echo "Error: nasm not found"; exit 1; }
command -v ld >/dev/null 2>&1 || { echo "Error: ld not found"; exit 1; }
command -v grub-mkrescue >/dev/null 2>&1 || { echo "Error: grub-mkrescue not found"; exit 1; }
command -v qemu-system-x86_64 >/dev/null 2>&1 || { echo "Error: qemu-system-x86_64 not found"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "Error: python3 not found"; exit 1; }
echo "✓ All dependencies found"
echo ""

# Clean previous builds
echo "Cleaning previous builds..."
make clean 2>/dev/null || true
echo ""

# Build kernel
echo "Building kernel..."
make
echo ""

# Check if build succeeded
if [ ! -f "build/kernel.bin" ]; then
    echo "Error: Kernel build failed!"
    exit 1
fi
echo "✓ Kernel built successfully"
echo ""

# Generate font binary if script exists
if [ -f "embed_fonts.py" ] && [ -f "arabic_font_data.c" ]; then
    echo "Generating font binary..."
    python3 embed_fonts.py arabic_font_data.c build/fonts.bin 2>/dev/null || echo "Warning: Font binary generation skipped"
    echo ""
fi

# Create ISO
echo "Creating bootable ISO..."
make iso
echo ""

# Check if ISO was created
if [ ! -f "build/cognica-os.iso" ]; then
    echo "Error: ISO creation failed!"
    exit 1
fi
echo "✓ ISO created successfully"
echo ""

# Display test information
echo "=========================================="
echo "Test Information"
echo "=========================================="
echo "Kernel size: $(stat -f%z build/kernel.bin 2>/dev/null || stat -c%s build/kernel.bin 2>/dev/null) bytes"
echo "ISO size: $(stat -f%z build/cognica-os.iso 2>/dev/null || stat -c%s build/cognica-os.iso 2>/dev/null) bytes"
echo ""
echo "Expected output:"
echo "  - Arabic text: 'مرحباً بك في نواة نظام Cognica'"
echo "  - System information in Arabic"
echo "  - Mixed Arabic/English text"
echo ""
echo "=========================================="
echo "Starting QEMU..."
echo "=========================================="
echo "Press Ctrl+C to stop QEMU"
echo ""

# Run QEMU
qemu-system-x86_64 -cdrom build/cognica-os.iso -m 128M -boot d -no-reboot

echo ""
echo "Test completed!"
