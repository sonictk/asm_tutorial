; This program creates a file, writes to it, then reads from it and prints the result
; to the console.
%include "win32n.inc"

default rel
bits 64

segment .data
    default_filename db 'tmp.tmp', 0
    default_text db 'This is test text to write to a file.', 0xd, 0xa, 0
    default_text_length equ $-default_text-1
    error_msg db 'An error occurred: %d', 0xd, 0xa, 0 ; CRLF and then null-terminate
    final_printout db 'text read: %s', 0xd, 0xa, 0

segment .text

; Kernel32.lib
extern _CRT_INIT

extern CloseHandle
extern CreateFileA
extern ExitProcess
extern GetLastError
extern GetProcessHeap
extern HeapAlloc
extern HeapFree
extern ReadFile
extern WriteFile

extern printf

global main

main:
.dwCreationDisposition equ 32
.dwFlagsAndAttributes equ 36
.hTemplateFile equ 40

    push    rbp
    mov    rbp, rsp
    sub    rsp, 64

    call    _CRT_INIT                 ; Needed since our entry point is not _DllMainCRTStartup. See https://msdn.microsoft.com/en-us/library/708by912.aspx

    ; Additional arguments pushed onto stack
    xor    eax, eax
    mov    qword [rsp + .hTemplateFile], rax
    mov    dword [rsp + .dwFlagsAndAttributes], FILE_ATTRIBUTE_NORMAL
    mov    dword [rsp + .dwCreationDisposition], CREATE_ALWAYS

    ; First 4 arguments go in registers, rest are pushed onto the stack
    xor    r9, r9
    mov    r8d, FILE_SHARE_READ
    mov    rdx, GENERIC_WRITE|GENERIC_READ
    lea    rcx, [default_filename]
    call    CreateFileA

    cmp    eax, INVALID_HANDLE_VALUE
    je    .error_creating_file

    ; NOTE: Clear the stack of the original variables; this is necessary since
    ; launching from cmder can make it possible to have stack corruption otherwise.
    ; TODO: Find out how to do this better, though? This probably wouldn't work if we
    ; needed to execute a leave and a ret instruction afterwards.
.lpNumberOfBytesWritten equ 52
.lpOverlapped equ 0
.fileHandle equ 40

    mov    rbp, rsp
    sub    rsp, 64

    mov    dword [rsp + .fileHandle], eax

    mov    ecx, eax ; File handle is first argument to WriteFile
    xor    eax, eax
    mov    dword [rsp + .lpOverlapped], eax
    lea    qword r9, [rsp + .lpNumberOfBytesWritten]
    xor    r8, r8
    mov    dword r8d, default_text_length
    lea    rdx, [default_text]
    call    WriteFile

    cmp    eax, 0
    je    .error_writing_to_file

    mov    ecx, dword [rsp + .fileHandle]
    call    CloseHandle

    cmp    eax, 0
    je    .error_closing_file

    xor    rax, rax
    mov    qword [rsp + .hTemplateFile], rax
    mov    dword [rsp + .dwFlagsAndAttributes], FILE_ATTRIBUTE_NORMAL
    mov    dword [rsp + .dwCreationDisposition], OPEN_EXISTING
    xor    r9, r9
    mov    r8d, FILE_SHARE_READ
    mov    rdx, GENERIC_READ
    lea    rcx, [default_filename]
    call    CreateFileA

    cmp    eax, INVALID_HANDLE_VALUE
    je    .error_creating_file

    mov    dword [rsp + .fileHandle], eax

    call    GetProcessHeap

    cmp    rax, 0
    je    .error_getting_heap

    xor    r8, r8
    mov    r8d, dword [rsp + .lpNumberOfBytesWritten]
    mov    edx, dword HEAP_ZERO_MEMORY
    mov    rcx, rax
    call    HeapAlloc

    cmp    rax, 0
    je    .error_allocating_memory

    mov    rbp, rsp
    sub    rsp, 64

.lpOverlapped2 equ 0
.lpNumberOfBytesRead equ 32
.lpBuffer equ 40


    mov    [rsp + .lpBuffer], rax; Store pointer to allocated memory block from HeapAlloc

    xor    rax, rax
    mov    [rsp + .lpOverlapped2], eax
    xor    r9, r9
    lea    r9, [rsp + .lpNumberOfBytesRead]
    xor    r8, r8
    mov    r8d, dword [rbp + .lpNumberOfBytesWritten]
    mov    rdx, qword [rsp + .lpBuffer]
    mov    rcx, qword [rbp + .fileHandle]
    call    ReadFile

    cmp    eax, 0
    je    .error_reading_file

    mov    rcx, qword [rbp + .fileHandle]
    call    CloseHandle

    cmp    eax, 0
    je    .error_closing_file

    mov    rdx, qword [rsp + .lpBuffer]
    lea    rcx, [final_printout]
    call    printf

    xor    eax, eax             ; return 0
    jmp    .quit_program


.error_getting_heap:
    mov    eax, 3
    jmp    .quit_program

.error_allocating_memory:
    mov    eax, 4
    jmp    .quit_program

.error_creating_file:
    mov    eax, 1               ; Oh no, we failed.
    jmp    .quit_program

.error_writing_to_file:
    mov    eax, 2               ; No, a failure.
    jmp    .quit_program

.error_reading_file:
    jmp    .print_last_error_code

.error_closing_file:
    jmp    .print_last_error_code

.print_last_error_code:
    call    GetLastError

    lea    rcx, [error_msg]
    mov    edx, eax
    call    printf

    mov    eax, 3
    jmp    .quit_program


.quit_program:
    call    ExitProcess
