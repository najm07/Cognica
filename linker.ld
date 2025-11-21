ENTRY(_start)

/* Multiboot header is now in .text section at the start */
SECTIONS
{
    . = 1M;

    .text : {
        *(.text)
    }

    .rodata :
    {
        *(.rodata)
    }

    .data :
    {
        *(.data)
    }

    .bss :
    {
        *(COMMON)
        *(.bss)
    }
}

