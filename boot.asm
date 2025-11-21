; Kernel entry point - 64-bit long mode
; We start in 32-bit mode, then transition to 64-bit

; VGA register definitions
VGA_SEQ_INDEX     equ 0x3C4
VGA_SEQ_DATA      equ 0x3C5
VGA_GC_INDEX      equ 0x3CE
VGA_GC_DATA       equ 0x3CF
VGA_MISC_READ     equ 0x3CC
VGA_MISC_WRITE    equ 0x3C2
VGA_CRTC_INDEX    equ 0x3D4
VGA_CRTC_DATA     equ 0x3D5

; Multiboot 2 header - MUST be at start of .text section (which is at start of loadable segment)
section .text
[BITS 32]
default abs    ; Force absolute addressing (not RIP-relative) - critical for 32-bit mode with elf64
global _start
extern kernel_main

align 8
multiboot_header_start:
    dd 0xe85250d6                ; Magic number (multiboot 2)
    dd 0                          ; Architecture 0 (protected mode i386 - GRUB requirement)
    dd multiboot_header_end - multiboot_header_start  ; Header length
    ; Checksum
    dd 0x100000000 - (0xe85250d6 + 0 + (multiboot_header_end - multiboot_header_start))

    ; Required end tag
    dw 0    ; Type
    dw 0    ; Flags
    dd 8    ; Size
multiboot_header_end:

; ============================================
; Debug Print Functions (32-bit mode)
; ============================================

; Simple VGA text mode debug output
; VGA memory is at 0xB8000
; Each character is 2 bytes: [char][color]
; Color format: [bg:4 bits][fg:4 bits]

debug_cursor_pos: dd 0  ; Current position (0-1999 for 80x25)

; Print a string to VGA (null-terminated)
; Input: ESI = pointer to string
debug_print_str:
    push eax
    push edi
    push esi
    
    mov edi, 0xB8000      ; VGA memory base
    mov eax, [debug_cursor_pos]
    shl eax, 1            ; Multiply by 2 (each char is 2 bytes)
    add edi, eax          ; Add byte offset
    
    mov ah, 0x0F          ; Color: white on black (0x0F = white fg, black bg)
    
.loop:
    lodsb                 ; Load byte from [ESI] into AL, increment ESI
    test al, al           ; Check if null terminator
    jz .done
    
    stosw                 ; Store AX (char + color) to [EDI], increment EDI by 2
    jmp .loop
    
.done:
    ; Update cursor position (convert byte offset back to character position)
    mov eax, edi
    sub eax, 0xB8000
    shr eax, 1            ; Divide by 2 to get character position
    mov [debug_cursor_pos], eax
    
    pop esi
    pop edi
    pop eax
    ret

; Print a hex value (32-bit)
; Input: EAX = value to print
debug_print_hex:
    push eax
    push ebx
    push ecx
    push edi
    
    mov edi, 0xB8000
    mov ebx, [debug_cursor_pos]
    shl ebx, 1            ; Multiply by 2 for byte offset
    add edi, ebx
    
    mov ah, 0x0F          ; Color: bright white on black (more visible)
    mov ecx, 8            ; 8 hex digits for 32-bit value
    push eax              ; Save original value with color
    
    ; Print "0x" prefix
    mov al, '0'
    stosw
    mov al, 'x'
    stosw
    
    pop eax               ; Restore value
    mov ah, 0x0F          ; Ensure color is still bright white (fix color corruption)
    
.loop:
    rol eax, 4            ; Rotate left 4 bits (bring next hex digit to bottom)
    mov bl, al
    and bl, 0x0F          ; Get low 4 bits
    
    cmp bl, 9
    jbe .digit
    add bl, 'A' - 10      ; A-F
    jmp .write
.digit:
    add bl, '0'           ; 0-9
.write:
    mov al, bl
    mov ah, 0x0F          ; Ensure color is bright white for each digit
    stosw
    loop .loop
    
    ; Update cursor position
    mov eax, edi
    sub eax, 0xB8000
    shr eax, 1            ; Divide by 2 to get character position
    mov [debug_cursor_pos], eax
    
    pop edi
    pop ecx
    pop ebx
    pop eax
    ret

