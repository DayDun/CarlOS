/*
*  link.ld
*/
OUTPUT_FORMAT(pei-i386)
ENTRY(kernel_start)
SECTIONS
 {
   . = 0x100000;
   .multiboot : { *(.multiboot) }
   .text : { *(.text) }
   .data : { *(.data) }
   .bss  : { *(.bss)  }
 }