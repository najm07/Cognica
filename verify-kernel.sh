#!/bin/bash
# Verify kernel and ISO setup

cd "$(dirname "$0")"

echo "=== Kernel Verification ==="
echo ""

# Check kernel
if [ -f build/kernel.bin ]; then
    echo "✓ Kernel exists: build/kernel.bin"
    ls -lh build/kernel.bin
    echo ""
    
    # Check with GRUB
    if grub-file --is-x86-multiboot2 build/kernel.bin 2>/dev/null; then
        echo "✓ GRUB recognizes as Multiboot 2"
    else
        echo "✗ GRUB does NOT recognize as Multiboot 2"
    fi
    
    # Check multiboot header location
    echo ""
    echo "Multiboot header location:"
    hexdump -C build/kernel.bin | grep -B1 -A3 "d6 50 52 e8" | head -5
else
    echo "✗ Kernel not found!"
    exit 1
fi

echo ""
echo "=== ISO Verification ==="
if [ -f build/cognica-os.iso ]; then
    echo "✓ ISO exists: build/cognica-os.iso"
    ls -lh build/cognica-os.iso
    echo ""
    echo "ISO file type:"
    file build/cognica-os.iso
else
    echo "✗ ISO not found!"
    echo "Run: bash rebuild-iso.sh"
    exit 1
fi

echo ""
echo "=== GRUB Config ==="
if [ -f isodir/boot/grub/grub.cfg ]; then
    echo "GRUB configuration:"
    cat isodir/boot/grub/grub.cfg
else
    echo "✗ GRUB config not found!"
fi

