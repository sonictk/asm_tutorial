bits 64
default rel

segment .data
    a dq 10, 20, 30, 40, 50

segment .bss
    b resb 5

segment .text
global main
extern ExitProcess

foo:
    mov    eax, 1
    ret

main:
    call    foo
    lea    rsi, [a]
    lea    rdi, [b]

    mov    rcx, 5
    rep    movsb                ; When preceded with rep, this does block move of ``ecx`` bytes/words/dwords

    xor eax, eax
    call ExitProcess