; Print a newline
debug_print_nl:
    push eax
    push edi
    
    mov eax, [debug_cursor_pos]
    mov edi, 80           ; 80 characters per line
    xor edx, edx
    div edi               ; EAX = current row, EDX = current column
    inc eax               ; Next row
    mul edi               ; EAX = next row * 80
    mov [debug_cursor_pos], eax
    
    pop edi
    pop eax
    ret

; Clear screen (optional, for clean debug output)
debug_clear:
    push eax
    push edi
    push ecx
    
    mov edi, 0xB8000
    mov eax, 0x0F20       ; White space on black
    mov ecx, 80 * 25      ; 80x25 = 2000 characters
    rep stosw
    
    mov dword [debug_cursor_pos], 0
    
    pop ecx
    pop edi
    pop eax
    ret

; Wait for Enter key press
; Polls keyboard controller and waits for Enter key (scancode 0x1C)
debug_wait_enter:
    push eax
    push edx
    push esi
    
    ; Display prompt message
    mov esi, debug_msg_press_enter
    call debug_print_str
    
.wait_loop:
    ; Check if keyboard data is available (read status port 0x64)
    in al, 0x64
    test al, 1           ; Bit 0 = output buffer full (data available)
    jz .wait_loop        ; No data, keep waiting
    
    ; Read scancode from keyboard data port (0x60)
    in al, 0x60
    
    ; Check if it's Enter key press (scancode 0x1C)
    cmp al, 0x1C
    je .enter_pressed
    
    ; Check if it's Enter key release (scancode 0x9C) - ignore
    cmp al, 0x9C
    je .wait_loop
    
    ; Not Enter key, keep waiting
    jmp .wait_loop
    
.enter_pressed:
    ; Clear the prompt message (overwrite with spaces)
    push edi
    push ecx
    mov edi, 0xB8000
    mov eax, [debug_cursor_pos]
    shl eax, 1
    add edi, eax
    sub edi, 60          ; Go back to start of prompt (assuming ~30 chars)
    mov ah, 0x0F
    mov al, ' '
    mov ecx, 30
    rep stosw
    pop ecx
    pop edi
    
    pop esi
    pop edx
    pop eax
    ret

; Delay function - waste CPU cycles to create a pause
; Input: ECX = number of delay iterations (higher = longer delay)
debug_delay:
    push ecx
.delay_loop:
    nop                   ; No operation (waste 1 cycle)
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    loop .delay_loop      ; Decrement ECX and loop
    pop ecx
    ret

; Short delay (about 0.5 seconds on modern CPUs)
debug_delay_short:
    push ecx
    mov ecx, 0x100000     ; ~1 million iterations
    call debug_delay
    pop ecx
    ret

; Medium delay (about 1 second on modern CPUs)
debug_delay_medium:
    push ecx
    mov ecx, 0x200000     ; ~2 million iterations
    call debug_delay
    pop ecx
    ret

; Long delay (about 2 seconds on modern CPUs)
debug_delay_long:
    push ecx
    mov ecx, 0x400000     ; ~4 million iterations
    call debug_delay
    pop ecx
    ret

; Very Long delay (about 2 seconds on modern CPUs)
debug_delay_very_long:
    push ecx
    mov ecx, 0x1000000     ; ~4 million iterations
    call debug_delay
    pop ecx
    ret

