default rel
bits 64

segment .data
    format_result db 'polynomial is %lf', 0xa, 0

    coefficients dq 4.4, 5.5, 6.6
    x dq 4.0
    degree dd 2

segment .text

extern printf
extern _CRT_INIT
extern ExitProcess

global calculate_polynomial
global main

    ; p(x) = p0 + p1x + p2x^2 + p3x^3 + ... + pnx^n
    ;
    ; Can use Horner's Rule for a more efficient method with doing less work
    ; bn = pn
    ; b (n-1) = p (n-1) + b (n) x
    ; b (n-2) = p (n-2) + b (n-1) x
    ; ...
    ; b (0) = p (0) + b1x
    ; Then p(x) = b0.

    ; calculate_polynomial(double *coefficients, double x, int degree)
calculate_polynomial:
    ; TODO: need to verify the result
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32

    movsd    xmm0, [rcx + r8 * 8] ; xmm0 = b_k
    cmp    r8d, 0                 ; Check if the degree is 0
    jz    .done

.more:
    dec    r8d
    mulsd    xmm0, xmm1         ; b_k * x
    addsd    xmm0, [rcx + r8 * 8] ; adding p_k
    jnz    .more

.done:
    leave
    ret


main:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32

    call    _CRT_INIT ; Needed since our entry point is not _DllMainCRTStartup. See https://msdn.microsoft.com/en-us/library/708by912.aspx

    lea    rcx, [coefficients]
    movsd    xmm1, [x]
    mov    r8d, [degree]
    call    calculate_polynomial

    lea    rcx, [format_result]
    movq    rdx, xmm0
    call    printf

    xor     eax, eax                ; return 0
    call    ExitProcess
