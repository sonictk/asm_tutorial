default rel
bits 64

segment .data
    format_length db 'length is %lf', 0xa, 0 ; lf for double in c99
    format_distance db 'distance is %lf', 0xa, 0
    format_inner db 'dot product is %lf', 0xa, 0

    v1x dd 5.0
    v1y dd 6.0
    v1z dd 7.0

    v2x dd 8.0
    v2y dd 9.0
    v2z dd 10.0

segment .text

extern printf
extern _CRT_INIT
extern ExitProcess

global length_vec3
global distance_vec3
global inner_product_vec3
global main


inner_product_vec3:             ; float inner_product_vec3(float x1, float y1, float z1, float x2, float y2, float z2)
.y2 equ 0
.z2 equ 4

    ; TODO: Is this a good idea? should I take the variables before/after setting up the stack frame?
    ; How can I get the 48 value for rbp to make this an actual function?
    movss    xmm5, [rbp - 48 + .z2]
    movss    xmm4, [rbp - 48 + .y2]

    push    rbp
    mov    rbp, rsp
    sub    rsp, 32

    mulss    xmm0, xmm3         ; x1 * x2
    mulss    xmm1, xmm4         ; y1 * y2
    mulss    xmm2, xmm5         ; z1 * z2

    addss    xmm1, xmm2
    addss    xmm0, xmm1

    leave
    ret


length_vec3:                    ; float length_vec3(float x, float y, float z)
    push    rbp
    mov    rbp, rsp
    sub    rsp, 32

    mulss    xmm0, xmm0
    mulss    xmm1, xmm1
    mulss    xmm2, xmm2

    addss    xmm0, xmm2
    addss    xmm0, xmm1

    sqrtss    xmm0, xmm0        ; Return value is also here since float is non-scalar type.

    leave
    ret


distance_vec3:                  ; float distance_vec3(float x1, float y1, float z1, float x2, float y2, float z2)
.y2 equ 0
.z2 equ 4

    ; TODO: Is this a good idea? should I take the variables before/after setting up the stack frame?
    ; How can I get the 48 value for rbp to make this an actual function?
    movss    xmm5, [rbp - 48 + .z2]
    movss    xmm4, [rbp - 48 + .y2]

    push    rbp
    mov    rbp, rsp
    sub    rsp, 32



    ; At this point:
    ; xmm0: x1, xmm1: y1, xmm2: z1    xmm3: x2, rsp + 32: y2, rsp + 36: z2

    subss    xmm0, xmm3         ; x1 - x2
    mulss    xmm0, xmm0         ; (x1 - x2) ^ 2

    subss    xmm1, xmm4  ; y1 - y2
    mulss    xmm1, xmm1         ; (y1 - y2) ^ 2

    subss    xmm2, xmm5
    mulss    xmm2, xmm2

    addss    xmm0, xmm2
    addss    xmm0, xmm1         ; (x1 - x2)^2 + (y1 - y2)^2 + (z1 - z2)^2

    sqrtss    xmm0, xmm0

    leave
    ret


main:
.y2 equ 0
.z2 equ 4

    push    rbp
    mov     rbp, rsp
    sub     rsp, 48

    call    _CRT_INIT ; Needed since our entry point is not _DllMainCRTStartup. See https://msdn.microsoft.com/en-us/library/708by912.aspx

    movss     xmm0, [v1x]           ; 1st 3d vector
    movss     xmm1, [v1y]
    movss     xmm2, [v1z]
    call    length_vec3

    lea     rcx, [format_length]           ; Place address of format string in rcx

    ; Remember, printf actually expects a double, so we need to convert the float
    ; return value to a double before printing
    cvtss2sd    xmm0, xmm0
    movq    rdx, xmm0
    call    printf

    ; Just clear so it's easier for debugging. This would be silly to do for real.
    xorps    xmm0, xmm0
    xorps    xmm1, xmm1
    xorps    xmm2, xmm2

    ; Next example: distance calcuation
    ; Calling convention: additional arguments are pushed onto the stack in reversed order (right-to-left).

    ; Last 2 params go on stack
    movss    xmm0, [v2z]
    movss    [rsp + .z2], xmm0

    movss    xmm0, [v2y]
    movss    [rsp + .y2], xmm0

    ; First 4 params go in registers
    movss    xmm3, [v2x]

    movss     xmm2, [v1z]
    movss     xmm1, [v1y]
    movss     xmm0, [v1x]           ; 1st 3d vector

    call    distance_vec3

    ; print distance result
    lea    rcx, [format_distance]
    cvtss2sd    xmm0, xmm0
    movq    rdx, xmm0

    call    printf

    ; Next example: inner product calculation
    xorps    xmm0, xmm0
    xorps    xmm1, xmm1
    xorps    xmm2, xmm2

    ; Last 2 params go on stack
    movss    xmm0, [v2z]
    movss    [rsp + .z2], xmm0

    movss    xmm0, [v2y]
    movss    [rsp + .y2], xmm0

    ; First 4 params go in registers
    movss    xmm3, [v2x]

    movss     xmm2, [v1z]
    movss     xmm1, [v1y]
    movss     xmm0, [v1x]

    call inner_product_vec3

    ; print dot product
    lea    rcx, [format_inner]
    cvtss2sd    xmm0, xmm0
    movq    rdx, xmm0

    call    printf

    xor     eax, eax                ; return 0
    call    ExitProcess
