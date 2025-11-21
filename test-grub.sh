#!/bin/bash
# Test script to verify Multiboot2 header and boot

echo "=== Testing Multiboot2 Kernel ==="
echo ""

# Check kernel
echo "1. Checking kernel binary..."
if [ -f build/kernel.bin ]; then
    echo "   ✓ Kernel exists"
    file build/kernel.bin
    
    # Check with grub-file
    echo ""
    echo "2. Validating with grub-file..."
    if grub-file --is-x86-multiboot2 build/kernel.bin 2>/dev/null; then
        echo "   ✓ Valid Multiboot2 kernel"
    else
        echo "   ✗ Invalid Multiboot2 kernel"
        exit 1
    fi
    
    # Check header location
    echo ""
    echo "3. Checking header location..."
    python3 << 'PYEOF'
with open('build/kernel.bin', 'rb') as f:
    f.seek(0x1000)
    magic = int.from_bytes(f.read(4), 'little')
    if magic == 0xe85250d6:
        print(f"   ✓ Header at file offset 0x1000: 0x{magic:08x}")
    else:
        print(f"   ✗ Header not at 0x1000: 0x{magic:08x}")
PYEOF
    
    # Check ISO
    echo ""
    echo "4. Checking ISO..."
    if [ -f build/cognica-os.iso ]; then
        echo "   ✓ ISO exists"
        ls -lh build/cognica-os.iso
    else
        echo "   ✗ ISO not found - run: make iso"
        exit 1
    fi
    
    echo ""
    echo "=== All checks passed! ==="
    echo ""
    echo "To boot:"
    echo "  make run"
    echo ""
    echo "Or manually:"
    echo "  qemu-system-x86_64 -cdrom build/cognica-os.iso -m 128M"
else
    echo "   ✗ Kernel not found - run: make"
    exit 1
fi

