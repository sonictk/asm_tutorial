bits 64
default rel

segment .text
extern ExitProcess
extern _CRT_INIT


global main

    ; long popcnt_array(unsigned long long *a, int size);
    ; Counts all the 1 bits in an array of qword integers.

    ;long popcnt_array (unsigned long long *a, int size)
    ;{
    ;    unsigned long long word;
    ;    long n = 0;
    ;    for (int w = 0; w < size; w++ ) {
    ;        word = a[w];
    ;        while ( word != 0 ) {
    ;            n += word & 1;
    ;            word >>= 1;
    ;        }
    ;    }
    ;    return n;
    ;}
    ; Faster alternative:
    ; Can precompute the number of bits in each possible bit pattern for a byte
    ; and use an array of 256 bytes to store the number of bits in each possible byte.
    ; Then use the 8 bytes of the quad word as indices into the array of bit counts
    ; and add them up.
    ;long popcnt_array ( long long *a, int size )
    ;{
    ;    long n = 0;
    ;    int word;
    ;    for (int b = 0; b < size*8; b++ ) {
    ;        word = ((unsigned char *)a)[b];
    ;        n += count[word];
    ;    }
    ;    return n;
    ;}

    ; Unroll the loop for working on 64 bits into 64 steps of working on 1 bit.
    ; Place 1/4 of the bits of each word in rax, rbx, rcx and rdx, then accumulate
    ; each fourth using different registers. This allows out of order execution
    ; with the loop by the CPU.
popcnt_array_unrolled:
.loop:
    ; Save the non-volatile registers on the stack
    push    rdi
    push    rsi
    push    rbx
    push    rbp
    push    r12
    push    r13
    push    r14
    push    r15

    mov    rdi, rcx   ; store  ptr to 64 bit int array in rdi
    mov    rsi, rdx   ; Store size limit in rsi

    ; Clear the volatile/non-volatile registers before using them
    xor    eax, eax
    xor    ebx, ebx
    xor    ecx, ecx
    xor    edx, edx
    xor    r12d, r12d
    xor    r13d, r13d
    xor    r14d, r14d
    xor    r15d, r15d

.count_words:
    mov    r8, [rdi]            ; Get ptr to array and put in r8
    mov    r9, r8               ; Copy it to r9, r10 and r11 as well
    mov    r10, r8
    mov    r11, r8

    and    r8, 0xffff           ; AND 64 bit int with 16 bits masks off the high-order 16 bits, thus lower 16 bits are unchanged
    shr    r9, 16               ; 1/4 of the bits in r9, r10, r11, and r12 each

    and    r9, 0xffff
    shr    r10, 32

    and    r10, 0xffff
    shr    r11, 48

    and    r11, 0xffff
    mov    r12w, r8w

    and    r12w, 1              ; Increment counter for number of bits for each register "job".
    add    rax, r12
    mov    r13w, r9w

    and    r13w, 1
    add    rbx, r13
    mov    r14w, r10w

    and    r14w, 1
    add    rcx, r14
    mov    r15w, r11w

    and    r15w, 1
    add    rdx, r15

%rep 15                         ; Repeat process until total 16 times have been reached
    shr    r8w, 1
    mov    r12w, r8w

    and    r12w, 1
    add    rax, r12

    shr    r9w, 1
    mov    r13w, r9w
    and    r13w, 1

    add    rbx, r13
    shr    r10w, 1
    mov    r14w, r10w

    and    r14w, 1
    add    rcx, r14

    shr    r11w, 1
    mov    r15w, r11w

    and    r15w, 1
    add    rdx, r15
%endrep

    add    rdi, 8

    dec    rsi                  ; Will set the zero flag, overflow and sign flags
    jg    .count_words          ; jump short if greater(zero flag=0) and Sign flag == overflow flag
    ; Basically keep looping until we hit the size that was passed in

    add    rax, rbx             ; Add up all the counters of the bits for each "job" and store in rax return value
    add    rax, rcx
    add    rax, rdx

    pop    r15                  ; Restore the non-volatile register values
    pop    r14
    pop    r13
    pop    r12
    pop    rbp
    pop    rbx
    pop    rsi
    pop    rdi

    ret


    ; Better version using popcnt instruction available in Intel instruction set
    ; note: This assumes an array size of at least 4, and that the array size is a multiple of 4.
popcnt_array:
    ; Store the original values of the non-volatile registers before using them
    push    r12
    push    r13
    push    r14
    push    r15

    xor    eax, eax
    xor    r8d, r8d
    xor    r9d, r9d
    xor    r14d, r14d
    xor    r15d, r15d

.loop:
    ; Calculate the number of bits for each of the numbers in the array and use
    ; r10, r11, r12, r13 as the intermediate registers to hold the results, along
    ; with rax, r8, r14, and r15 as the accumulators.
    popcnt    r10, [rcx + r9 * 8]
    add    rax, r10
    popcnt    r11, [rcx + r9 * 8 + 8]
    add    r8, r11
    popcnt    r12, [rcx + r9 * 8 + 16]
    add    r14, r12
    popcnt    r13, [rcx + r9 * 8 + 24]
    add    r15, r13
    add    r9, 4                ; Array counter. We just worked on 4 numbers, so inc by 4
    cmp    r9, rdx              ; Continue until we hit the size limit
    jl    .loop

    add    rax, r8              ; Add up the accumulators
    add    rax, r14
    add    rax, r15

    ; Restore the original register values
    pop    r15
    pop    r14
    pop    r13
    pop    r12

    ret


main:
segment .data
array: dq 4, 4, 4, 4, 4, 4, 4, 4
array_size: dq 8


segment .text

    push    rbp
    mov    rbp, rsp
    sub    rsp, 64

    call    _CRT_INIT

    lea    rcx, [array]
    mov    rdx, [array_size]

    call    popcnt_array_unrolled

    lea    rcx, [array]
    mov    rdx, [array_size]

    call    popcnt_array

    xor    eax, eax
    call ExitProcess
