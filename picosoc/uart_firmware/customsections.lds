ENTRY(_start)
SECTIONS
{
    . = 0x0010;
    .crt0 : {*(.crt0)}
    .text : {*(.text)}
    . = 0xdac;
    .data : {*(.data)}
    .sdata : {*(.sdata)}
    bss_addr = .;
    .bss : {*(.bss)}
    bss_end = .;
}