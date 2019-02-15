    ; Use these macros for pushing/popping the general purpose registers
%macro multipush 1-*            ; Variadic macro that accepts any number of arguments.
%rep %0                         ; %0 means that this proc will repeat as many times as there were arguments
    push %1
%rotate 1                       ; Shifts arguments left by one (i.e. $3 becomes $2, $2 becomes $1, $1 gets deleted)
%endrep
%endmacro


%macro multipop 1-*             ; Symmetric version in order to pop the arguments from the stack.
%rep %0
%rotate -1                      ; Orig. last argument now appears as %1. Iterate in reverse order.
    pop %1
%endrep
%endmacro


    ; Use these macros for pushing/popping xmm registers
%macro multipush_xmm 1-*
%rep %0
    sub    rsp, 16
    movdqu    oword [rsp], %1   ; note: In NASM, octo-word is used instead of dqword like in MASM.
%rotate 1
%endrep
%endmacro


%macro multipop_xmm 1-*
%rep %0
%rotate -1
    movdqu    %1, oword [rsp]
    add    rsp, 16
%endrep
%endmacro


    ; Use these macros for pushing/popping ymm registers
%macro multipush_ymm 1-*
%rep %0
    sub    rsp, 32
    vmovdqu    yword [rsp], %1   ; note: In NASM, octo-word is used instead of dqword like in MASM.
%rotate 1
%endrep
%endmacro


%macro multipop_ymm 1-*
%rep %0
%rotate -1
    vmovdqu    %1, yword [rsp]
    add    rsp, 32
%endrep
%endmacro
