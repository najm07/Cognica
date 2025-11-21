# Compiler and tools
CC = gcc
ASM = nasm
LD = ld

# Flags
CFLAGS = -m64 -nostdlib -nostdinc -fno-builtin -fno-stack-protector \
         -nostartfiles -nodefaultlibs -Wall -Wextra -c \
         -mno-red-zone -mno-mmx -mno-sse -mno-sse2 \
         -finput-charset=utf-8 -fexec-charset=utf-8
ASMFLAGS = -f elf64
LDFLAGS = -m elf_x86_64 -T linker.ld

# Directories
SRC_DIR = .
BUILD_DIR = build
ISO_DIR = isodir
BOOT_DIR = $(ISO_DIR)/boot
GRUB_DIR = $(BOOT_DIR)/grub

# Source files
C_SOURCES = $(wildcard *.c)
ASM_SOURCES = $(wildcard *.asm)

# Object files
C_OBJECTS = $(C_SOURCES:%.c=$(BUILD_DIR)/%.o)
ASM_OBJECTS = $(ASM_SOURCES:%.asm=$(BUILD_DIR)/%.o)
OBJECTS = $(ASM_OBJECTS) $(C_OBJECTS)

# Output
KERNEL = $(BUILD_DIR)/kernel.bin
BOOTLOADER = $(BUILD_DIR)/bootloader.bin
FONT_BIN = $(BUILD_DIR)/fonts.bin
DISK_IMG = $(BUILD_DIR)/disk.img
ISO = $(BUILD_DIR)/cognica-os.iso

.PHONY: all clean run iso bootloader disk

all: $(KERNEL) bootloader

# Build bootloader (16-bit, raw binary)
bootloader: $(BOOTLOADER)

$(BOOTLOADER): bootloader.asm
	@echo "Building bootloader..."
	@mkdir -p $(BUILD_DIR)
	$(ASM) -f bin -o $@ $<
	@echo "Bootloader size: $$(stat -f%z $@ 2>/dev/null || stat -c%s $@ 2>/dev/null) bytes"

# Generate font binary from C source
$(FONT_BIN): arabic_font_data.c embed_fonts.py
	@echo "Generating font binary..."
	@mkdir -p $(BUILD_DIR)
	python3 embed_fonts.py arabic_font_data.c $@

# Create bootable disk image with bootloader + fonts + kernel
disk: $(BOOTLOADER) $(FONT_BIN) $(KERNEL)
	@echo "Creating bootable disk image..."
	@mkdir -p $(BUILD_DIR)
	# Create empty disk image (10MB)
	dd if=/dev/zero of=$(DISK_IMG) bs=1024 count=10240 2>/dev/null || \
		dd if=/dev/zero of=$(DISK_IMG) bs=1M count=10 2>/dev/null
	# Write bootloader to first sector
	dd if=$(BOOTLOADER) of=$(DISK_IMG) bs=512 count=1 conv=notrunc 2>/dev/null
	# Write font data to sectors 2-4
	dd if=$(FONT_BIN) of=$(DISK_IMG) bs=512 seek=1 conv=notrunc 2>/dev/null
	# Write kernel starting at sector 5
	dd if=$(KERNEL) of=$(DISK_IMG) bs=512 seek=4 conv=notrunc 2>/dev/null
	@echo "Disk image created: $(DISK_IMG)"

$(KERNEL): $(OBJECTS) linker.ld
	@echo "Linking kernel..."
	@mkdir -p $(BUILD_DIR)
	$(LD) $(LDFLAGS) -Map=$(BUILD_DIR)/kernel.map -o $@ $(OBJECTS)

$(BUILD_DIR)/%.o: %.c
	@echo "Compiling $<..."
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -o $@ $<

$(BUILD_DIR)/%.o: %.asm
	@echo "Assembling $<..."
	@mkdir -p $(BUILD_DIR)
	$(ASM) $(ASMFLAGS) -o $@ $<

iso: $(KERNEL)
	@echo "Creating bootable ISO..."
	@mkdir -p $(GRUB_DIR)
	@cp $(KERNEL) $(BOOT_DIR)/

	# === GRUB CONFIG ===
	@echo "set timeout=3" > $(GRUB_DIR)/grub.cfg
	@echo "set default=0" >> $(GRUB_DIR)/grub.cfg
	@echo "" >> $(GRUB_DIR)/grub.cfg
	@echo "menuentry \"Cognica OS\" {" >> $(GRUB_DIR)/grub.cfg
	@echo "	multiboot2 /boot/kernel.bin" >> $(GRUB_DIR)/grub.cfg
	@echo "	boot" >> $(GRUB_DIR)/grub.cfg
	@echo "}" >> $(GRUB_DIR)/grub.cfg

	# === Create bootable ISO ===
	grub-mkrescue -o $(ISO) $(ISO_DIR) 2>&1

	@echo "ISO created successfully: $(ISO)"

run: iso
	@echo "Launching QEMU..."
	qemu-system-x86_64 -cdrom $(ISO) -m 128M -boot d -no-reboot

debug: iso
	@echo "Launching QEMU with debug output..."
	qemu-system-x86_64 -cdrom $(ISO) -m 128M -boot d -d int -no-reboot

clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR) $(ISO_DIR)
	@echo "Clean complete."