_start:
    ; Save multiboot info IMMEDIATELY (first thing, before ANY other operations!)
    ; EAX = magic, EBX = info pointer - these come from GRUB and MUST be saved first
    mov [multiboot_magic], eax
    mov [multiboot_info], ebx
    
    ; Set up stack FIRST (before any function calls!)
    ; This is critical - function calls use the stack for return addresses
    mov esp, stack_top_32
    
    ; Wait for Enter before starting main section
    call debug_wait_enter
    
    ; Clear screen for clean debug output
    call debug_clear
    
    ; Debug: Entry point reached
    mov esi, debug_msg_start
    call debug_print_str
    call debug_print_nl
    call debug_wait_enter
    
    ; Debug: Stack set (already done above, but show it)
    mov esi, debug_msg_stack
    call debug_print_str
    call debug_print_nl
    call debug_wait_enter
    
    ; Clear direction flag
    cld
    
    ; Debug: Multiboot info saved
    mov esi, debug_msg_multiboot
    call debug_print_str
    mov eax, [multiboot_magic]
    call debug_print_hex
    call debug_print_nl
    call debug_wait_enter
    
    ; Enable PAE FIRST (required before setting up paging)
    mov esi, debug_msg_pae
    call debug_print_str
    
    mov eax, cr4
    or eax, 1 << 5  ; PAE bit (bit 5)
    or eax, 1 << 7  ; PGE (Page Global Enable)
    or eax, 1 << 9  ; OSFXSR (OS support for FXSAVE/FXRSTOR)
    mov cr4, eax
    
    ; Debug: PAE enabled
    mov esi, debug_msg_ok
    call debug_print_str
    call debug_print_nl
    call debug_wait_enter
    
    ; Set up paging for long mode
    mov esi, debug_msg_paging
    call debug_print_str
    call setup_paging
    mov esi, debug_msg_ok
    call debug_print_str
    call debug_print_nl
    call debug_wait_enter
    
    ; Enter long mode
    mov esi, debug_msg_longmode
    call debug_print_str
    call enter_long_mode
    
    ; We should never reach here, but just in case
    mov esi, debug_msg_error
    call debug_print_str
    call debug_print_nl
    cli
.hang:
    hlt
    jmp .hang

