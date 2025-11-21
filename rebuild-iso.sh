#!/bin/bash
cd "$(dirname "$0")"

echo "Rebuilding ISO with multiboot2..."

# Clean and rebuild
rm -rf isodir
mkdir -p isodir/boot/grub

# Copy kernel
cp build/kernel.bin isodir/boot/

# Create GRUB config with multiboot2
cat > isodir/boot/grub/grub.cfg << 'EOF'
set timeout=0
set default=0

menuentry "Cognica OS" {
    multiboot2 /boot/kernel.bin
    boot
}
EOF

# Create ISO
grub-mkrescue -o build/cognica-os.iso isodir

if [ -f build/cognica-os.iso ]; then
    echo "ISO created successfully: build/cognica-os.iso"
    ls -lh build/cognica-os.iso
else
    echo "ISO creation failed"
    exit 1
fi

