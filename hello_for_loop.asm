bits 64
default rel

segment .data
    n dq 5
    a dq 10, 20, 30, 40, 50
    b dq 1, 2, 3, 4, 5
    c dq 0

segment .text
global main

main:
    push    rbp                 ; set up a stack frame
    mov    rbp, rsp             ; base pointer points to stack frame
    sub    rsp, 32              ; leave room for shadow params, stack pointer on 16 byte boundary

    ; This code does a simple for loop
    ;for (i=0; i < n; ++i) {
    ;    c[i] = a[i] + b[i]
    ;}
    mov    rdx, [n]
    xor    ecx, ecx

for:
    cmp    rcx, rdx
    je    end_for

    lea    r11, [a]
    mov    rax, [r11 + rcx * 8]

    lea    r12, [b]
    add    rax, [r12 + rcx * 8]

    lea    r13, [c]
    mov    [r13 + rcx * 8], rax
    inc    rcx
    jmp for

end_for:
    xor    eax, eax
    leave
    ret
