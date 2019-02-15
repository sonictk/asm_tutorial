default rel
bits 64

segment .data
a: dq 5
b: dq 2
c: dq 3

segment .bss
    max resq 1
    result resq 1

segment .text
global main
extern ExitProcess

main:
    ; if (a < b) {
    ;     max = b
    ; } else {
    ;     max = a
    ; }

    mov    rax, [a]
    mov    rbx, [b]
    cmp    rax, rbx
    jnl    else
    mov    [max], rbx
    jmp endif


    ;if (a < b) {
    ;    result = 1
    ;} else if (a > c) {
    ;    result = 2
    ;} else {
    ;    result = 3
    ;}
    mov    rax, [a]
    mov    rbx, [b]
    cmp    rax, rbx
    jnl    elseif
    mov    qword [result], 1
    jmp    endif


else:
    mov    [max], rax

elseif:
    mov    rcx, [c]
    cmp    rax, rcx
    jng    else2
    mov    qword [result], 2
    jmp endif

else2:
    mov    qword [result], 3

endif:
    xor eax, eax
    call ExitProcess
