default rel
bits 64

segment .bss
    c resq 2

segment .data
    a dd 3.25
    b dd 10.53
    x dd 3.5, 8.2, 10.5, 1.3
    y dq 4.4, 5.5, 6.6, 7.7
    z dd 1.2, 2.3, 3.4, 4.56, 5.53, 2.34, 2.12, 8.01

segment .text
global main
extern _CRT_INIT
extern ExitProcess
extern printf

main:
    call _CRT_INIT                 ; Needed since our entry point is not _DllMainCRTStartup. See https://msdn.microsoft.com/en-us/library/708by912.aspx

    push    rbp
    mov    rbp, rsp
    sub    rsp, 32

    movss    xmm0, [a]             ; Load a
    movss    xmm1, [b]             ; Load b
    vaddss    xmm2, xmm0, xmm1      ; xmm2 = xmm1 + xmm2
segment .data
.format db 'result is: %f', 0xa, 0
segment .text
    lea    rcx, [.format]
    movss    xmm1, xmm2

    ; Remember, %f actually expects a double, so we need to convert the float to double
    cvtss2sd    xmm1, xmm1

    ; Also remember: floats are passed in xmm registers, but printf wants a
    ; double! This is an aggregate so it's passed in RDX instead.
    movq    rdx, xmm1
    call    printf

    ; Now let's try moving packed data around
    movups    xmm0, [x]         ; Move 4 floats to xmm0
    vmovups    ymm0, [z]        ; Move 8 floats to ymm0
    vmovupd    ymm1, [y]        ; Move 4 doubles to ymm1
    movupd    [a], xmm0         ; Move 2 doubles to a

    addps    xmm0, xmm0         ; Packed add
    vaddpd    ymm1, ymm1

    vmovupd    ymm2, ymm1

    vsubpd    ymm3, ymm2, ymm1  ; ymm2 - ymm1, store in ymm3

    ; Unordered comparison of floating point single scalar
    ucomiss    xmm0, xmm1
    jbe    less_or_equal

less_or_equal:
    movss    xmm3, [a]

    xor eax, eax                ; return 0
    call ExitProcess
