default rel
bits 64

segment .bss

struc Node
    .value resq 1                   ; Data
    .next resq 1                    ; pointer to next node
endstruc


segment .text

extern ExitProcess
extern _CRT_INIT
extern malloc
extern free
extern scanf
extern printf

global main


new_list:                        ; Empty list will be ``NULL``
    xor    eax, eax
    ret


    ; list = insert(list, item);
insert_node:
.list equ 32
.item equ 40

    push    rbp
    mov    rbp, rsp
    sub    rsp, 64

    mov    [rsp + .list], rcx   ; save list pointer into function
    mov    [rsp + .item], rdx   ; save item passed into function

    mov    ecx, Node_size     ; The size is defined via an EQU directive by NASM behind the scenes
    call    malloc              ; rax = pointer to node memory allocated

    mov    r8, [rsp + .list]    ; Get pointer to the list and put in r8
    mov    [rax + Node.next], r8 ; r8 points to the next node
    mov    r9, [rsp + .item]     ; Get the next item's data and put in r9
    mov    [rax + Node.value], r9 ; Save the item value in the node

    leave
    ret

    ; Traversal of the list requires using an instruction like:
    ; mov    ptr_node, [ptr_node + Node.next]
    ; in order to advance from a pointer in one node to a pointer in the next node.
print_nodes:
segment .data
.print_fmt: db '%ld', 0
.newline: db 0xd, 0xa, 0            ; 0xd is CR, 0xa is LF char

segment .text
.rbx_storage equ 32
    push    rbp
    mov    rbp, rsp
    sub    rsp, 64

    mov    [rsp + .rbx_storage], rbx ; save original rbx value, we depend on it being preserved by printf
    cmp    rcx, 0                             ; skip the loop if list pointer is NULL
    je    .done
    mov    rbx, rcx                           ; get first node that was passed into function, save in rbx since it is preserved across calls.

.more:
    lea    rcx, [.print_fmt]
    mov    rdx, [rbx + Node.value]

    call    printf              ; Print the node's value

    mov    rbx, [rbx + Node.next] ; point rbx to the next node
    cmp    rbx, 0                       ; end the loop if node pointer is NULL
    jne    .more                        ; If not NULL, keep printing!

.done:
    lea    rcx, [.newline]
    call    printf              ; Print a newline

    mov    rbx, [rsp + .rbx_storage] ; restore rbx to the pointer to the first node

    leave
    ret


main:
segment .data
.list equ 32
.k equ 40

.prompt_fmt: db 'Enter a int for the node value. To abort, enter a character.', 0xd, 0xa, 0
.scanf_fmt: db '%ld', 0

segment .text
    push    rbp
    mov    rbp, rsp
    sub    rsp, 64

    call    _CRT_INIT                 ; Needed since our entry point is not _DllMainCRTStartup. See https://msdn.microsoft.com/en-us/library/708by912.aspx

    call    new_list

    mov    [rsp + .list], rax   ; Store the new list pointer

.more:
    lea    rcx, [.prompt_fmt]
    call    printf

    lea    rcx, [.scanf_fmt]
    lea    rdx, [rsp + .k]

    call    scanf               ; Read user input and store in k

    cmp    rax, 1               ; On failure, exit
    jne    .done

    mov    rcx, [rsp + .list]   ; Get the list into argument pos 1
    mov    rdx, [rsp + .k]      ; Get the user input into argument pos 2

    call    insert_node

    mov    [rsp + .list], rax   ; Save result on stack, we'll print it next
    mov    rcx, rax

    call    print_nodes

    jmp    .more                   ; Loop some more

.done:
    xor    eax, eax             ; Successful exit code
    call    ExitProcess
