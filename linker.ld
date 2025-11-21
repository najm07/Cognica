/* Linker script for multiboot -> long-mode kernel */
/* Link at 1 MiB */
ENTRY(_start)

SECTIONS
{
    /* Load address */
    . = 0x100000;

    /* Code and rodata aligned to page so GDT pointer/base are <4GB and simple */
    .text ALIGN(4096) : {
        *(.text)
    }

    .rodata ALIGN(4096) : {
        *(.rodata)
    }

    .data ALIGN(4096) : {
        *(.data)
    }

    /* BSS: place page tables first (explicitly reserved), then rest of BSS items */
    .bss ALIGN(4096) : {
        __bss_start = .;

        /* Ensure page tables are aligned and kept in output */
        . = ALIGN(4096);
        PROVIDE(page_table_l4 = .);    /* PML4 base (phys addr) */
        KEEP(*(.page_tables_l4))       /* optional: allow .page_tables_l4 section override */
        . += 4096;                     /* reserve 4KB */

        . = ALIGN(4096);
        PROVIDE(page_table_p3 = .);    /* PDP / P3 */
        KEEP(*(.page_tables_p3))
        . += 4096;

        . = ALIGN(4096);
        PROVIDE(page_table_p2 = .);    /* PD / P2 */
        KEEP(*(.page_tables_p2))
        . += 4096;

        /* If your assembly simply uses resb labels in .bss, they will be placed
           after these reservations when assembled and linked. The PROVIDE symbols
           above point at the start of each reserved area. */

        /* Remaining BSS content (stacks, guard page, other resb) */
        *(.bss)
        *(COMMON)

        __bss_end = .;
    }
}
