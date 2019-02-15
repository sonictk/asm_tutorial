bits 64
default rel

segment .data
    search_string db "hello world"
    n dq 0

search_term: db 'w'

segment .text
global main
extern ExitProcess

main:
    push    rbp                 ; set up a stack frame
    mov    rbp, rsp             ; base pointer points to stack frame
    sub    rsp, 32              ; leave room for shadow params, stack pointer on 16 byte boundary


    ; This program searches a char array terminated by a 0 byte.
    ; rax will be current byte being searched
    ; bl will be byte to search for
    ; ecx will be loop counter
    ; i = 0
    ; c = data[i]
    ; if (c != 0) {
    ;     do {
    ;         if (c == x) break;
    ;         ++i;
    ;         c = data[i];
    ;     } while (c != 0);
    ; }
    ; n = c == 0 ? -1 : i;

    mov    bl, [search_term]         ; lower byte of bx
    xor    ecx, ecx
    lea    r11, [search_string]
    mov    al, [r11 + rcx]      ; c = data[i]
    cmp    al, 0                ; if (c != 0)
    jz    end_if                ; Jump if zero (flag is set)

do_while:
    cmp    al, bl               ; if (c == x) break
    je    found
    inc    rcx                  ;++i
    mov    al, [r11 + rcx]      ; c = data[i]
    cmp    al, 0                ; while (c != 0)
    jnz    do_while             ; continue loop

end_if:
    mov    rcx, -1              ; c == 0 if this is reached, this implements n = c == 0 ? -1 : i

found:
    mov    [n], rcx

    xor    eax, eax
    leave
    call ExitProcess
