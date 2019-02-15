%include "macros.inc"

bits 64
default rel

segment .text

global correlation_sse
global correlation_avx

    ; SSE is a more widely-supported instruction set.
    ; todo: figure out the limitation re. needing the sample count to be aligned to 16
correlation_sse:
    ; Store the non-volatile registers to restore them later
    multipush_xmm xmm6, xmm7, xmm8, xmm9, xmm10, xmm11, xmm12, xmm13, xmm14, xmm15

    ; register usage:
    ; rcx : x array
    ; rdx : y array
    ; r8  : number of samples (n)

    ; r9  : sample counter
    ; r10 : loop counter

    ; xmm0 : 2 parts of sumX
    ; xmm1 : 2 parts of sumY
    ; xmm2 : 2 parts of sumXX
    ; xmm3 : 2 parts of sumYY
    ; xmm4 : 2 parts of sumXY
    ; xmm5 : 2 x values - later squared
    ; xmm6 : 2 y values - later squared
    ; xmm7 : 2 xy values
    xor    r9d, r9d             ; Start the sample counter at 0
    mov    r10, r8              ; r10 = number of samples (copy)

    subpd    xmm0, xmm0         ; Use subpd for doubles (psubd for ints) This basically zeros out the xmm0 register.

    movapd    xmm1, xmm0        ; zero out the xmm registers we're about to use
    movapd    xmm2, xmm0
    movapd    xmm3, xmm0
    movapd    xmm4, xmm0
    movapd    xmm8, xmm0
    movapd    xmm9, xmm0
    movapd    xmm10, xmm0
    movapd    xmm11, xmm0
    movapd    xmm12, xmm0

