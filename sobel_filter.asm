bits 64
default rel

segment .text
;extern ExitProcess
;extern _CRT_INIT

; global main
global sobel

    ; Refer to the NASM documentation for how this macro works.
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


    ; note: More on the Sobel filter: https://blog.saush.com/2011/04/20/edge-detection-with-the-sobel-operator-in-ruby/
    ; Long story short: 2 3x3 convolution matrices(kernels) are used (1 is simply the other rotated 90 degrees)
    ; and the magnitude is calculated based on adding the sum of the horizontal and vertical gradients.
    ;horizontal_matrix   -1   0   1          vertical matrix   -1   -2   -1
    ;                    -2   0   2                             0    0    0
    ;                    -1   0   1                             1    2    1

; The border of the output array will be unfilled

;#define I(a, b, c) a[(b) * (cols) + (c)]
;void sobel_ref(unsigned char *data, float *out, long rows, long cols)
;{
;    int r;
;    int c;
;    int gx;
;    int gy;
;
;    for (r = 1; r < rows - 1; r++) {
;        for (c = 1; c < cols - 1; c++) {
;            gx = -I(data, r - 1, c - 1) + I(data, r - 1, c + 1) +
;                -2 * I(data, r, c - 1) + 2 * I(data, r, c + 1) +
;                -I(data, r + 1, c - 1) + I(data, r + 1, c + 1);
;
;            gy = -I(data, r - 1, c - 1) - 2 * I(data, r - 1, c) - I(data, r - 1, c + 1) +
;                 I(data, r + 1, c - 1) + 2 * I(data, r + 1, c) + I(data, r + 1, c + 1);
;
;            float val = sqrt(((float)(gx) * (float)(gx)) + ((float)(gy) * (float)(gy)));
;            I(out, r, c) = sqrt(((float)(gx) * (float)(gx)) + ((float)(gy) * (float)(gy)));
;        }
;    }
;}
sobel:
.columns equ 0
.rows equ 8
.output equ 16
.input equ 24
.bytes_per_input_row equ 32
.bytes_per_output_row equ 40

    push    rbp
    mov    rbp, rsp
    sub    rsp, 48              ; Give space for local variables on the stack

    ; Store the non-volatile registers to restore them later
    multipush rbx, rsi, r12, r13, r14, r15
    multipush_xmm xmm6, xmm7, xmm8, xmm9, xmm10, xmm11, xmm12, xmm13, xmm14, xmm15

    cmp    r8, 3                ; Need at least 3 rows to perform convolution with the matrix
    jl    .image_too_small
    cmp    r9, 3                ; Need at least 3 columns as well
    jl    .image_too_small

    ; rcx: ptr to input data in RGBA format
    ; rdx: ptr to buffer to write output data
    ; r8: num of rows
    ; r9: num of columns
    ; rbx: loop counter for number of columns
    mov    [rsp + .input], rcx  ; Store input arguments on the stack
    mov    [rsp + .output], rdx
    mov    [rsp + .rows], r8
    mov    [rsp + .columns], r9

    mov    [rsp + .bytes_per_input_row], r9    ; Num. of columns = bytes per input row
    imul    r9, 4                              ; 4 bytes per output pixel, float value for the sobel magnitude
    mov    [rsp + .bytes_per_output_row], r9

    ; rax: counter for number of rows iterated over
    mov    rax, [rsp + .rows]                  ; rax = num of rows
    mov    r11, [rsp + .columns]               ; r11 = num of columns

    sub    rax, 2               ; Subtract 2 because the top/bottom rows will not be convolved since we are using 3x3 matrices as the filter.

    add    rcx, r11              ; rcx now points to start of 2nd row of array (added the stride), we are not calculating the first row of the image

    mov    r9, rcx               ; r9 = address of start of second row
    mov    r10, rcx              ; r10 = address of start of second row

    sub    rcx, r11              ; rcx points to to the start of the input data again

    add    r10, r11             ; r10 = address of start of third row (added the stride)

    add    rdx, [rsp + .bytes_per_output_row] ; rdx advance by stride length (address of 2nd row, since first row will have zero sobel magnitude values)

    pxor    xmm13, xmm13
    pxor    xmm14, xmm14
    pxor    xmm15, xmm15

