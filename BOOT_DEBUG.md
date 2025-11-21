# Boot Debugging Guide

## Common 64-bit Boot Issues

### Issue 1: Triple Fault / Immediate Reboot
**Symptoms:** System reboots immediately after GRUB loads kernel

**Possible Causes:**
- Page table setup incorrect
- GDT not properly loaded
- Stack not properly set up
- Invalid memory access

**Fix:** Check page table addresses are identity mapped correctly

### Issue 2: "No Multiboot Header Found"
**Symptoms:** GRUB can't find multiboot header

**Possible Causes:**
- Header not at correct location
- Wrong multiboot version
- Checksum incorrect

**Fix:** Verify header is at start of .text section

### Issue 3: Kernel Hangs / Freezes
**Symptoms:** Screen goes black, nothing happens

**Possible Causes:**
- Long mode transition failed
- Page fault during boot
- Invalid GDT entry
- Stack overflow

**Fix:** Add debug output or use QEMU monitor

## Debugging Commands

### Check Kernel Structure
```bash
objdump -h build/kernel.bin
readelf -l build/kernel.bin
```

### Test with QEMU Monitor
```bash
qemu-system-x86_64 -cdrom build/cognica-os.iso -m 128M -monitor stdio
```
Then in monitor: `info registers`, `x/10i $pc`

### Check Multiboot Header
```bash
grub-file --is-x86-multiboot2 build/kernel.bin
```

## Current Kernel Status

- Architecture: x86-64 (64-bit)
- Entry Point: 0x100018
- Page Tables: Identity mapped at 0x101000-0x104000
- Stack: 0x10c000 (64-bit)
- GDT: In .data section

