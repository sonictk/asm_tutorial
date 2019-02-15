bits 64
default rel

segment .bss
    resb 11
    resd 9
    alignb 8                     ;  Align data to the next 8 byte boundary
    resq 10

    b resd 10
    pointer_to_large_array resd 1

segment .data
a: dd 1, 2, 3, 4, 5

segment .text

extern ExitProcess

extern malloc
extern free

global main
global copy_array

    ; This example copies ``a`` to ``b``.
main:
    push    rbp
    mov    rbp, rsp
    sub    rsp, 32

    ; for fun, malloc a big array and release it
    mov    rcx, 100000
    call    malloc
    mov    [pointer_to_large_array], rax

    mov    rcx, [pointer_to_large_array]
    call    free

    lea    rcx, [b]             ; destination
    lea    rdx, [a]             ; source
    mov    r8d, 5                ; buffer size, store in the lower DWORD
    call    copy_array

    xor    eax, eax
    leave
    call ExitProcess

copy_array:
    push    rbp
    mov    rbp, rsp
    sub    rsp, 32

    xor    r9d, r9d             ; Start with 0 for the index, this register is used for counter

repeat_copy:
    mov    eax, [rdx + 4 * r9]  ; load size of DWORD from source
    mov    [rcx + 4 + r9], eax  ; store size of DWORD to dest
    inc    r9d                  ; increment counter
    cmp    r9, r8
    jne    repeat_copy

    leave
    ret