.more_rows:
    mov    rbx, 1               ; rbx = first column. Will act as our column loop counter.

.more_columns:
    ; move 16 pixels' worth of data at a time
    movdqu    xmm0, [rcx + rbx - 1] ; xmm0 = data for 1st row (on first iteration)
    movdqu    xmm1, xmm0           ; xmm1 = data for 1st row
    movdqu    xmm2, xmm0           ; xmm2 = data for 1st row

    pxor    xmm9, xmm9          ; Clear the non-volatile registers before use
    pxor    xmm10, xmm10        ; since we're using these registers as accumulators
    pxor    xmm11, xmm11
    pxor    xmm12, xmm12

    psrldq    xmm1, 1           ; shift the pixels in the first row 1 to the right in xmm1
    psrldq    xmm2, 2           ; shift the pixels in the first row 2 to the right in xmm2

    ; Now the lowest 14 values of xmm0, xmm1 and xmm2 are lined up properly for
    ; applying the top row of the 2 matrices (both Gx and Gy).

    ; note: use aligned move here to avoid paying performance penalty for unaligned memory access
    ; i.e. not on 16-byte boundary in this case.

    movdqa    xmm3, xmm0        ; xmm3 = data for 1st row
    movdqa    xmm4, xmm1        ; xmm4 = data 1st row shifted right by 1
    movdqa    xmm5, xmm2        ; xmm5 = data 1st row shifted right by 2

    punpcklbw    xmm3, xmm13    ; Interleaves the low 8 bytes of xmm3 and xmm13. (i.e. 0, val, 0, val, 0, val... for 8 times
    punpcklbw    xmm4, xmm14    ; Since xmm13 is 0, 8 words are formed in xmm3. Same goes for xmm4 and xmm5.
    punpcklbw    xmm5, xmm15
    ; Low 8 values are now words in registers xmm3, xmm4 and xmm5 ready for math (converted from bytes to words basically)

    psubw    xmm11, xmm3        ; xmm11 will hold 8 values of Gx (xmm3 - xmm11 for each word)
    psubw    xmm9, xmm3         ; xmm9 will hold 8 values of Gy

    paddw    xmm11, xmm5        ; Gx subtracts left adds right

    psubw    xmm9, xmm4         ; Gy subtracts 2 * middle pixel
    psubw    xmm9, xmm4

    psubw    xmm9, xmm5         ; Final Gy subtract

    punpckhbw    xmm0, xmm13    ; Convert top 8 bytes to words (0, v, 0, v... for 8 times)
    punpckhbw    xmm1, xmm14
    punpckhbw    xmm2, xmm15
    ; High 8 values are now words in registers xmm0, xmm1, and xmm2 ready for math.

    ; Do the same math as before, storing these 6 values in xmm12 and xmm10 instead
    psubw    xmm12, xmm0
    psubw    xmm10, xmm0

    paddw    xmm12, xmm2

    psubw    xmm10, xmm1
    psubw    xmm10, xmm1

    psubw    xmm10, xmm2

    movdqu    xmm0, [r9 + rbx - 1] ; xmm0 = data for 2nd row
    ; Repeat math from 1st row with nothing added to Gy (since Gy convolution matrix 2nd row is blank)
    movdqu    xmm2, xmm0

    psrldq    xmm2, 2           ; Shift pixels in 2nd row 2 pixels to the right

    movdqa    xmm3, xmm0        ; xmm3 = data for 2nd row
    movdqa    xmm5, xmm2        ; xmm5 = data for 2nd row shifted 2 pixels to the right

    punpcklbw    xmm3, xmm13    ; convert low 8 bytes to words here in xmm3/xmm5
    punpcklbw    xmm5, xmm15    ; 2nd row

    psubw    xmm11, xmm3        ; Gx now subtracts 2 * left pixel
    psubw    xmm11, xmm3

    paddw    xmm11, xmm5        ; ...and then Gx adds 2 * right pixel
    paddw    xmm11, xmm5

    punpckhbw    xmm0, xmm13    ; Convert high 8 bytes to words here in xmm0/xmm2
    punpckhbw    xmm2, xmm15

    psubw    xmm12, xmm0        ; Gx subtracts 2 * left pixel
    psubw    xmm12, xmm0

    paddw    xmm12, xmm2        ; and then Gx adds 2 * right pixel. Gotta do this for both high/low bytes, that's why we're repeating ourselves!
    paddw    xmm12, xmm2

    ; Same thing for the 3rd row
    movdqu    xmm0, [r10 + rbx - 1] ; xmm0 = data for 3rd row
    movdqu    xmm1, xmm0
    movdqu    xmm2, xmm0

    psrldq    xmm1, 1
    psrldq    xmm2, 2

    movdqa    xmm3, xmm0
    movdqa    xmm4, xmm1
    movdqa    xmm5, xmm2

    punpcklbw    xmm3, xmm13
    punpcklbw    xmm4, xmm14
    punpcklbw    xmm5, xmm15    ; 3rd row

    psubw    xmm11, xmm3

    paddw    xmm9, xmm3
    paddw    xmm11, xmm5

    paddw    xmm9, xmm4
    paddw    xmm9, xmm4

    paddw    xmm9, xmm5

    punpckhbw    xmm0, xmm13
    punpckhbw    xmm1, xmm14
    punpckhbw    xmm2, xmm15

    psubw    xmm12, xmm0

    paddw    xmm10, xmm0
    paddw    xmm12, xmm2

    paddw    xmm10, xmm1
    paddw    xmm10, xmm1

    paddw    xmm10, xmm2

    pmullw    xmm9, xmm9        ; square of Gx and Gy
    pmullw    xmm10, xmm10
    pmullw    xmm11, xmm11
    pmullw    xmm12, xmm12

    paddw    xmm9, xmm11        ; Sum of the squares in both x and y
    paddw    xmm10, xmm12

    movdqa    xmm1, xmm9        ; xmm1 = sum of squares in x
    movdqa    xmm3, xmm10       ; xmm2 = sum of squares in y

    punpcklwd    xmm9, xmm13    ; convert low 4 words to dwords...

    punpckhwd    xmm1, xmm13    ; convert high 4 words to dwords...

    punpcklwd    xmm10, xmm13   ; convert low 4 words to dwords...

    punpckhwd    xmm3, xmm13    ; convert high 4 words to dwords...

    cvtdq2ps    xmm0, xmm9      ;...to floating point
    cvtdq2ps    xmm1, xmm1      ; ...
    cvtdq2ps    xmm2, xmm10
    cvtdq2ps    xmm3, xmm3

    sqrtps    xmm0, xmm0
    sqrtps    xmm1, xmm1
    sqrtps    xmm2, xmm2
    sqrtps    xmm3, xmm3

    movups    [rdx + rbx * 4], xmm0 ; and modify the image values with the gradient intensity
    movups    [rdx + rbx * 4 + 16], xmm1
    movups    [rdx + rbx * 4 + 32], xmm2

    movlps    [rdx + rbx * 4 + 48], xmm3

    add    rbx, 14              ; Process 14 Sobel values at a time (16 - 1 - 1px), so increment counter

    cmp    rbx, r11             ; Check if we have iterated over all columns
    jl    .more_columns

    add    rcx, r11             ; Increment all counters by the number of rows
    add    r9, r11
    add    r10, r11
    add    rdx, [rsp + .bytes_per_output_row] ; Increment bytes counter so that writing to the next pixel's memory will be correct
    sub    rax, 1               ; 1 fewer row to go, so decrement the counter
    cmp    rax, 0               ; Have we finished iterating over all rows?
    jg    .more_rows

.image_too_small:
    multipop_xmm xmm6, xmm7, xmm8, xmm9, xmm10, xmm11, xmm12, xmm13, xmm14, xmm15
    multipop rbx, rsi, r12, r13, r14, r15

    leave
    ret


; main:
;     push    rbp
;     mov    rbp, rsp
;     sub    rsp, 64

;     call _CRT_INIT

;     ; todo: implement test of sobel function from pure asm eventually

;     xor    eax, eax
;     call ExitProcess
