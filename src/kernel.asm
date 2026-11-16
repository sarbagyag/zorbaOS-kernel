[BITS 32]
global _start
extern kernel_main

CODE_SEG equ 0x08
DATA_SEG equ 0x10

_start:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov ebp, 0x00200000
    mov esp, ebp

    ; Enable the A20 line (Fast A20 Gate)
    in al, 0x92
    or al, 2
    out 0x92, al

    ; Remap the master PIC
    mov al, 00010001b   ; ICW1: put the PIC into initialization mode
    out 0x20, al

    mov al, 0x20        ; ICW2: IRQ0 -> interrupt 0x20
    out 0x21, al

    mov al, 00000001b   ; ICW4: x86 mode
    out 0x21, al
    ; End remap of the master PIC

    ; Interrupts are enabled from C (enable_interrupts) once the IDT is loaded

    call kernel_main
    jmp $

times 512 - ($ - $$) db 0 ; Pad to 512 bytes so the C code that follows stays aligned
