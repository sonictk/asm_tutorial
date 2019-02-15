default rel
bits 64

segment .data
    name db 'Calvin', 0
    address db '12 Mockingbird Lane', 0
    balance dd 12500

    format db '%s %s %d', 0xd, 0xa, 0


segment .bss

    ; NASM will automatically define ``Customer_size`` to be the number of bytes
    ; in the struct.
    ; If variables are declared without the ``.`` prefix, they will be accessible globally.
struc Customer
    .id resd 1
    .name resb 64
    .address resb 65            ; Alignment problems could occur here since MSVC/GCC
                                ; will automatically perform padding to pack the structure
                                ; and align to 4 byte boundaries. NASM does not do padding,
                                ; therefore this struct definition will not match the alignment
                                ; of C. We place alignb 4 to force nasm compiler to perform the
                                ; alignment as well.
    alignb 4
    .balance resd 1
endstruc



    ; As before, the size of this struct will be accessible via ``TestStruct_size``.
struc TestStruct
    ts_test_int resd 1
endstruc

segment .data

    ; Can also make use of ``istruc``, ``iend`` and ``at`` struct instance features
    ; in NASM to have static variables instead.

    customer_memory dq 0

    ; Official NASM docs say this is for declaring instances of structures. Here,
    ; however, we're using it to demonstrate how to make a static variable instead.
    ; ``at`` macro is to make use of the ``TIMES`` prefix to advance the assembly
    ; position to the correct point for the specified structure field, and then to
    ; declare the specified data.
istruc TestStruct                ; test structure that we will have static variables for.
    at ts_test_int, dd 7       ; This is a global identifier since it doesn't have the ``.`` prefix.
iend

    array_structs_memory dq 0


segment .bss

struc ArrayStructExample
    .id resd 1                      ; 4 bytes (aligned on appropriate boundary)
    .name resb 65                   ; 69 bytes
    .address resb 69                ; 134 bytes
    alignb 4                        ; aligns to 136
    .balance resd 1                 ; 140 bytes
    .rank resb 1                ; 141 bytes
    alignb 4                ; aligns to 144. The alignment must be the size of the
                            ; largest data item in the struct. i.e. if there was a
                            ;quadword field, would need to use alignb 8 here to force nasm to align the
                            ; _size value to be a multiple of 8.
endstruc


segment .text

extern ExitProcess
extern _CRT_INIT
extern malloc
extern free
extern strcpy
extern printf

global main


main:
local1 equ 32
local2 equ 40


    push    rbp
    mov    rbp, rsp
    sub    rsp, 64

    call    _CRT_INIT                 ; Needed since our entry point is not _DllMainCRTStartup. See https://msdn.microsoft.com/en-us/library/708by912.aspx

    mov    rcx, Customer_size

    call    malloc

    mov    [customer_memory], rax

    ; Fill the struct
    mov    [rax + Customer.id], dword 7

    lea    rcx, [customer_memory + Customer.name]
    lea    rdx, [name]

    call   strcpy

    mov    rax, [customer_memory] ; restore the pointer since ``strcpy`` blew away the value in ``rax``.
    lea    rcx, [customer_memory + Customer.address]
    lea    rdx, [address]

    call   strcpy

    mov    rax, [customer_memory]
    mov    edx, [balance]
    mov    [customer_memory + Customer.balance], edx

    lea    rax, [customer_memory]
    call    free


    ; Test using array of structs
    ; Allocate memory for 100 structs
    mov    ecx, 100
    imul    ecx, ArrayStructExample_size
    call    malloc
    mov    [array_structs_memory], rax

    ; r14 and r15 are preserved through calls
    mov    [rbp + local1], r14
    mov    [rbp + local2], r15

more:
    mov    r15, 100
    mov    r14, [array_structs_memory]

    lea    rcx, [format]
    lea    edx, [r14 + ArrayStructExample.address]
    lea    r8, [r14 + ArrayStructExample.name]
    mov    r9, [r14 + ArrayStructExample.id]

    call    printf
    add    r14, ArrayStructExample_size
    sub    r15, 1
    jnz more

    mov    r14, [rbp + local1]
    mov    r15, [rbp + local2]


    xor    eax, eax             ; Successful exit code

    call ExitProcess
