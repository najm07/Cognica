# Windows Setup Guide

## Quick Start

### Option 1: Install NASM (Recommended)

1. Download NASM from https://www.nasm.us/
2. Install and add to PATH
3. Run: `.\build.ps1`

### Option 2: Use WSL (Windows Subsystem for Linux)

1. Install WSL: `wsl --install`
2. In WSL, install dependencies:
   ```bash
   sudo apt-get update
   sudo apt-get install build-essential nasm grub-pc-bin grub-common qemu-system-x86
   ```
3. Build in WSL using the Makefile:
   ```bash
   make
   make iso
   ```

### Option 3: Use MSYS2

1. Install MSYS2 from https://www.msys2.org/
2. In MSYS2 terminal:
   ```bash
   pacman -S mingw-w64-x86_64-gcc nasm mingw-w64-x86_64-binutils
   ```
3. Build using Makefile or PowerShell script

## PowerShell Build Script Usage

```powershell
# Check dependencies
.\build.ps1 -CheckDeps

# Build kernel
.\build.ps1

# Build and create ISO
.\build.ps1 -Iso

# Build, create ISO, and run in QEMU
.\build.ps1 -Iso -Run

# Clean build artifacts
.\build.ps1 -Clean
```

## Current Status

You have:
- ✓ GCC (MinGW)
- ✓ LD (MinGW)
- ✗ NASM (needed)
- ✗ GRUB tools (needed for ISO)

## Next Steps

1. Install NASM from https://www.nasm.us/
2. Add NASM to your PATH
3. Run `.\build.ps1 -CheckDeps` to verify
4. Run `.\build.ps1` to build the kernel

