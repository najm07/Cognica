# Cognica OS Kernel

A minimal operating system kernel written from scratch in C and x86 assembly.

## Features

- **Multiboot 2 compliant** - Boots with GRUB
- **VGA text mode** - 80x25 character display
- **Basic memory detection** - Reports available memory
- **Color text output** - Supports 16 VGA colors
- **Simple I/O** - Basic port I/O operations
- **RTL-native text rendering** - Right-to-left native mode (column 0 = rightmost)
- **Arabic script support** - UTF-8 decoding and Arabic character mapping
- **64-bit long mode** - Full x86-64 support with proper paging setup

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
qemu-system-x86_64 -cdrom build/cognica-os.iso -m 128M
```

### On Windows/WSL:
```powershell
wsl bash -c "cd /mnt/c/Users/mehdi/source/repos/Cognica && qemu-system-x86_64 -cdrom build/cognica-os.iso -m 128M"
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
├── boot.asm              # Bootloader and kernel entry point (32-bit to 64-bit transition)
├── kernel.c              # Main kernel code
├── vga.h                 # VGA text mode header
├── vga.c                 # VGA text mode implementation (RTL-native)
├── vga_font.h            # VGA font loading header
├── vga_font.c            # UTF-8 decoding and Arabic font support
├── arabic_font.h         # Arabic font bitmap definitions
├── arabic_font_data.c    # Arabic font bitmap data
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

- **Architecture**: x86-64 (64-bit long mode)
- **Bootloader**: GRUB (Multiboot 2)
- **Display**: VGA text mode (0xB8000)
- **Stack**: 16 KB (64-bit)
- **Calling Convention**: System V AMD64 ABI

## Development

The kernel is structured as follows:

1. **boot.asm** - Sets up the multiboot header, initializes paging, transitions from 32-bit to 64-bit mode, and calls the kernel main function
2. **kernel.c** - Main kernel entry point that initializes subsystems and displays information
3. **vga.c/vga.h** - VGA text mode driver with RTL-native support (column 0 = rightmost)
4. **vga_font.c/vga_font.h** - UTF-8 decoding and Arabic character mapping to custom font codes
5. **arabic_font_data.c/arabic_font.h** - Arabic font bitmap definitions (8x16 pixels)
6. **io.h** - Low-level I/O port operations

## Text Rendering Features

### RTL-Native Mode
The kernel supports right-to-left (RTL) native text rendering by default:
- Column 0 represents the rightmost position on screen
- Text flows from right to left naturally
- Can be switched to LTR mode using `vga_set_rtl_mode(0)`

### Arabic Script Support
- UTF-8 string decoding for Arabic Unicode characters
- Maps Arabic characters to extended ASCII codes (0x80-0x9B)
- Supports common Arabic letters: ا, ب, ت, ث, ج, ح, خ, د, ذ, ر, ز, س, ش, ص, ض, ط, ظ, ع, غ, ف, ق, ك, ل, م, ن, ه, و, ي

**Note:** Actual Arabic font glyph loading into VGA character generator RAM is currently disabled due to compatibility issues in protected mode. The UTF-8 decoding and character mapping infrastructure is in place.

## Next Steps

Potential enhancements:
- Interrupt handling (IDT setup)
- Keyboard input
- Memory management (paging) - Currently basic identity mapping
- Process scheduling
- File system support
- System calls
- Proper VGA font loading (requires BIOS calls or mode switching)

## License

This is a learning project. Feel free to use and modify as needed.

