bits 64
default rel

segment .bss
; Remember, the alignment must be the size of the largest data item in the struct.
; Can use ``alignb`` to achieve this if necessary.
struc Node
.value resq 1
.left resq 1
.right resq 1
endstruc

struc Tree
.count resq 1
.root resq 1
endstruc


segment .text

extern ExitProcess
extern _CRT_INIT
extern malloc
extern printf
extern scanf

global main


    ; newTreePtr = new_tree();
new_tree:
    push    rbp
    mov    rbp, rsp
    sub    rsp, 64

    mov    rcx, Tree_size
    call    malloc

    cmp    rax, 0
    je    .error

    xor    ecx, ecx

    mov    [rax + Tree.root], rcx ; New tree has no root node yet
    mov    [rax + Tree.count], rcx ; New tree has a node count of zero

    jmp    .done

.error:
    xor    rax, rax
    mov    eax, 0

.done:
    leave
    ret


    ; ptr_to_node = find_node_in_tree(tree, node); NULL if not found
find_node_in_tree:
    push    rbp
    mov    rbp, rsp
    sub    rsp, 64

    mov    rcx, [rcx + Tree.root] ; Store the tree root node in rcx
    xor    eax, eax

.loop:
    cmp    rcx, 0               ; If we've reached a sentinel value, end iteration
    je    .done

    cmp    rdx, [rcx + Node.value] ; Compare the node value passed in with the current node's value
    jl    .traverse_left
    jg    .traverse_right

    mov    rax, rcx             ; Move the node to rax
    jmp    .done

.traverse_left:
    mov    rcx, [rcx + Node.left]
    jmp    .loop

.traverse_right:
    mov    rcx, [rcx + Node.right]
    jmp    .loop

.done:
    leave
    ret


; insert_node(tree, node)
insert_node:
.node equ 32
.tree equ 40

    push    rbp
    mov    rbp, rsp
    sub    rsp, 64

    mov    [rsp + .tree], rcx   ; save the parameters passed in onto the stack
    mov    [rsp + .node], rdx

    ; Check if the node already exists in the tree to prevent cycles (i.e. inserting when it already exists)
    call    find_node_in_tree
    cmp    rax, 0

    jne    .done                ; If it already exists, don't insert

    mov    rcx, Node_size
    call    malloc              ; Allocate memory for a new node

    mov    rdx, [rsp + .node]   ; Get the node that was passed in
    mov    [rax + Node.value], rdx ; Store the node's value that was passed in into the new node's value

    ; We'll set the Lf/Rt sides of the new node to sentinel values first; we'll
    ; decide where it goes in the tree right after this
    xor    r10, r10
    mov    [rax + Node.left], r10 ; set the new node's left side to NULL
    mov    [rax + Node.right], r10 ; set the new node's right side to NULL

    mov    r9, [rsp + .tree]    ; Get the tree that was passed in
    mov    rcx, [r9 + Tree.count] ; Get the number of nodes in the tree passed in
    cmp    rcx, 0                 ; If the tree has no existing nodes, node inserted is the first one

    jne    .find_parent

    inc    qword [r9 + Tree.count] ; count = 1
    mov    [r9 + Tree.root], rax   ; The tree root points to the new node created (if first node in tree is being inserted)
    jmp    .done

.find_parent:
    inc    qword [r9 + Tree.count] ; increment the tree node count for the new node inserted
    mov    r9, [r9 + Tree.root]    ; r9 now points to the root node of the tree

.loop:
    cmp    rdx, [r9 + Node.value] ; check if node's value passed in is less than root node's value
    jl    .traverse_left

    mov    r8, r9               ; Store the current node in r8
    mov    r9, [r8 + Node.right] ; Store current node's right side in r9
    cmp    r9, 0                 ; If we have reached a sentinel value for the right side, add the node here
    jne    .loop

    mov    [r8 + Node.right], rax ; Set the current node's right to point to the new node created
    jmp    .done

.traverse_left:
    mov    r8, r9               ; Store the current node in r8
    mov    r9, [r8 + Node.left] ; Store current node's left side in r9
    cmp    r9, 0                ; If we have reached a sentinel value for the left side, add the node here instead
    jne    .loop

    mov    [r8 + Node.left], rax ; Set the current node's left to point to the new node created

.done:
    leave
    ret


    ; print_recurse_tree(node)
print_recurse_tree:
segment .data
    .print_fmt db '%ld ', 0
segment .text
.node equ 32

    push    rbp
    mov    rbp, rsp
    sub    rsp, 64

    cmp    rcx, 0               ; Once we hit the sentinel value, end recursion
    je    .done

    mov    [rsp + .node], rcx   ; Store the node passed in onto the stack
    mov    rcx, [rcx + Node.left] ; Go to the first node in the tree
    call    print_recurse_tree

    mov    rcx, [rsp + .node]
    mov    rdx, [rcx + Node.value] ; Get the value from the tree and print it

    lea    rcx, [.print_fmt]
    call    printf

    mov    rcx, [rsp + .node]
    mov    rcx, [rcx + Node.right] ; Now go to the right node

    call    print_recurse_tree

.done:
    leave
    ret

    ; print_tree(root)
    ; This prints all keys in the left sub-tree, then the root node's key, then the
    ; keys of the right sub-tree.
print_tree:
segment .data
    .print_endline db 0xd, 0xa, 0 ; CRLF null terminator
segment .text
    push    rbp
    mov    rbp, rsp
    sub    rsp, 64

    mov    rcx, [rcx + Tree.root] ; Store tree root node passed in
    call    print_recurse_tree

    lea    rcx, [.print_endline]
    call    printf

    leave
    ret


main:
segment .data
    .prompt_fmt db 'Enter an integer for the node value. To abort, enter a character', 0xd, 0xa, 0
    .scanf_fmt db '%ld', 0

segment .text
.tree equ 32
.k equ 40

    push    rbp
    mov    rbp, rsp
    sub    rsp, 64

    call _CRT_INIT

    call    new_tree

    mov    [rsp + .tree], rax   ; Tree just created is saved on the stack

.more:
    lea    rcx, [.prompt_fmt]
    call    printf

    lea    rcx, [.scanf_fmt]
    lea    rdx, [rsp + .k]
    call    scanf               ; Read user input and store in k

    cmp    rax, 1               ; On failure, exit
    jne    .error_reading_input

    mov    rcx, [rsp + .tree]
    mov    rdx, [rsp + .k]
    call    insert_node

    mov    rcx, [rsp + .tree]
    call    print_tree

    jmp    .more

.error_reading_input:
    mov    rax, -1
    jmp .done

.done:
    xor    eax, eax
    call    ExitProcess
