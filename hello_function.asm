default rel
bits 64

segment .data
    format db 'x is %lf', 0xa, 0 ; lf for double in c99

segment .text
global main
extern printf
extern _CRT_INIT
extern ExitProcess

main:
    call _CRT_INIT                 ; Needed since our entry point is not _DllMainCRTStartup. See https://msdn.microsoft.com/en-us/library/708by912.aspx

    push    rbp
    mov    rbp, rsp
    sub    rsp, 32

    ;movsd    xmm1, xmm0         ; value in xmm0 must be copied to xmm1 and also to rdx
    ;movq    rdx, xmm1

    lea rcx, [format]           ; Place address of format string in rcx
    call    printf

    xor eax, eax                ; return 0
    call ExitProcess
