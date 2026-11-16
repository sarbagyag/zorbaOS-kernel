[BITS 32]

section .asm

global paging_load_directory
global enable_paging
global paging_invalidate_page

paging_load_directory:
    push ebp
    mov ebp, esp
    mov eax, [ebp+8]
    mov cr3, eax
    pop ebp
    ret

enable_paging:
    push ebp
    mov ebp, esp
    mov eax, cr0
    or eax, 0x80000000
    mov cr0, eax
    pop ebp
    ret

; void paging_invalidate_page(void* virt)
paging_invalidate_page:
    push ebp
    mov ebp, esp
    mov eax, [ebp+8]
    invlpg [eax]
    pop ebp
    ret
