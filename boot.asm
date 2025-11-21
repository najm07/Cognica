; Kernel entry point - multiboot header must be first
section .text
global _start
extern kernel_main

; Multiboot 2 header - must be at start of .text section
align 8
multiboot_header_start:
    dd 0xe85250d6                ; Magic number (multiboot 2)
    dd 0                          ; Architecture 0 (protected mode i386)
    dd multiboot_header_end - multiboot_header_start  ; Header length
    ; Checksum
    dd 0x100000000 - (0xe85250d6 + 0 + (multiboot_header_end - multiboot_header_start))

    ; Required end tag
    dw 0    ; Type
    dw 0    ; Flags
    dd 8    ; Size
multiboot_header_end:

_start:
    ; Set up stack pointer
    mov esp, stack_top
    
    ; Clear direction flag
    cld
    
    ; Push multiboot info (cdecl: right-to-left, so push last param first)
    push ebx    ; Multiboot info structure (second parameter)
    push eax    ; Multiboot magic number (first parameter)
    
    ; Call kernel main
    call kernel_main
    add esp, 8  ; Clean up stack (2 arguments * 4 bytes)
    
    ; If kernel returns, halt
    cli
.hang:
    hlt
    jmp .hang

section .bss
align 16
stack_bottom:
    resb 16384  ; 16 KB stack
stack_top:

