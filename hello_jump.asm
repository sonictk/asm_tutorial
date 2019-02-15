bits 64
default rel

segment .data
switch:
    dq main.case0
    dq main.case1
    dq main.case2

i: dq 2

a: dq 3
b: dq 5

segment .bss
    temp resq 1

segment .text
global main
extern ExitProcess

main:
    ; This block basically implements:
    ; if (a < b) {
    ;    temp = a;
    ;    a = b;
    ;    b = temp;
    ; }
    mov    rax, [a]
    mov    rbx, [b]
    cmp    rax, rbx
    jge    .end
    mov    [temp], rax
    mov    [a], rbx
    mov    [b], rax
    ; end block

    ; This is just demonstrating unconditional jump. Change ``i`` to jump differently.
    ; It's essentially a switch statement.
    mov    rax, [i]            ; move value of i to rax
    lea    rcx, [switch]
    jmp    [rcx + rax * 8]  ; switch (i)

.case0:
    mov    rbx, 100
    jmp .end

.case1:
    mov    rbx, 101
    jmp .end

.case2:
    mov    rbx, 103
    jmp .end

.end:
    xor eax, eax
    call ExitProcess
