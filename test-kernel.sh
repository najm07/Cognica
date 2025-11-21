#!/bin/bash
# Test script for Cognica OS kernel

cd "$(dirname "$0")"

echo "=== Cognica OS Kernel Test ==="
echo ""
echo "Starting QEMU with kernel ISO..."
echo "Press Ctrl+Alt+G to release mouse/keyboard from QEMU"
echo "Press Ctrl+C to stop QEMU"
echo ""

# Check if running in WSL
if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null ; then
    echo "Detected WSL environment"
    # Try to use WSLg (Windows 11) or fallback to VNC
    if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
        echo "Using GUI display..."
        qemu-system-x86_64 -cdrom build/cognica-os.iso -m 128M
    else
        echo "No display available. Starting with VNC server on localhost:1"
        echo "Connect with: vncviewer localhost:1"
        qemu-system-x86_64 -cdrom build/cognica-os.iso -m 128M -vnc :1
    fi
else
    # Native Linux
    qemu-system-x86_64 -cdrom build/cognica-os.iso -m 128M
fi

