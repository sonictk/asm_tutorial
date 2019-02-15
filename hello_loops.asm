bits 64
default rel

segment .data
    data dq 0xfedcba9876543210
    sum dq 0

segment .text
global main
extern ExitProcess

main:
    push    rbp                 ; set up a stack frame
    mov    rbp, rsp             ; base pointer points to stack frame
    sub    rsp, 32              ; leave room for shadow params, stack pointer on 16 byte boundary

    ; This program counts the number of ``1`` bits in the ``data`` binary representation.
    ; sum = 0
    ; i = 0
    ; while (i < 64) {
    ;     sum += data & 1
    ;     data = data >> 1
    ;     ++i
    ; }
    mov    rax, [data]          ; bits being examined
    xor    ebx, ebx             ; carry bit after bt, setc
    xor    ecx, ecx             ; we'll use rcx as the counter
    xor    edx, edx             ; sum of 1 bits

while:
    cmp    rcx, 64              ; i < 64
    jnl    end_while            ; exit the loop if necessary
    bt    rax, 0                ; store the first bit in the carry flag.
    setc    bl                  ; set lower byte bx if carry flag is 1. This is ``data & 1``.
    add    edx, ebx             ; sum += data
    shr    rax, 1               ; data >> 1
    inc    rcx                  ; ++i
    jmp while                   ; repeat loop

end_while:
    mov    [sum], rdx
    xor    eax, eax
    leave
    call ExitProcess
