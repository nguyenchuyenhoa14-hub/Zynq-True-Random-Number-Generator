ENTRY(_start)

SECTIONS {
  . = 0x00000000;   /* địa chỉ load code */
  .text : { *(.text*) }
  .data : { *(.data*) }
  .bss  : { *(.bss*)  }
}
