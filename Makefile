# Compiler and tools
CC = gcc
ASM = nasm
LD = ld

# Flags
CFLAGS = -m32 -nostdlib -nostdinc -fno-builtin -fno-stack-protector \
         -nostartfiles -nodefaultlibs -Wall -Wextra -c
ASMFLAGS = -f elf32
LDFLAGS = -m elf_i386 -T linker.ld

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
ISO = $(BUILD_DIR)/cognica-os.iso

.PHONY: all clean run iso

all: $(KERNEL)

$(KERNEL): $(OBJECTS) linker.ld
	@echo "Linking kernel..."
	@mkdir -p $(BUILD_DIR)
	$(LD) $(LDFLAGS) -o $@ $(OBJECTS)

$(BUILD_DIR)/%.o: %.c
	@echo "Compiling $<..."
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -o $@ $<

$(BUILD_DIR)/%.o: %.asm
	@echo "Assembling $<..."
	@mkdir -p $(BUILD_DIR)
	$(ASM) $(ASMFLAGS) -o $@ $<

iso: $(KERNEL)
	@echo "Creating ISO image..."
	@mkdir -p $(GRUB_DIR)
	@cp $(KERNEL) $(BOOT_DIR)/
	@echo "set timeout=0" > $(GRUB_DIR)/grub.cfg
	@echo "set default=0" >> $(GRUB_DIR)/grub.cfg
	@echo "" >> $(GRUB_DIR)/grub.cfg
	@echo "menuentry \"Cognica OS\" {" >> $(GRUB_DIR)/grub.cfg
	@echo "	multiboot2 /boot/kernel.bin" >> $(GRUB_DIR)/grub.cfg
	@echo "	boot" >> $(GRUB_DIR)/grub.cfg
	@echo "}" >> $(GRUB_DIR)/grub.cfg
	grub-mkrescue -o $(ISO) $(ISO_DIR)
	@echo "ISO created: $(ISO)"

run: iso
	@echo "Starting QEMU..."
	qemu-system-i386 -cdrom $(ISO)

clean:
	@echo "Cleaning..."
	rm -rf $(BUILD_DIR) $(ISO_DIR)
	@echo "Clean complete."