.loop:
    ; We can use aligned here since we're guaranteed our double is aligned on 16 byte boundaries
    movapd    xmm5, [rcx + r9]  ; current x value goes into xmm5 based off sample counter
    movapd    xmm6, [rdx + r9]  ; current y value goes into xmm6 based off sample counter

    movapd    xmm7, xmm5        ; xmm7 = current x value (copy)
    mulpd    xmm7, xmm6         ; xmm7 = x * y

    addpd    xmm0, xmm5         ; xmm0 = sumX (copy)
    addpd    xmm1, xmm6         ; xmm1 = sumY (copy)
    mulpd    xmm5, xmm5         ; xmm5 = x * x
    mulpd    xmm6, xmm6         ; xmm6 = y * y

    addpd    xmm2, xmm5         ; xmm2 = sumXX
    addpd    xmm3, xmm6         ; xmm3 = sumYY
    addpd    xmm4, xmm7         ; xmm4 = sumXY

    ; Load the next 128 bits into the registers
    movapd    xmm13, [rcx + r9 + 16] ; xmm13 = next 16 bytes (128 bits) after current x
    movapd    xmm14, [rdx + r9 + 16] ; xmm14 = next 16 bytes after current y

    movapd    xmm15, xmm13      ; xmm15 = next 16 bytes after current x (copy)
    mulpd    xmm15, xmm14       ; x * y

    addpd    xmm8, xmm13        ; sumX
    addpd    xmm9, xmm14        ; sumY

    mulpd    xmm13, xmm13       ; x * x
    mulpd    xmm14, xmm14       ; y * y

    addpd    xmm10, xmm13       ; sumXX
    addpd    xmm11, xmm14       ; sumYY
    addpd    xmm12, xmm15       ; sumXY

    add    r9, 32               ; We're doing 16 + 16 bytes per loop iteration (i.e. 4 doubles)
    sub    r10, 4               ; Decrement the counter by number of doubles processed
    jnz    .loop                ; Continue looping until all doubles are exhausted

    addpd    xmm0, xmm8         ; xmm0 = sumX (combine both the parallel SIMD registers' results)
    addpd    xmm1, xmm9         ; xmm1 = sumY
    addpd    xmm2, xmm10        ; xmm2 = sumXX
    addpd    xmm3, xmm11        ; xmm3 = sumYY
    addpd    xmm4, xmm12        ; xmm4 = sumXY

    ; haddpd explanation
    ; adds the high quadword to the low quadword and stores result in low quadword of destination operand.
    ; a           b          (where each letter refers to a 64 bit double value)
    ; c           d
    ; a + b      c + d           result

    haddpd    xmm0, xmm0        ; xmm0 = sumX (we're adding both doubles together)
    haddpd    xmm1, xmm1        ; xmm1 = sumY
    haddpd    xmm2, xmm2        ; xmm2 = sumXX
    haddpd    xmm3, xmm3        ; xmm3 = sumYY
    haddpd    xmm4, xmm4        ; xmm4 = sumXY

    movsd    xmm6, xmm0         ; xmm6 = sumX (copy)
    movsd    xmm7, xmm1         ; xmm7 = sumY (copy)

    cvtsi2sd    xmm8, r8        ; xmm8 = n (convert int to double)

    mulsd    xmm6, xmm6         ; sumX * sumX
    mulsd    xmm7, xmm7         ; sumY * sumY
    mulsd    xmm2, xmm8         ; sumXX * n
    mulsd    xmm3, xmm8         ; sumYY * n

    ; subtracts the low double in 2nd from 1st
    subsd    xmm2, xmm6         ; (n * sumXX) - (sumX * sumX) = varX
    subsd    xmm3, xmm7         ; (n * sumYY) - (sumY * sumY) = varY

    ; multiplies the low doubles
    mulsd    xmm2, xmm3         ; varX * varY
    sqrtsd    xmm2, xmm2

    mulsd    xmm4, xmm8         ; sumXY * n
    mulsd    xmm0, xmm1         ; sumX * sumY

    subsd    xmm4, xmm0         ; (sumXY * n) = (sumX * sumY) = covXY

    divsd    xmm4, xmm2
    movsd    xmm0, xmm4         ; return value goes in xmm0 according to convention

    ; Restore the original volatile registers
    multipop_xmm xmm6, xmm7, xmm8, xmm9, xmm10, xmm11, xmm12, xmm13, xmm14, xmm15

    ret


    ; AVX support is not as widespread
correlation_avx:
    ; Store the non-volatile registers to restore them later
    multipush_ymm ymm6, ymm7, ymm8, ymm9, ymm10, ymm11, ymm12, ymm13, ymm14, ymm15

    ; rcx: x array
    ; rdx: y array
    ; r8: num of samples
    ; r9  : sample counter
    ; r10: loop counter

    ; ymm0: 4 parts of sumX (work on 4 values at a time)
    ; ymm1: 4 parts of sumY
    ; ymm2: 4 parts of sumXX
    ; ymm3: 4 parts of sumYY
    ; ymm4: 4 parts of sumXY
    ; ymm5; 4 x values - later squared
    ; ymm6: 4 y values - later squared
    ; ymm7: 4 xy values

    xor    r9d, r9d
    mov    r10, r8              ; r10 = num of samples (copy)

    vzeroall                    ; zeros the contents of all the ymm registers.

.loop:
    vmovupd    ymm5, [rcx + r9] ; ymm5 = 4 doubles from x
    vmovupd    ymm6, [rdx + r9] ; ymm6 = 4 doubles from y

    ; AVX instructions ymm7 = ymm5 * ymm6: (can name same register twice)
    ; Having 3 operands reduces the register pressure and allows using 2 registers
    ; as sources in an instruction while preserving their values.
    vmulpd    ymm7, ymm5, ymm6  ; ymm7 = x * y (calc. this first so we can just act on ymm5/6 in-place later)

    vaddpd    ymm0, ymm0, ymm5  ; ymm0 = sumX (SIMD add the 4 doubles ymm0 + ymm5 and store in ymm0)
    vaddpd    ymm1, ymm1, ymm6  ; ymm1 = sumY

    vmulpd    ymm5, ymm5, ymm5  ; ymm5 = x * x
    vmulpd    ymm6, ymm6, ymm6  ; ymm6 = y * y

    vaddpd    ymm2, ymm2, ymm5  ; ymm2 = sumXX
    vaddpd    ymm3, ymm3, ymm6  ; ymm3 = sumYY
    vaddpd    ymm4, ymm4, ymm7  ; ymm4 = sumXY

    ; Load the next 256 bits into the registers and apply the same math
    vmovupd    ymm13, [rcx + r9 + 32] ; ymm13 = next 256 bits after current x
    vmovupd    ymm14, [rdx + r9 + 32] ; ymm14 = next 256 bits after current y

    vmulpd    ymm15, ymm13, ymm14 ; ymm15 = x * y

    vaddpd    ymm8, ymm8, ymm13 ; ymm8 = sumX
    vaddpd    ymm9, ymm9, ymm14 ; ymm9 = sumY

    vmulpd    ymm13, ymm13, ymm13 ; ymm13 = x * x
    vmulpd    ymm14, ymm14, ymm14 ; ymm14 = y * y

    vaddpd    ymm10, ymm10, ymm13 ; ymm10 = sumXX
    vaddpd    ymm11, ymm11, ymm14 ; ymm11 = sumYY
    vaddpd    ymm12, ymm12, ymm15 ; ymm12 = sumXY

    add    r9, 64               ; We're doing 32 + 32 bytes per loop iteration (i.e. 8 doubles)
    sub    r10, 8               ; Decrement the sample counter by the number of doubles processed
    jnz    .loop                ; Continue looping until all samples have been processed

    vaddpd    ymm0, ymm0, ymm8  ; SIMD add up both sumX totals
    vaddpd    ymm1, ymm1, ymm9  ; Same for sumY

    vaddpd    ymm2, ymm2, ymm10 ; SIMD add up both sumXX totals
    vaddpd    ymm3, ymm3, ymm11 ; Same for sumYY

    vaddpd    ymm4, ymm4, ymm12 ; Same for sumXY

    ; vhaddpd differs from haddpd a little; this is the operation (4 x 64bit doubles)
    ;
    ;  input    x3            x2             x1           x0
    ;  input2   y3            y2             y1           y0
    ;  result   y2 + y3      x2 + x3        y0 + y1      x0 + x1

    vhaddpd    ymm0, ymm0, ymm0 ; ymm0 = sumX (sum up the doubles)
    vhaddpd    ymm1, ymm1, ymm1 ; ymm1 = sumY
    vhaddpd    ymm2, ymm2, ymm2 ; ymm2 = sumXX
    vhaddpd    ymm3, ymm3, ymm3 ; ymm3 = sumYY
    vhaddpd    ymm4, ymm4, ymm4 ; ymm4 = sumXY

    ; vextractf128: Extracts 128 bits of packed floats from second operand and stores results in dest.
    ; xmm5 = sumX (copy of the lower 2 doubles)
    vextractf128    xmm5, ymm0, 1 ; 3rd operand determines offset to start extraction (128bit offset from operand specified)
    ; add scalar double
    vaddsd    xmm0, xmm0, xmm5  ; xmm0 = lower 2 doubles of sumX * 2

    vextractf128    xmm6, ymm1, 1 ; Do same thing for sumY
    vaddsd    xmm1, xmm1, xmm6

    vmulsd    xmm6, xmm0, xmm0  ; xmm6 = sumX * sumX
    vmulsd    xmm7, xmm1, xmm1  ; xmm7 = sumY * sumY

    vextractf128    xmm8, ymm2, 1 ; xmm8 = sumXX
    vaddsd    xmm2, xmm2, xmm8  ; xmm2 = sumXX

    vextractf128    xmm9, ymm3, 1 ; xmm9 = sumYY
    vaddsd    xmm3, xmm3, xmm9    ; xmm3 = sumYY

    cvtsi2sd    xmm8, r8        ; convert n from int to double and store in xmm8

    vmulsd    xmm2, xmm2, xmm8  ; xmm2 = n * sumXX
    vmulsd    xmm3, xmm3, xmm8  ; xmm3 = n * sumYY

    vsubsd    xmm2, xmm2, xmm6  ; xmm2 = (n * sumXX) - (sumX * sumX)
    vsubsd    xmm3, xmm3, xmm7  ; xmm3 = (n * sumYY) - (sumY * sumY)

    vmulsd    xmm2, xmm2, xmm3  ; xmm2 = varX * varY
    vsqrtsd    xmm2, xmm2, xmm2 ; xmm2 = sqrt(varX * varY)

    vextractf128    xmm6, ymm4, 1 ; xmm6 = lower 2 doubles of sumXY

    vaddsd    xmm4, xmm4, xmm6  ; xmm4 = lower 2 doubles of sumXY + other 2 doubles of sumXY
    vmulsd    xmm4, xmm4, xmm8  ; xmm4 = n * sumXY
    vmulsd    xmm0, xmm0, xmm1  ; xmm0 = sumX * sumY
    vsubsd    xmm4, xmm4, xmm0  ; xmm4 = (n * sumXY) - (sumX * sumY)

    vdivsd    xmm0, xmm4, xmm2  ; xmm0 = covXY / sqrt(varX * varY)

    ; Restore the original volatile registers
    multipop_ymm ymm6, ymm7, ymm8, ymm9, ymm10, ymm11, ymm12, ymm13, ymm14, ymm15

    ret
