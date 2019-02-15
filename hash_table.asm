default rel
bits 64

segment .bss
struc Node
.value resq 1
.next resq 1
endstruc


segment .data
    hash_table_size dq 256
    string_hash_prime dq 191

    table times 256 dq 0

    help_text_fmt: db 'Enter a value for the node:', 0xd, 0xa, 0
    scanf_fmt: db '%ld', 0


segment .text

extern ExitProcess
extern _CRT_INIT
extern malloc
extern printf
extern scanf


global main

    ; i = hash_int(n); we're using ``n mod t`` where ``n`` is the key and ``t`` is the array size.
    ; Example table size is 256 (0xff),
hash_int: ; Ultra simple hash, just bitwise & the value with 0xff mask which is ``n mod 256``.
    mov    eax, ecx    ; For such simple functions, there's no need to
    and    eax, 0xff   ; reserve a stack frame

    ret

    ; String hashing: one way is to treat the string as containing polynomial coefficients
    ; and evaluate p(n) for some prime number ``n``. E.g. using ``191``. After evaluating the
    ; polynomial value, we can perform a modulus operation using the table size.
    ; Using a prime number in the computation makes it less important that the table
    ; size is a prime.
    ; int hash(char *s)
    ; {
    ;     int h = 0;
    ;     int i = 0;
    ;     while (s[i]) {
    ;          h = (h * 191) + s[i];
    ;          ++i;
    ;     }
    ;     return h % 0xff;
    ; }
hash_str:
.s equ 32

    push    rbp
    mov    rbp, rsp
    sub    rsp, 64

    mov    [rsp + .s], rcx      ; store ptr to string passed in

.loop:
    cmp    rcx, 0               ; Until we hit string null terminator, continue
    je    .end_of_string

    mov    r8, 0                 ; r8 is the loop counter to loop through the char array
    mov    r9, [string_hash_prime] ; Prime number chosen
    xor    r10, r10
    imul   r10, r9
    add    r10, [rsp + .s + r8] ; r10 will store the final hash result
    inc    r8
    jmp    .loop

.end_of_string:
    ; Remember, division remainder is modulo
    mov    r11, [hash_table_size]
    mov    rax, r10
    div    r11                  ; Divides rax by r11, quotient stored in rax and remainder stored in rdx

    mov    rdx, rax

    leave
    ret


    ; node = find_item(n) where n is the node value
    ; returns ``0`` if not found
find_item:
.n equ 32

    push    rbp
    mov    rbp, rsp
    sub    rsp, 64

    mov    [rsp + .n], rcx      ; Save input on stack
    call    hash_int            ; rax = hash(n)

    lea    r8, [table]          ; work around RIP-relative addressing for x64
    mov    rax, [r8 + rax * 8]  ; node = table[h]
    mov    rcx, [rsp + .n]      ; restore n
    cmp    rax, 0               ; if node ptr is 0, quit (means there are no entries for that key left)
    je    .done

.more:
    cmp    rcx, [rax + Node.value] ; if node->value == n then return the node
    je    .done
    mov    rax, [rax + Node.next] ; node = node->next (otherwise, go along the linked list until we find a node that matches the value passed in)
    cmp    rax, 0                 ; keep looping until node ptr is 0
    jne .more

.done:
    leave
    ret


    ; insert(node) : this gets inserted into the global ``table`` memory
insert_item:
.n equ 32
.hash_value equ 40
    push    rbp
    mov    rbp, rsp
    sub    rsp, 64

    mov    [rsp + .n], rcx      ; Save the ptr to the node passed in
    call    find_item           ; If the node is not found in the hash table, then add it

    cmp    rax, 0               ; this way we avoid adding duplicate entries
    jne    .found

    mov    rcx, [rsp + .n]      ; Get the node back from the stack and store in rcx
    call    hash_int            ; Compute the hash for this node

    mov    [rsp + .hash_value], rax ; Save the computed hash on the stack

    mov    rcx, Node_size
    call    malloc              ; Allocate size of storage of the node: at this
                                ; point, rax will point to the storage for the new node

    mov    r9, [rsp + .hash_value] ; get the hash value
    lea    r10, [table]
    mov    r8, [r10 + r9 * 8]   ; get the first node from table[hash_value]

    mov    [rax + Node.next], r8 ; Set next ptr of node newly allocated to the first node
    mov    r8, [rsp + .n]          ; Set value of new node to n
    mov    [rax + Node.value], r8
    mov    [r10 + r9 * 8], rax     ; make node first entry in table[hash_value]

.found:
    leave
    ret

; print iterates through entire global table, printing the index number and the keys
print_hash_table:
.r12_storage equ 32
.r13_storage equ 40

    push    rbp
    mov    rbp, rsp
    sub    rsp, 64

    mov    [rsp + .r12_storage], r12 ; Save the orig. values of r12 and r13 on the stack
    mov    [rsp + .r13_storage], r13 ; r12 will be the counter for iteration, and r13 will be the ptr for the list (i.e. table[r12])

    ; for (int i=0; i < 256; ++i)
    ; Clear the loop counter before we begin
    xor    r12, r12

.loop_begin:
    lea    r10, [table]
    mov    r13, [r10 + r12 * 8] ; table[r12] is now in r13

    cmp    r13, 0
    je    .continue_loop

    ; Print the list header
segment .data
.print_fmt_index: db 'list %3d: ', 0

segment .text
    lea    rcx, [.print_fmt_index]
    mov    rdx, r12
    call    printf

    ; Now print all values associated with the index
.iterate_values:

segment .data
.print_fmt_values: db 'val: %ld ', 0

segment .text
    lea    rcx, [.print_fmt_values]
    mov    rdx, [r13 + Node.value]
    call    printf

    mov    r13, [r13 + Node.next] ; advance to the next node
    cmp    r13, 0                 ; while the node is not NULL (haven't reached the end of the list), keep printing
    jne    .iterate_values

segment .data
.print_fmt_newline: db 0xd, 0xa, 0

segment .text
    lea    rcx, [.print_fmt_newline]
    call    printf

.continue_loop:
    inc    r12
    mov    r11, [hash_table_size]
    cmp    r12, r11
    jl    .loop_begin

    ; Restore r12 and r13 since the x64 calling convention dictates that they are non-volatile registers
    mov    r12, [rsp + .r12_storage]
    mov    r13, [rsp + .r13_storage]

    leave
    ret


main:
.n equ 32

    push    rbp
    mov    rbp, rsp
    sub    rsp, 64

    call    _CRT_INIT

.read_input:
    lea    rcx, [help_text_fmt]
    call    printf

    lea    rcx, [scanf_fmt]
    lea    rdx, [rsp + .n]      ; Store user input in n

    call    scanf

    cmp    rax, 1
    jne    .done                ; If the reading of user input failed, exit

    mov    rcx, [rsp + .n]

    call    insert_item

    call    print_hash_table

    jmp    .read_input

.done:
    xor     eax, eax
    call    ExitProcess
