/* Minimal linker script: place the program at the core's boot vector (PC_INITIAL). */
OUTPUT_ARCH("riscv")
ENTRY(_start)

SECTIONS
{
    . = 0x80000000;      /* must match riscv_top PC_INITIAL */
    .text : { *(.text*) }
    .data : { *(.data*) *(.rodata*) }
    .bss  : { *(.bss*)  *(COMMON) }

    . = 0x80003FF0;      /* HALT_ADDR */
    .tohost : { *(.tohost) }
}
