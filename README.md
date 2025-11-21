# Cognica OS Kernel

A minimal operating system kernel written from scratch in C and x86 assembly.

## Features

- **Multiboot 2 compliant** - Boots with GRUB
- **VGA text mode** - 80x25 character display
- **Basic memory detection** - Reports available memory
- **Color text output** - Supports 16 VGA colors
- **Simple I/O** - Basic port I/O operations

## Requirements

- **GCC** - C compiler (with 32-bit support)
- **NASM** - x86 assembler
- **GNU LD** - Linker
- **GRUB** - Bootloader tools (grub-mkrescue)
- **QEMU** - For testing (optional)

### Installing on Ubuntu/Debian:
```bash
sudo apt-get install build-essential nasm grub-pc-bin grub-common qemu-system-x86
```

### Installing on Windows:

**Option 1: Using WSL (Recommended)**
1. Install WSL: `wsl --install`
2. Install Ubuntu: `wsl --install -d Ubuntu`
3. In WSL, install dependencies:
   ```bash
   sudo apt-get update
   sudo apt-get install build-essential nasm grub-pc-bin grub-common qemu-system-x86 xorriso
   ```

**Option 2: Using PowerShell Script**
- Run `.\build.ps1 -CheckDeps` to check dependencies
- Install missing tools (NASM, etc.)
- Use `.\build.ps1` to build (note: requires cross-compiler for linking)

See `WINDOWS_SETUP.md` for detailed Windows instructions.

## Building

### On Linux/WSL:
```bash
make
```

This will create `build/kernel.bin`.

### On Windows (PowerShell):
```powershell
.\build.ps1
```

Note: For full functionality on Windows, use WSL as MinGW's linker doesn't support ELF format required for kernels.

## Creating Bootable ISO

```bash
make iso
```

This creates `build/cognica-os.iso` which can be booted in a virtual machine.

## Running

### Using QEMU:
```bash
make run
```

Or manually:
```bash
qemu-system-i386 -cdrom build/cognica-os.iso -m 128M
```

### On Windows/WSL:
```powershell
wsl bash -c "cd /mnt/c/Users/mehdi/source/repos/Cognica && qemu-system-i386 -cdrom build/cognica-os.iso -m 128M"
```

Or use the test script:
```bash
./test-kernel.sh
```

See `TEST_KERNEL.md` for detailed testing instructions.

### Using VirtualBox/VMware:
1. Create a new virtual machine
2. Set the ISO file (`build/cognica-os.iso`) as the boot medium
3. Start the VM

## Project Structure

```
.
├── boot.asm              # Bootloader and kernel entry point
├── kernel.c              # Main kernel code
├── vga.h                 # VGA text mode header
├── vga.c                 # VGA text mode implementation
├── io.h                  # I/O port operations
├── linker.ld             # Linker script
├── Makefile              # Build system (Linux/WSL)
├── build.ps1             # PowerShell build script (Windows)
├── rebuild-iso.sh        # ISO creation script
├── test-kernel.sh        # Kernel testing script
├── verify-kernel.sh      # Kernel verification script
├── WINDOWS_SETUP.md      # Windows setup guide
├── CROSS_COMPILER_SETUP.md # Cross-compiler setup guide
├── TEST_KERNEL.md        # Testing instructions
└── README.md             # This file
```

## Architecture

- **Architecture**: x86 (32-bit protected mode)
- **Bootloader**: GRUB (Multiboot 2)
- **Display**: VGA text mode (0xB8000)
- **Stack**: 16 KB

## Development

The kernel is structured as follows:

1. **boot.asm** - Sets up the multiboot header, initializes the stack, and calls the kernel main function
2. **kernel.c** - Main kernel entry point that initializes subsystems and displays information
3. **vga.c/vga.h** - VGA text mode driver for screen output
4. **io.h** - Low-level I/O port operations

## Next Steps

Potential enhancements:
- Interrupt handling (IDT setup)
- Keyboard input
- Memory management (paging)
- Process scheduling
- File system support
- System calls

## License

This is a learning project. Feel free to use and modify as needed.

