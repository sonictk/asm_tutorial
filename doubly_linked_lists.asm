default rel
bits 64

segment .bss

    ; This will be a node in a doubly-linked list.
struc Node
.value resq 1
.next resq 1
.prev resq 1
endstruc

segment .text

extern ExitProcess
extern _CRT_INIT
extern malloc
extern printf
extern scanf


global main

    ; A new list will always have a "head" node that points to the first node in
    ; the actual list. Even if the list is "empty", the head node remains and the
    ; pointer to it never changes.
; list = new_list()
new_list:
    push    rbp
    mov    rbp, rsp
    sub    rsp, 64

    mov    ecx, Node_size       ; This is a constant defined by NASM automatically
    call    malloc

    mov    [rax + Node.next], rax ; points forward...
    mov    [rax + Node.prev], rax ; and back to itself, since this is the head node

    leave
    ret

    ; insert_node(list, n);
insert_node:
.list equ 32
.n equ 40
    push    rbp
    mov    rbp, rsp
    sub    rsp, 64

    mov    [rsp + .list], rcx   ; Save the pointer to the list passed in
    mov    [rsp + .n], rdx      ; Save the node that was passed in

    mov    ecx, Node_size       ; Allocate memory for this new node
    call    malloc

    mov    r8, [rsp + .list]    ; Get the ptr to the list, store in r8
    mov    r9, [r8 + Node.next] ; Get the head node's ``next`` ptr, store in r9

    mov    [rax + Node.next], r9 ; new node's ``next`` now points to head node's ``next``
    mov    [rax + Node.prev], r8 ; new node's ``prev`` now points to the head node itself
    mov    [r8 + Node.next], rax ; new node now stored in head node's ``next``
    mov    [r9 + Node.prev], rax ; head node's ``next`` and then it's ``prev`` (so the new node's ``prev`` basically) points to the new node's value

    mov    r9, [rsp + .n]        ; Get the node that was passed in and store in r9
    mov    [rax + Node.value], r9 ; Save the node's value passed in in the new node's ``value``

    leave
    ret


; print_nodes(list);
print_nodes:
segment .data
.print_fmt: db '%ld', 0xd, 0xa, 0
.newline: db 0xd, 0xa, 0        ; CR LF null terminator

segment .text
.list equ 32
.rbx_storage equ 40

    push    rbp
    mov    rbp, rsp
    sub    rsp, 64

    mov    [rsp + .rbx_storage], rbx ; Save previous rbx value
    mov    [rsp + .list], rcx        ; Store ptr to list passed in
    mov    rbx, [rcx + Node.next]    ; Store first node in rbx
    cmp    rbx, [rsp + .list]        ; Check if it's the head node
    je    .done                      ; If it is, then we've reached the end of iteration

.more:
    lea    rcx, [.print_fmt]
    mov    rdx, [rbx + Node.value] ; Print the value of the node

    call    printf

    mov    rbx, [rbx + Node.next] ; Now advance the iteration, the next node goes into rbx
    cmp    rbx, [rsp + .list]     ; If it's not the head node, continue iteration
    jne    .more

.done:
    lea    rcx, [.newline]
    call    printf

    mov    rbx, [rsp + .rbx_storage] ; Restore the original value of the rbx register

    leave
    ret


main:
segment .data
.prompt_fmt: db 'Enter a int for the node value. To abort, enter a character.', 0xd, 0xa, 0
.scanf_fmt: db '%ld', 0

segment .text
.list equ 32
.k equ 40

    push    rbp
    mov    rbp, rsp
    sub    rsp, 64

    call    _CRT_INIT ; Needed since our entry point is not _DllMainCRTStartup. See https://msdn.microsoft.com/en-us/library/708by912.aspx

    call    new_list

    mov    [rsp + .list], rax   ; Store the pointer to the list that was newly-created

.more:
    lea    rcx, [.prompt_fmt]
    call    printf

    lea    rcx, [.scanf_fmt]
    lea    rdx, [rsp + .k]

    call    scanf               ; Read user input and store in k

    cmp    rax, 1               ; On failure, exit
    jne    .error_reading_input

    mov    rcx, [rsp + .list]
    mov    rdx, [rsp + .k]

    call    insert_node

    mov    [rsp + .list], rax
    mov    rcx, rax

    call    print_nodes

    jmp    .more                ; Continue looping

.error_reading_input:
    mov    rax, -1
    jmp    .done

    xor    eax, eax

.done:
    call    ExitProcess
