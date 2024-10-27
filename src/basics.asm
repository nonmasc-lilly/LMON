MON_USER_API_ERRNO: db 0x00

_MON_USER_API_PRINT_STR: ; si = string
        push ax
        push si
        mov ah, 0x0E
.loop:
        mov al, [si]
        or al, al
        jz .eloop
        int 0x10
        inc si
        jmp .loop
.eloop:
        pop si
        pop ax
        ret

_MON_USER_API_PRINT_NL:
        push ax
        mov ax, 0x0E0A
        int 0x10
        mov ax, 0x0E0D
        int 0x10
        pop ax
        ret

_MON_USER_API_PRINT_HEX: ; cx = hexadecimal value
        push ax
        push cx
        push bx
        mov ah, 0x0E
        xor bx, bx
.loop:
        cmp bx, 4
        je .eloop
        mov al, ch
        shr al, 0x04
        cmp al, 0x09
        jg .hex
        or al, 0x30
        int 0x10
        jmp .continue
.hex:
        sub al, 0x09
        add al, 0x40
        int 0x10
.continue:
        shl cx, 0x04
        inc bx
        jmp .loop
.eloop:
        pop bx
        pop cx
        pop ax
        ret

_MON_USER_API_CHECK_HEX_DIG: ; al = char, ah = 0 on succ, ah = 1 on fail
        cmp al, 0x30
        jl .invalid
        cmp al, 0x39
        jg .hex
        jmp .valid
.hex:
        cmp al, 0x41
        jl .invalid
        cmp al, 0x46
        jg .invalid
.valid:
        xor ah, ah
        ret
.invalid:
        mov ah, 0x01
        ret
_MON_USER_API_GET_HEX_BYTE: ; ret = al
        push cx
        xor cl, cl
        xor ch, ch
.loop:
        cmp ch, 0x01
        jg .eloop
        xor ah, ah
        int 0x16
        push ax
        mov ah, 0x0E
        int 0x10
        pop ax
        call _MON_USER_API_CHECK_HEX_DIG
        cmp ah, 0x00
        jne .err
        sub al, 0x30
        cmp al, 0x11
        jl .nhex
        sub al, 0x07
.nhex:
        shl cl, 0x04
        or cl, al
        inc ch
        jmp .loop
.eloop:
        mov al, cl
        pop cx
        ret
.err:
        mov byte [MON_USER_API_ERRNO], 0x01
        pop cx
        ret