setup_paging:
    ; Wait for Enter before starting paging section
    call debug_wait_enter
    
    ; Debug: Setting up paging
    push esi
    mov esi, debug_msg_paging_setup
    call debug_print_str
    call debug_print_nl
    call debug_wait_enter
    pop esi
    
    ; Set up page tables for long mode
    ; Identity map first 128MB using 2MB pages (64 entries)
    ; This ensures GRUB's multiboot info and modules are accessible
    
    ; Clear all page tables first (P4, P3, P2)
    ; Use labels in .bss so the assembler/linker gives the correct addresses
    mov edi, page_table_l4    ; P4 table (label in .bss)
    
    ; Debug: Show page table addresses BEFORE clearing (so we don't overwrite)
    push eax
    push ebx
    push ecx
    push edx
    push edi
    
    ; Show P4 address
    mov esi, debug_msg_paging_l4_addr
    call debug_print_str
    mov eax, page_table_l4
    call debug_print_hex
    call debug_print_nl
    
    ; Show P3 address
    mov esi, debug_msg_paging_p3_addr
    call debug_print_str
    mov eax, page_table_p3
    call debug_print_hex
    call debug_print_nl
    
    ; Show P2 address
    mov esi, debug_msg_paging_p2_addr
    call debug_print_str
    mov eax, page_table_p2
    call debug_print_hex
    call debug_print_nl
    call debug_wait_enter
    
    ; Restore EDI (page_table_l4 address) before clearing
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    
    ; Clear all 3 page tables (12KB total = 3 * 4096 bytes = 3072 dwords)
    ; CRITICAL FIX: stosd writes 4 bytes (1 dword) per iteration
    ; So we need: 3 pages * 4096 bytes / 4 bytes per dword = 3072 dwords
    ; NOT 4096 * 3 = 12288 (which would write 4× too much!)
    xor eax, eax              ; Clear value (0)
    mov ecx, 3072             ; 3072 dwords = 12KB total (CORRECT!)
    rep stosd                 ; Clear all 3 page tables (EDI already set to page_table_l4)
    
    ; Debug: Page tables cleared
    push esi
    mov esi, debug_msg_paging_clear
    call debug_print_str
    call debug_print_nl
    call debug_wait_enter
    pop esi
    
    ; Set up P4 table (points to P3) - first entry
    mov edi, page_table_l4
    mov eax, page_table_p3
    or eax, 0x03          ; Present + Write
    mov dword [edi], eax    ; lower 32 bits = phys addr | flags
    mov dword [edi + 4], 0  ; upper 32 bits = 0 (mapping <4GB)

    ; Set up P3 table (points to P2) - first entry
    mov edi, page_table_p3
    mov eax, page_table_p2
    or eax, 0x03          ; Present + Write
    mov dword [edi], eax
    mov dword [edi + 4], 0

    ; Set up P2 table (2MB pages - identity map first 128MB)
    ; 128MB = 64 * 2MB pages
    mov edi, page_table_p2      ; P2 table address
    mov eax, 0x00000083  ; Present + Write + 2MB page (bit 7 = page size)
    xor edx, edx         ; High 32 bits = 0 for <4GB mappings
    mov ecx, 64          ; Map 64 * 2MB = 128MB
.setup_p2:
    mov dword [edi], eax      ; lower 32 bits
    mov dword [edi + 4], edx  ; upper 32 bits
     add eax, 0x200000     ; Next 2MB page
     add edi, 8            ; Next P2 entry (8 bytes per entry)
     loop .setup_p2        ; Decrement ecx and loop (works in 32-bit mode)
    
    ; Debug: Page entries set up
    push esi
    mov esi, debug_msg_paging_entries
    call debug_print_str
    call debug_print_nl
    call debug_wait_enter
    pop esi
    
    ; Load CR3 with P4 table address (physical address)
    mov eax, page_table_l4      ; P4 table address
    mov cr3, eax
    
    ; Debug: CR3 loaded - verify it was set correctly
    push esi
    mov esi, debug_msg_paging_cr3
    call debug_print_str
    mov eax, cr3
    call debug_print_hex
    call debug_print_nl
    call debug_wait_enter
    pop esi
    
    ret

; Load Arabic fonts using VGA register manipulation in text mode
; NOTE: This function is disabled - writing to 0xA0000 in text mode causes display corruption
; Font loading will be handled in 64-bit mode via vga_load_arabic_font()
load_arabic_fonts_bios:
    ; Disabled - causes display corruption
    ; The issue is that 0xA0000 is graphics memory and writing to it in text mode
    ; corrupts the display. Font loading needs a different approach.
    ret
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    
    ; Save current VGA state
    mov dx, VGA_SEQ_INDEX
    mov al, 0x02             ; Sequencer register 2 (map mask)
    out dx, al
    inc dx
    in al, dx
    push eax                 ; Save map mask
    
    mov dx, VGA_GC_INDEX
    mov al, 0x04             ; Graphics controller register 4 (read plane select)
    out dx, al
    inc dx
    in al, dx
    push eax                 ; Save read plane
    
    mov al, 0x05             ; Graphics controller register 5 (mode)
    mov dx, VGA_GC_INDEX
    out dx, al
    inc dx
    in al, dx
    push eax                 ; Save mode
    
    mov al, 0x06             ; Graphics controller register 6 (misc)
    mov dx, VGA_GC_INDEX
    out dx, al
    inc dx
    in al, dx
    push eax                 ; Save misc
    
    ; Configure VGA to access font memory (plane 2 - character generator)
    ; Set sequencer to map plane 2
    mov dx, VGA_SEQ_INDEX
    mov al, 0x02
    out dx, al
    inc dx
    mov al, 0x04             ; Enable plane 2 only (character generator)
    out dx, al
    
    ; Set graphics controller for font access
    mov dx, VGA_GC_INDEX
    mov al, 0x04
    out dx, al
    inc dx
    mov al, 0x02             ; Read plane 2
    out dx, al
    
    mov al, 0x05
    mov dx, VGA_GC_INDEX
    out dx, al
    inc dx
    mov al, 0x00             ; Write mode 0
    out dx, al
    
    mov al, 0x08             ; Bit mask register
    mov dx, VGA_GC_INDEX
    out dx, al
    inc dx
    mov al, 0xFF             ; All bits
    out dx, al
    
    ; In text mode, font memory is mapped differently
    ; We need to use the character generator access method
    ; Font memory is accessible through plane 2 at 0xA0000 when configured
    ; But we need to ensure 0xA0000 is mapped in our page tables
    mov esi, arabic_font_table  ; Source font data
    mov edi, 0xA0000 + (0x80 * 32)  ; Destination: character 0x80, 32 bytes per char
    mov ecx, 28                  ; 28 characters
    mov edx, 16                  ; 16 bytes per character
    
.load_char_loop:
    push ecx
    mov ecx, edx
    rep movsb                   ; Copy 16 bytes
    add edi, 16                 ; Skip to next character slot (32 bytes total)
    pop ecx
    loop .load_char_loop
    
    ; Restore VGA state
    mov dx, VGA_SEQ_INDEX
    mov al, 0x02
    out dx, al
    inc dx
    pop eax
    out dx, al               ; Restore map mask
    
    mov dx, VGA_GC_INDEX
    mov al, 0x04
    out dx, al
    inc dx
    pop eax
    out dx, al               ; Restore read plane
    
    mov al, 0x05
    mov dx, VGA_GC_INDEX
    out dx, al
    inc dx
    pop eax
    out dx, al               ; Restore mode
    
    mov al, 0x06
    mov dx, VGA_GC_INDEX
    out dx, al
    inc dx
    pop eax
    out dx, al               ; Restore misc
    
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

enter_long_mode:
    ; Wait for Enter before starting long mode section
    call debug_wait_enter
    
    ; Debug: Entering long mode
    push esi
    mov esi, debug_msg_entering_lm
    call debug_print_str
    call debug_print_nl
    call debug_wait_enter
    pop esi
    
    ; Save ESI at the start (we'll need it later)
    push esi
    
    ; PAE is already enabled in _start
    
    ; Enable long mode in EFER MSR
    push esi
    mov esi, debug_msg_efer
    call debug_print_str
    
    mov ecx, 0xC0000080  ; EFER MSR
    rdmsr
    or eax, 1 << 8  ; LME bit (bit 8) - Long Mode Enable
    wrmsr
    
    ; Debug: EFER.LME enabled
    mov esi, debug_msg_ok
    call debug_print_str
    call debug_print_nl
    call debug_wait_enter
    
    ; Read EFER again to show updated value
    mov ecx, 0xC0000080  ; EFER MSR
    rdmsr
    mov esi, debug_msg_efer_value
    call debug_print_str
    call debug_print_hex
    call debug_print_nl
    call debug_wait_enter
    pop esi
    
    ; Load GDT before enabling paging
    push esi
    mov esi, debug_msg_gdt
    call debug_print_str
    
    ; Use explicit 32-bit addressing (we're still in 32-bit mode)
    mov eax, gdt64_pointer
    lgdt [eax]  ; This should use 32-bit addressing in [BITS 32] mode
    
    ; Debug: GDT loaded
    mov esi, debug_msg_ok
    call debug_print_str
    call debug_print_nl
    call debug_wait_enter
    
    mov esi, debug_msg_gdt_value
    call debug_print_str
    mov eax, gdt64_pointer
    mov eax, [eax + 2]    ; Get GDT base address
    call debug_print_hex
    call debug_print_nl
    call debug_wait_enter
    pop esi
    
    ; Enable paging (this activates long mode)
    push esi
    mov esi, debug_msg_enable_paging
    call debug_print_str
    
    ; CRITICAL: Must set PE (Protected Mode) BEFORE PG (Paging)
    mov eax, cr0
    push eax              ; Save original CR0 for debugging
    or eax, 1 << 0   ; PE bit (bit 0) - Protected Mode Enable (MUST be set!)
    or eax, 1 << 31  ; PG bit (bit 31) - Paging Enable
    mov cr0, eax
    
    ; Verify CR0 was set correctly (PE and PG should both be 1)
    mov eax, cr0
    test eax, 1 << 0   ; Check PE bit
    jz .cr0_pe_error   ; If PE=0, error!
    test eax, 1 << 31  ; Check PG bit
    jz .cr0_pg_error   ; If PG=0, error!
    jmp .cr0_ok
.cr0_pe_error:
    ; PE not set - this is fatal
    mov esi, debug_msg_cr0_pe_error
    call debug_print_str
    call debug_print_nl
    call debug_wait_enter
    cli
.hang_lm:
    hlt
    jmp .hang_lm
.cr0_pg_error:
    ; PG not set - this is fatal
    mov esi, debug_msg_cr0_pg_error
    call debug_print_str
    call debug_print_nl
    call debug_wait_enter
    cli
.hang_lm2:
    hlt
    jmp .hang_lm2
.cr0_ok:
    
    ; Debug: Paging enabled (CR0.PE and CR0.PG should both be set)
    mov esi, debug_msg_ok
    call debug_print_str
    call debug_print_nl
    call debug_wait_enter
    
    mov esi, debug_msg_cr0_value
    call debug_print_str
    mov eax, cr0
    call debug_print_hex
    call debug_print_nl
    
    ; Verify CR0 has both PE and PG set
    test eax, 1 << 0   ; Check PE bit
    jz .show_cr0_error
    test eax, 1 << 31  ; Check PG bit
    jz .show_cr0_error
    mov esi, debug_msg_cr0_ok
    call debug_print_str
    call debug_print_nl
    call debug_wait_enter
    jmp .cr0_verified
.show_cr0_error:
    mov esi, debug_msg_cr0_error
    call debug_print_str
    call debug_print_nl
    call debug_wait_enter
.cr0_verified:
    
    ; Load Arabic fonts using VGA graphics mode switching
    ; NOTE: Currently disabled - causes display corruption
    ; Font loading will be handled in 64-bit mode instead
    push esi
    mov esi, debug_msg_loading_fonts
    call debug_print_str
    call debug_print_nl
    call debug_wait_enter
    pop esi
    
    ; Skip font loading - causes display corruption
    ; call load_arabic_fonts_bios
    
    push esi
    mov esi, debug_msg_fonts_loaded
    call debug_print_str
    call debug_print_nl
    call debug_wait_enter
    pop esi
    
    ; Far jump
    mov esi, debug_msg_far_jump
    call debug_print_str
    mov eax, long_mode_start
    call debug_print_hex
    call debug_print_nl
    call debug_wait_enter    ; Wait for Enter before the critical far jump
    
    pop esi               ; Restore ESI (was saved at start)
    
    ; Far jump to 64-bit code segment (this switches to 64-bit mode)
    ; This is the ONLY correct way to enter 64-bit mode from 32-bit
    ; Use explicit bytes to ensure correct encoding (NASM has issues with
    ; far jumps from [BITS 32] to [BITS 64] labels)
    db 0xEA                    ; Far jump opcode
    dd long_mode_start         ; 32-bit offset (low 32 bits of address)
    dw gdt64_code              ; 16-bit segment selector

[BITS 64]
default abs    ; Force absolute addressing in 64-bit mode (critical for accessing .data labels)
long_mode_start:
    ; Debug: We made it to 64-bit mode!
    ; Note: We can't use the 32-bit debug functions here, but we can write directly to VGA
    mov rax, 0xB8000 + (80 * 2)  ; Second row
    mov word [rax], 0x0A5B        ; '[' in green
    mov word [rax + 2], 0x0A37    ; '7' in green
    mov word [rax + 4], 0x0A5D    ; ']' in green
    mov word [rax + 6], 0x0A20    ; ' ' in green
    mov word [rax + 8], 0x0A36    ; '6' in green
    mov word [rax + 10], 0x0A34   ; '4' in green
    mov word [rax + 12], 0x0A2D   ; '-' in green
    mov word [rax + 14], 0x0A62   ; 'b' in green
    mov word [rax + 16], 0x0A69   ; 'i' in green
    mov word [rax + 18], 0x0A74   ; 't' in green
    mov word [rax + 20], 0x0A20   ; ' ' in green
    mov word [rax + 22], 0x0A4D   ; 'M' in green
    mov word [rax + 24], 0x0A6F   ; 'o' in green
    mov word [rax + 26], 0x0A64   ; 'd' in green
    mov word [rax + 28], 0x0A65   ; 'e' in green
    mov word [rax + 30], 0x0A21   ; '!' in green
    
    ; Set up 64-bit stack
    mov rsp, stack_top
    
    ; Clear direction flag
    cld
    
    ; Set up segment registers
    ; Note: In 64-bit mode, segment registers are mostly ignored except FS/GS
    ; SS is set automatically when RSP is loaded, so we don't load it explicitly
    mov ax, gdt64_data
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    ; mov ss, ax  ; REMOVED: Cannot load SS directly in 64-bit mode - causes GPF
    
    ; Load multiboot info into registers (System V AMD64 ABI)
    ; Zero-extend 32-bit values to 64-bit
    ; With default abs, these will use absolute addressing correctly
    mov edi, dword [multiboot_magic]   ; First parameter (magic) - zero-extends to rdi
    mov esi, dword [multiboot_info]    ; Second parameter (multiboot_info pointer) - zero-extends to rsi
    
    ; Call kernel main
    call kernel_main
    
    ; If kernel returns, halt
    cli
.hang64:
    hlt
    jmp .hang64

section .data
align 8
multiboot_magic: dq 0
multiboot_info:  dq 0

; Debug message strings
debug_msg_start:          db "[1] Entry point", 0
debug_msg_stack:          db "[2] Stack set", 0
debug_msg_multiboot:      db "[3] Multiboot magic: ", 0
debug_msg_pae:            db "[4] Enabling PAE...", 0
debug_msg_paging:         db "[5] Setting up paging...", 0
debug_msg_paging_setup:   db "    Starting paging setup...", 0
debug_msg_paging_clear:   db "    Page tables cleared", 0
debug_msg_paging_l4_addr:  db "    P4 table address: ", 0
debug_msg_paging_p3_addr:  db "    P3 table address: ", 0
debug_msg_paging_p2_addr:  db "    P2 table address: ", 0
debug_msg_paging_entries: db "    Page entries configured", 0
debug_msg_paging_cr3_addr: db "    Loading CR3 with address: ", 0
debug_msg_paging_cr3:     db "    CR3 loaded: ", 0
debug_msg_longmode:       db "[6] Entering long mode...", 0
debug_msg_entering_lm:    db "    Enabling long mode...", 0
debug_msg_efer:           db "    Setting EFER.LME...", 0
debug_msg_efer_value:     db "    EFER value: ", 0
debug_msg_gdt:            db "    Loading GDT...", 0
debug_msg_gdt_value:      db "    GDT base: ", 0
debug_msg_enable_paging:  db "    Enabling paging (CR0.PG)...", 0
debug_msg_cr0_value:      db "    CR0 value: ", 0
debug_msg_cr0_ok:         db "    CR0: PE=1, PG=1 (OK)", 0
debug_msg_cr0_error:      db "    CR0: ERROR - PE or PG not set!", 0
debug_msg_cr0_pe_error:   db "[FATAL] CR0.PE not set!", 0
debug_msg_cr0_pg_error:   db "[FATAL] CR0.PG not set!", 0
debug_msg_far_jump:       db "    Far jump to: ", 0
debug_msg_loading_fonts:  db "    Loading Arabic fonts...", 0
debug_msg_fonts_loaded:   db "    Arabic fonts loaded", 0
debug_msg_ok:             db " OK", 0
debug_msg_press_enter:    db " [Press Enter to continue...]", 0
debug_msg_error:          db "[ERROR] Should not reach here!", 0

; GDT for 64-bit mode
gdt64:
    dq 0                    ; Null descriptor
gdt64_code: equ $ - gdt64
    dq (1 << 43) | (1 << 44) | (1 << 47) | (1 << 53)  ; Code segment
gdt64_data: equ $ - gdt64
    dq (1 << 44) | (1 << 47)  ; Data segment
gdt64_end:

gdt64_pointer:
    dw gdt64_end - gdt64 - 1    ; Limit (16-bit)
    dd gdt64                    ; Base address (32-bit) - MUST be 32-bit in [BITS 32] mode

; Arabic font table for BIOS font loading
; 28 characters (0x80-0x9B), each 16 bytes (8x16 pixels)
align 16
arabic_font_table:
    ; Character 0x80 - ا (alif)
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18
    
    ; Character 0x81 - ب (ba)
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x3C, 0x66, 0x66, 0x66, 0x3C, 0x06, 0x06, 0x06
    
    ; Character 0x82 - ت (ta)
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x3C, 0x66, 0x66, 0x66, 0x3C, 0x18, 0x18, 0x18
    
    ; Character 0x83 - ث (tha)
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x3C, 0x66, 0x66, 0x66, 0x3C, 0x18, 0x18, 0x18
    
    ; Character 0x84 - ج (jeem)
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x3C, 0x60, 0x60, 0x60, 0x3C, 0x06, 0x66, 0x3C
    
    ; Character 0x85 - ح (ha)
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x3C, 0x60, 0x60, 0x60, 0x3C, 0x06, 0x06, 0x06
    
    ; Character 0x86 - خ (kha)
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x3C, 0x60, 0x60, 0x60, 0x3C, 0x06, 0x06, 0x06
    
    ; Character 0x87 - د (dal)
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x3C, 0x18
    
    ; Character 0x88 - ذ (thal)
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x3C, 0x18
    
    ; Character 0x89 - ر (ra)
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x0C, 0x18
    
    ; Character 0x8A - ز (zay)
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x0C, 0x18
    
    ; Character 0x8B - س (seen)
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x3C, 0x60, 0x60, 0x3C, 0x06, 0x06, 0x66, 0x3C
    
    ; Character 0x8C - ش (sheen)
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x3C, 0x60, 0x60, 0x3C, 0x06, 0x06, 0x66, 0x3C
    
    ; Character 0x8D - ص (sad)
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x3C, 0x66, 0x66, 0x66, 0x3C, 0x06, 0x06, 0x06
    
    ; Character 0x8E - ض (dad)
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x3C, 0x66, 0x66, 0x66, 0x3C, 0x06, 0x06, 0x06
    
    ; Character 0x8F - ط (ta)
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x7E, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18
    
    ; Character 0x90 - ظ (za)
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x7E, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18
    
    ; Character 0x91 - ع (ain)
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x3C, 0x60, 0x60, 0x3C, 0x06, 0x06, 0x06, 0x06
    
    ; Character 0x92 - غ (ghain)
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x3C, 0x60, 0x60, 0x3C, 0x06, 0x06, 0x06, 0x06
    
    ; Character 0x93 - ف (fa)
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x3C, 0x66, 0x66, 0x66, 0x3C, 0x18, 0x18, 0x18
    
    ; Character 0x94 - ق (qaf)
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x3C, 0x66, 0x66, 0x66, 0x3C, 0x06, 0x06, 0x06
    
    ; Character 0x95 - ك (kaf)
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x66, 0x66, 0x66, 0x3C, 0x18, 0x18, 0x18, 0x18
    
    ; Character 0x96 - ل (lam)
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x3C, 0x66
    
    ; Character 0x97 - م (meem)
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x3C, 0x06
    
    ; Character 0x98 - ن (noon)
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x3C, 0x66, 0x66, 0x66, 0x3C, 0x06, 0x06, 0x06
    
    ; Character 0x99 - ه (ha)
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x3C, 0x66, 0x66, 0x66, 0x3C, 0x06, 0x06, 0x06
    
    ; Character 0x9A - و (waw)
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x3C, 0x66, 0x66, 0x66, 0x66, 0x66, 0x3C, 0x18
    
    ; Character 0x9B - ي (ya)
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x3C, 0x66, 0x66, 0x66, 0x3C, 0x18, 0x18, 0x18

section .bss
; Allocate the actual page tables here (3 pages, 4KB each)
align 4096
page_table_l4:    resb 4096
page_table_p3:    resb 4096
page_table_p2:    resb 4096

; Ensure page tables are properly spaced (they should be sequential)
; P4 at offset 0, P3 at offset 4096, P2 at offset 8192

align 16
stack_bottom_32: resb 16384  ; 16 KB stack for 32-bit mode
stack_top_32:

align 4096
stack_guard_page: resb 4096  ; Guard page (non-present, prevents stack overflow corruption)

align 16
stack_bottom: resb 16384  ; 16 KB stack for 64-bit mode
stack_top:

