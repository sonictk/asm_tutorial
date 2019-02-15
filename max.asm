default rel
bits 64

segment .data
    output_string db "max of %ld and %ld is %ld", 0 ; The string to display, null-terminated

segment .text
global main

extern printf
extern _CRT_INIT
extern ExitProcess

    ; Define constants to refer to the function arguments as offsets from RSP/RBP
    a equ    0
    b equ    8
print_max:
    push    rbp                 ; Set up a stack frame for the function
    mov    rbp, rsp             ; Continuing the linked list here, by pointing rbp to this stack frame
    sub    rsp, 32              ; Must align on 16 byte boundary, reserve 32 bytes

    mov    [rsp + a], rcx       ; save parameter a (rcx)
    mov    [rsp + b], rdx       ; save parameter b (rdx)

    ; int max;
    max equ 16                  ; ``max`` will be a local variable in the stack frame.

    mov    [rsp + max], rcx     ; max = a
    cmp    rdx, rcx             ; if (b > a) then max = b
    jng skip
    mov    [rsp + max], rdx     ; max = b
skip:
    lea    rcx, [output_string] ; Load the 4 arguments for printf in the registers.
    mov    rdx, [rsp + a]       ; For Microsoft x64 calling convention, first 4 are RCX, RDX, R8 and R9.
    mov    r8, [rsp + b]
    mov    r9, [rsp + max]
    call    printf

    leave                       ; Undo the stack frame (it sets rsp to rbp, then pops rbp.)
    ret                         ; return to calling procedure (main).

main:
    call _CRT_INIT                 ; Needed since our entry point is not _DllMainCRTStartup. See https://msdn.microsoft.com/en-us/library/708by912.aspx

    push    rbp                 ; Set up a stack frame
    mov    rbp, rsp             ; base pointer now points to stack frame
    sub    rsp, 32              ; Leave room for shadow parameters (4 for windows)

    mov    rcx, 100             ; First parameter to function
    mov    rdx, 200             ; Second parameter to function
    call    print_max           ; Invoke function

    xor    eax, eax                ; return 0
    leave

    call ExitProcess            ; On Windows, terminates the process.
