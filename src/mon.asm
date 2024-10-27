;
;   LMON, A simple 8086 16 bit legacy bios monitor (mon.asm)
;   Copyright (C) 2024 Lilly H. St Claire
;            This program is free software: you can redistribute it and/or modify
;            it under the terms of the GNU General Public License as published by
;            the Free Software Foundation, either version 3 of the License, or (at
;            your option) any later version.
;            This program is distributed in the hope that it will be useful, but
;            WITHOUT ANY WARRANTY; without even the implied warranty of
;            MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;            General Public License for more details.
;            You should have received a copy of the GNU General Public License
;            along with this program.  If not, see <https://www.gnu.org/licenses/>.

use16
org 0x7C00
macro print desc,num {
        display desc
        value=num
        pos=1000
        repeat 4
                digit = value/pos
                value = value-(digit*pos)
                pos = pos/10
                display ('0' + digit)
        end repeat
        display $d,$a
}
jmp _MON_START
MON_CUR_DRIVE:          db 0x00
MON_FAR_JUMP_LOC:       dd 0x00
MON_ERRNO:              db 0x00
MON_INVALID_INPUT_MSG:  db 0xA, 0xD, "Error: invalid input.", 0xA, 0xD, 0x0
MON_JUMP_ADDR:          dd 0x00
_MON_PRINT_STR: ; si = string
        push si
        push ax
        mov ah, 0x0E
.loop:
        mov al, [si]
        cmp al, 0x00
        je .eloop
        inc si
        int 0x10
        jmp .loop
.eloop:
        pop ax
        pop si
        ret
_MON_PRINT_NL:
        push ax
        mov ax, 0x0E0A
        int 0x10
        mov ax, 0x0E0D
        int 0x10
        pop ax
        ret
_MON_PRINT_HEX: ; cx = hexadecimal value
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
_MON_CHECK_HEX_DIG: ; al = char, ah = 0 on succ, ah = 1 on fail
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
_MON_GET_HEX_BYTE: ; ret = al
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
        call _MON_CHECK_HEX_DIG
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
        mov byte [MON_ERRNO], 0x01
        pop cx
        ret
_MON_MEM_READ: ; bx = Address
        push bx
        mov ax, 0x1000
        mov ds, ax
        mov al, [bx]
        xor bx, bx
        mov ds, bx
        pop bx
        ret
_MON_MEM_WRITE: ; al = value, bx = Address
        push bx
        push ax
        mov ax, 0x1000
        mov ds, ax
        pop ax
        mov [bx], al
        xor bx, bx
        mov ds, bx
        pop bx
        ret
_MON_START:
        mov byte [MON_CUR_DRIVE], dl
        xor ah, ah
        mov al, 0x02
        int 0x10

        mov ah, 0x02
        mov al, 0x7F
        mov cx, 0x0002
        mov dh, 0x00
        mov bx, 0x1000
        mov es, bx
        xor bx, bx
        int 0x13

.cmd_loop:
        mov ah, 0x0E
        mov al, "]"
        int 0x10
        mov al, 0x20
        int 0x10
        xor ah, ah
        int 0x16
        mov ah, 0x0E
        int 0x10
.peek:
        cmp al, '.'
        jne .poke
        call .get_word
        call _MON_PRINT_NL
        mov cx, bx
        call _MON_PRINT_HEX
        call _MON_PRINT_NL
        call _MON_MEM_READ
        xor ah, ah
        mov cx, ax
        call _MON_PRINT_HEX
        call _MON_PRINT_NL
        jmp .continue
.poke:
        cmp al, ','
        jne .call
        call .get_word
        mov ax, 0x0E20
        int 0x10
        call .get_byte
        call _MON_MEM_WRITE
        call _MON_PRINT_NL
        jmp .continue
.call:
        cmp al, '$'
        jne .save
        call .get_word
        call _MON_PRINT_NL
        mov ax, 0x1000
        mov ds, ax
        mov word [MON_JUMP_ADDR+2], 0x1000
        mov word [MON_JUMP_ADDR  ], bx
        call far [MON_JUMP_ADDR]
        xor ax, ax
        mov ds, ax
        jmp .continue
.save:
        cmp al, '%'
        push 0x00
        je .save.cont
        call .invalid_input
        jmp .continue
.save.cont:
        mov si, 0x00
        .save_loop:
        cmp si, 0x03
        je .esave_loop
        mov ah, 0x03
        mov al, 0x7F
        mov cx, 0x0002
        mov dh, 0x00
        mov dl, [MON_CUR_DRIVE]
        mov bx, 0x1000
        mov es, bx
        xor bx, bx
        int 0x13
        mov ah, 0x02
        mov al, 0x7F
        mov cx, 0x0002
        mov dh, 0x00
        mov dl, [MON_CUR_DRIVE]
        mov bx, 0x1000
        mov es, bx
        xor bx, bx
        int 0x13
        inc si
        .esave_loop:
        call _MON_PRINT_NL
        jmp .continue
.get_byte:
        call _MON_GET_HEX_BYTE
        cmp byte [MON_ERRNO], 0x00
        jne .invalid_input
        ret
.get_word:
        mov dx, 0x00
        call .get_byte
        mov bh, al
        or dx, dx
        jz .get_word.cont1
        pop bx
        jmp .continue
.get_word.cont1:
        call .get_byte
        mov bl, al
        or dx, dx
        jz .get_word.cont2
        pop bx
        jmp .continue
.get_word.cont2:
        ret
.invalid_input:
        mov byte [MON_ERRNO], 0x00
        mov si, MON_INVALID_INPUT_MSG
        call _MON_PRINT_STR
        mov dx, 0x01
        ret
.continue:
        jmp .cmd_loop

print "size: ", $-$$
print "remaining: ", 0x1FE-($-$$)
times 0x1FE-($-$$) db 0x00
dw 0xAA55
include "writer.asm"
times 0x1000-($-$$) db 0x00
