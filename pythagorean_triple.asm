default rel                     ; This allows compilation without /largeaddressaware:no

segment .data
    a dq 3
    b dq 4
    c dq 5


segment .text
global main                     ; tell linker about main

main:
    mov rax, [a]
    mul rax                    ; a^2

    mov rbx, [b]
    imul rbx, rbx               ; b^2

    mov rcx, [c]
    imul rcx, rcx               ; c^2

    add rax, rbx                ; a^2 + b^2
    sub rax, rcx                ; == c^2 ?

    xor    eax, eax
    ret
