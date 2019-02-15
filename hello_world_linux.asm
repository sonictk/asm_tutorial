bits 64

segment .data
    dd 4
    dd 4.4
    times 10 dd 0               ; pseudo-op that allocated 10 dwords
    dw 1, 2
    db 0xfb
    db "hello world", 0
    a dq 175
    b dq 4097
    c dq 2
    sum dq 0

segment .bss
    resd    1
    resd    10
    resb    100

    myArray resq    10

segment .text
global main                     ; tell linker about main

main:
    push   rbp                 ; set up a stack frame
    mov    rbp, rsp            ; rbp now points to stack frame
    sub    rsp, 32             ; leave room for shadow parameters
                               ; rsp on a 16 byte boundary
    mov    rax, 64

    bts    qword [myArray], 4   ; Set bit 4 of myArray
    bts    qword [myArray], 7   ; Set bit 7 of myArray
    bts    qword [myArray], 8   ; Set bit 8 of myArray
    bts    qword [myArray + 8], 12   ; Set bit 76 of myArray

    mov    rax, 76
    mov    rbx, rax
    shr    rbx, 6
    mov    rcx, rax
    and    rcx, 0x3f            ; Extract rightmost 6 bits
    xor    edx, edx

    lea    r11, [myArray]       ; RIP relative addressing for x64; load the table address in a register first, then access the table via the register
    bt    [r11 + 8 * rbx], rcx  ; 8
    setc    dl                  ; edx equals the tested bit
    btr    [r11 + 8 * rbx], rcx ; clear the bit, remove
    bts    [r11 + 8 * rbx], rcx ; set the bit, insert into set
    xor    rax, rax


    mov    r9, 2
    mul    r9
    mov    r8, 4

    div    r8
    idiv    r9

    not    r8
    and    r8, r9
    or    r8, r9
    xor    r8, r8

    neg    rax
    sar    rax, 8
    shl    rax, 8
    shr    rax, 8
    ror    rax, 24
    rol    rax, 48

    mov    rax, [a]
    add    rax, [b]

    mov    rbx, 256

    imul    rax, [a], 100

    imul    rbx

    inc    rax
    dec    rax
    sub    rax, 50

    xor rdx, rdx
    add rdx, 1000000

    mov    [sum], rax
    mov    rbx, rax

    movsx    rax, byte [a]      ; move byte and sign extend
    movzx    rbx, word [b]      ; move word and zero extend
    movsxd    rcx, dword [b]    ; move dword and sign extend

    neg    rbx
    neg    qword [sum]
    neg    qword [b]

    mov    rdx, [b]

    ; Testing conditional moves to avoid branching
    mov    rbx, rax
    neg    rax
    sub    rax, 100000000
    cmovl    rax, rcx

    mov    rax, 60             ; System call to exit
    xor    rdi, rdi            ; exit code 0
    syscall
