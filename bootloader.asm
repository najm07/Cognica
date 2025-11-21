; Custom Bootloader for Arabic Font Loading
; Loads Arabic fonts into VGA character generator RAM using BIOS INT 10h
; Then loads and executes the kernel

[BITS 16]
[ORG 0x7C00]

; Bootloader entry point
start:
    ; Set up segment registers
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00  ; Stack grows downward from bootloader
    
    sti
    
    ; Save boot drive (DL contains boot drive number)
    mov [boot_drive], dl
    
    ; Print boot message
    mov si, msg_booting
    call print_string
    
    ; Load Arabic fonts into VGA character generator RAM
    call load_arabic_fonts
    
    ; Print success message
    mov si, msg_fonts_loaded
    call print_string
    
    ; Load kernel from disk
    call load_kernel
    
    ; Switch to protected mode and jump to kernel
    call switch_to_protected_mode
    
    ; Should never reach here
    jmp halt

; Load Arabic fonts into VGA character generator RAM using BIOS INT 10h
load_arabic_fonts:
    pusha
    
    ; First, load font data from disk to memory
    ; Font data is stored in sectors 2-4 (3 sectors = 1536 bytes, enough for 96 chars)
    ; We'll load it to 0x7E00 (after bootloader)
    mov si, msg_loading_fonts
    call print_string
    
    ; Reset disk
    mov ah, 0x00
    mov dl, [boot_drive]
    int 0x13
    jc .font_error
    
    ; Load font sectors (sectors 2-4, 3 sectors = 1536 bytes)
    mov ax, 0x07E0  ; Segment for 0x7E00
    mov es, ax
    mov bx, 0x0000  ; Offset 0
    
    mov ah, 0x02    ; Read sectors
    mov al, 3       ; 3 sectors (enough for fonts)
    mov ch, 0       ; Cylinder 0
    mov cl, 2       ; Sector 2 (after bootloader)
    mov dh, 0       ; Head 0
    mov dl, [boot_drive]
    int 0x13
    jc .font_error
    
    ; Now load fonts into VGA using BIOS INT 10h
    ; BIOS INT 10h, AH=11h, AL=20h: Set user 8x16 font
    mov ax, 0x07E0  ; Segment for font data
    mov es, ax
    mov bp, 0x0000  ; Offset to font data
    
    ; Load font forms (0x80-0xEF, 112 characters = 1792 bytes)
    ; We'll load in two batches due to BIOS limitations
    mov ax, 0x1120  ; AH=11h (character generator), AL=20h (set user 8x16 font)
    mov bh, 16      ; 16 bytes per character
    mov bl, 0       ; Block 0
    mov cx, 96      ; Load first 96 characters (fits in 3 sectors)
    mov dx, 0x0080  ; Start at character 0x80
    int 0x10
    
    ; Load remaining 16 forms if we have space (would need 4th sector)
    ; For now, we'll load what we can
    
    mov si, msg_fonts_loaded
    call print_string
    popa
    ret
    
.font_error:
    mov si, msg_font_error
    call print_string
    popa
    ret

; Load kernel from disk
load_kernel:
    pusha
    
    ; Reset disk system
    mov ah, 0x00
    mov dl, [boot_drive]
    int 0x13
    jc disk_error
    
    ; Load kernel from sectors 2-63 (assuming kernel fits in 62 sectors)
    ; Kernel starts at LBA 1 (sector 2, since bootloader is sector 1)
    mov si, msg_loading_kernel
    call print_string
    
    ; Set up disk address packet for LBA read
    mov ax, 0x1000  ; Load kernel to 0x10000 (64KB)
    mov es, ax
    mov bx, 0x0000  ; Offset 0
    
    ; Read sectors using INT 13h, AH=02h (CHS) or INT 13h, AH=42h (LBA)
    ; For simplicity, use CHS addressing
    mov ah, 0x02    ; Read sectors
    mov al, 62      ; Number of sectors to read
    mov ch, 0       ; Cylinder 0
    mov cl, 2       ; Sector 2 (bootloader is sector 1)
    mov dh, 0       ; Head 0
    mov dl, [boot_drive]
    int 0x13
    jc disk_error
    
    mov si, msg_kernel_loaded
    call print_string
    
    popa
    ret

disk_error:
    mov si, msg_disk_error
    call print_string
    jmp halt

; Switch to protected mode and jump to kernel
switch_to_protected_mode:
    cli
    
    ; Load GDT
    lgdt [gdt_descriptor]
    
    ; Enable A20 line
    call enable_a20
    
    ; Set protected mode bit in CR0
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    
    ; Far jump to 32-bit code
    jmp CODE_SEG:protected_mode_start

enable_a20:
    ; Try BIOS method first
    mov ax, 0x2401
    int 0x15
    ret

[BITS 32]
protected_mode_start:
    ; Set up segment registers
    mov ax, DATA_SEG
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    
    ; Set up stack
    mov esp, 0x90000
    
    ; Jump to kernel (loaded at 0x10000)
    jmp 0x10000

[BITS 16]
; Print string (null-terminated)
print_string:
    pusha
    mov ah, 0x0E  ; BIOS teletype function
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    popa
    ret

halt:
    cli
    hlt
    jmp halt

; Data section
msg_booting:        db 'Booting...', 13, 10, 0
msg_loading_fonts:  db 'Loading fonts...', 13, 10, 0
msg_fonts_loaded:   db 'Fonts loaded!', 13, 10, 0
msg_font_error:     db 'Font load error!', 13, 10, 0
msg_loading_kernel: db 'Loading kernel...', 13, 10, 0
msg_kernel_loaded:  db 'Kernel loaded!', 13, 10, 0
msg_disk_error:     db 'Disk error!', 13, 10, 0
boot_drive:         db 0

; GDT for protected mode
gdt_start:
    ; Null descriptor
    dd 0x0
    dd 0x0
    
    ; Code segment (base=0x0, limit=0xFFFFF, type=0x9A, flags=0xC)
    dw 0xFFFF      ; Limit (bits 0-15)
    dw 0x0         ; Base (bits 0-15)
    db 0x0         ; Base (bits 16-23)
    db 10011010b   ; Access byte
    db 11001111b   ; Flags + Limit (bits 16-19)
    db 0x0         ; Base (bits 24-31)
    
    ; Data segment (base=0x0, limit=0xFFFFF, type=0x92, flags=0xC)
    dw 0xFFFF      ; Limit (bits 0-15)
    dw 0x0         ; Base (bits 0-15)
    db 0x0         ; Base (bits 16-23)
    db 10010010b   ; Access byte
    db 11001111b   ; Flags + Limit (bits 16-19)
    db 0x0         ; Base (bits 24-31)
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1  ; Size
    dd gdt_start                 ; Address

CODE_SEG equ gdt_start + 8
DATA_SEG equ gdt_start + 16

; Boot signature (must be at offset 510-511)
times 510-($-$$) db 0
dw 0xAA55
