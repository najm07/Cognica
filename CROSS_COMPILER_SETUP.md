# Cross-Compiler Setup for Kernel Development

## The Problem

MinGW's linker only supports PE (Windows executable) format, but kernels need ELF format. You need a cross-compiler to build the kernel.

## Option 1: Install Cross-Compiler on Windows

### Using MSYS2 (Recommended)

1. Install MSYS2 from https://www.msys2.org/
2. Open MSYS2 terminal and install cross-compiler:
   ```bash
   pacman -S mingw-w64-x86_64-gcc
   pacman -S mingw-w64-x86_64-binutils
   ```
3. Add MSYS2 bin directory to PATH:
   - `C:\msys64\mingw64\bin` (or wherever MSYS2 is installed)

### Manual Cross-Compiler Build

This is complex. Consider using WSL instead.

## Option 2: Use WSL (Windows Subsystem for Linux) - Easiest

1. Install WSL:
   ```powershell
   wsl --install
   ```
2. In WSL, install build tools:
   ```bash
   sudo apt-get update
   sudo apt-get install build-essential nasm grub-pc-bin grub-common qemu-system-x86
   ```
3. Build in WSL:
   ```bash
   cd /mnt/c/Users/mehdi/source/repos/Cognica
   make
   make iso
   ```

## Option 3: Use Docker

Create a Docker container with cross-compiler tools.

## Current Status

Your build is failing at the linking stage because:
- ✅ Compilation works (GCC, NASM are fine)
- ❌ Linking fails (MinGW ld doesn't support ELF)

## Quick Fix

The easiest solution is to use WSL. Your kernel code is ready, you just need the right build environment!

