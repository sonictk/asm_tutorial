; This program allocates and fills an array with random numbers and then computes
; the minimum value of the array. If the array size <= 20, it prints the values
; in the array.
    ; TODO: Crashing when specifying 10000 on the command line
    ; TODO: Not printing the indices correctly
default rel
bits 64

segment .bss
    argv resq 1
    argc resq 1

segment .data
    format_string db 'array value: %ld for index', 0xd, 0xa, 0
    format_min db 'min: %ld', 0xd, 0xa, 0 ; CRLF and then null-terminate

segment .text
global main

; msvcrt.lib and ucrt.lib
extern malloc
extern printf
extern rand
extern _wtoi


; Kernel32.lib
extern _CRT_INIT
extern ExitProcess
extern GetCommandLineW


; Shell32.lib
extern CommandLineToArgvW


create_array:                   ; Equivalent to void *create_array(int size)
    push    rbp
    mov    rbp, rsp
    sub    rsp, 32

    sal    rcx, 2               ; Multiply size by 4 to get num of bytes to allocate
    call    malloc

    leave
    ret


fill_array:                     ; implements fill(array, size)
.array equ 0                    ; Define offsets to access local stack frame variables
.size equ 8                     ; These are local labels (only valid within the scope of ``fill_array``)
.i equ 16

    push    rbp                 ; Set up a stack frame
    mov    rbp, rsp
    sub    rsp, 32

    mov    [rsp + .array], rcx  ; Save the array on the stack
    mov    [rsp + .size], rdx   ; Save the size on the stack

    xor    ecx, ecx             ; Clear the index register

.more:
    mov    [rsp + .i], rcx      ; Save index register
    call    rand

    mov    rcx, [rsp + .i]      ; Recall index
    mov    rdx, [rsp + .array]  ; Load array address
    mov    [rdx + rcx * 4], eax ; store random value from rand's return
    inc    rcx
    cmp    rcx, [rsp + .size]
    jl    .more                 ; Keep looping until we go through the array

    leave
    ret


print_array:                    ; Implements print(array, size)
.array equ 32
.size equ 40
.i equ 48

    push    rbp                 ; Set up a stack frame
    mov    rbp, rsp
    sub    rsp, 64              ; Reserve extra 32 bytes for printf

    mov    [rsp + .array], rcx  ; Save the array
    mov    [rsp + .size], rdx   ; Save size
    xor    r8d, r8d             ; Zero index register (lower 32 bits)
    mov    [rsp + .i], r8       ; Move the index into R8

.more:
    lea    rcx, [format_string] ; First param
    mov    rdx, [rsp + .array]  ; Array address
    mov    r8, [rsp + .i]       ; Index register 3rd param
    mov    edx, [rdx + r8 * 4]  ; get array[i], 2nd param
    ; NOTE: Because we're making a function call here, need to make sure that all
    ; stack variables are _above_ the shadow space (i.e. offset starts after 32 bytes)
    call printf

    mov    rcx, [rsp + .i]      ; get index
    inc    rcx
    mov    [rsp + .i], rcx      ; save incremented index
    cmp    rcx, [rsp + .size]
    jl    .more

    leave
    ret


min:                            ; Implements min(array, size)
    push    rbp                 ; Set up a stack frame
    mov    rbp, rsp
    sub    rsp, 32

    mov    eax, [rcx]           ; get array[0]
    mov    r8d, 1               ; Set index to 1

.more:
    mov    r9d, [rcx + r8 * 4]  ; Get array[r8]
    cmp    r9d, eax             ; if array[r8] < eax
    cmovl    eax, r9d           ; if yes, move array[r8] to eax
    inc    r8
    cmp    r8, rdx              ; Compare counter vs array size
    jl    .more                 ; Continue until iterate over entire array

    leave
    ret


main:
.array equ 32
.size equ 40

    push    rbp
    mov    rbp, rsp
    sub    rsp, 64

    call    _CRT_INIT                 ; Needed since our entry point is not _DllMainCRTStartup. See https://msdn.microsoft.com/en-us/library/708by912.aspx

    mov    r8d, 7              ; Set default array size
    mov    [rsp + .size], r8

    ; Check for cmdline argument providing size
    ; On Windows, mainCRTStartup doesn't receive any args from the
    ; caller. Command line that is eventually passed to main/WinMain is being
    ; retrieved via GetCommandLine() within the runtime library (RTL)'s
    ; implementation of xxxCRTStartup.
    call    GetCommandLineW
    ; At this point, rax should have pointer to string from GetCommandLineW

    ; Prepare arguments for CommandLineToArgvW
    lea    rdx, [argc]
    mov    rcx, rax
    call    CommandLineToArgvW

    ; if an error occurred in CommandLineToArgvW, assume no size entered
    cmp    rax, 0
    je    .nosize

    mov    qword [argv], rax

    cmp    qword [argc], 2      ; Must only specify one argument, the 1st argument
                                ; will be the path to the exe and the 2nd will be the actual
                                ; argument
    jne    .nosize

    mov    rcx, [argv]
    mov    r9, 2
    mov    rcx, [rcx + 8]

    call    _wtoi                ; Convert string to int, now rax should have size from cmdline

    ; If invalid size was specified on command line, use default size
    cmp    rax, 0
    je    .nosize

    ; ...else use the size specified
    mov    [rsp + .size], rax
    jmp    .gotsize

.nosize:
    mov    rcx, [rsp + .size]

.gotsize:
    call    create_array

    mov    [rsp +.array], rax   ; Get array address from return value of create_array()

    ; fill array with random numbers
    mov    rcx, rax
    mov    rdx, [rsp + .size]
    call    fill_array

    ; If size <= 20 print the array
    mov    rdx, [rsp + .size]
    cmp    rcx, 20
    jg    .too_big
    mov    rcx, [rsp + .array]
    call    print_array

.too_big:
    ; print the minimum
    mov    rcx, [rsp + .array]
    mov    rdx, [rsp + .size]
    call    min

    lea    rcx, [format_min]
    mov    rdx, rax
    call    printf

    xor    eax, eax             ; return 0
    ;leave                       ; TODO: Somehow this causes a crash if CommandLineToArgvW is even specified in externals? Why???

    call    ExitProcess
