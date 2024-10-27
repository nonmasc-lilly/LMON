org 0x0000
jmp _WRITER_MON_START
include "basics.asm"
        ;                                                                                   !!!
WRITER_MON_WELCOME_MSG:
        db "Hello World! This is LMON WRITER, a simple writing program!", 0x0A, 0x0D
        db "  W <addr> <string> : writes <string> from address <addr> to address", 0x0A, 0x0D
        db "                      <addr+string_length> a write is ended with a CTR+C", 0x0A, 0x0D
        db "  R <addr> <length> : prints <length> characters from <addr> to the terminal", 0x0A, 0x0D
        db "  Q                 : quits the program", 0x0A, 0x0D, 0x00
WRITER_MON_INVALID_COMMAND_MSG:
        db "Error: invalid command", 0x0A, 0x0D, 0x00
WRITER_MON_EXIT_COMMAND_MSG:
        db "Goodbye World!", 0x0A, 0x0D, 0x00

_WRITER_MON_START:
        mov si, WRITER_MON_WELCOME_MSG
        call _MON_USER_API_PRINT_STR
        call _WRITER_MON_SHELL
        retf

_WRITER_MON_SHELL:
.loop:
        mov ah, 0x0E
        mov al, "$"
        int 0x10
        xor ah, ah
        int 0x16
        mov ah, 0x0E
        int 0x10
.write:
        cmp al, "W"
        jne .read
        call _WRITER_MON_SHELL_WRITE_CMD
        jmp .continue
.read:
        cmp al, "R"
        jne .quit
        call _WRITER_MON_SHELL_READ_CMD
        jmp .continue
.quit:
        cmp al, "Q"
        jne .invalid_input
        call _MON_USER_API_PRINT_NL
        jmp .eloop
.invalid_input:
        mov si, WRITER_MON_INVALID_COMMAND_MSG
        call _MON_USER_API_PRINT_STR
.continue:
        jmp .loop
.eloop:
        mov si, WRITER_MON_EXIT_COMMAND_MSG
        call _MON_USER_API_PRINT_STR
        ret

_WRITER_MON_SHELL_READ_CMD:
        mov ax, 0x0E20
        int 0x10
        call _MON_USER_API_GET_HEX_BYTE
        mov bh, al
        cmp byte [MON_USER_API_ERRNO], 0x00
        jne .invalid_input
        call _MON_USER_API_GET_HEX_BYTE
        mov bl, al
        cmp byte [MON_USER_API_ERRNO], 0x00
        jne .invalid_input
        mov ax, 0x0E20
        int 0x10
        call _MON_USER_API_GET_HEX_BYTE
        cmp byte [MON_USER_API_ERRNO], 0x00
        jne .invalid_input
        call _MON_USER_API_PRINT_NL
        mov cl, al
        mov ah, 0x0E
.loop:
        or cl, cl
        jz .eloop
        mov al, [bx]
        int 0x10
        inc bx
        dec cl
        jmp .loop
.eloop:
        call _MON_USER_API_PRINT_STR
        ret
.invalid_input:
        mov byte [MON_USER_API_ERRNO], 0x00
        mov si, WRITER_MON_INVALID_COMMAND_MSG
        call _MON_USER_API_PRINT_STR
        ret

_WRITER_MON_SHELL_WRITE_CMD:
        mov ax, 0x0E20
        int 0x10
        call _MON_USER_API_GET_HEX_BYTE
        mov bh, al
        cmp byte [MON_USER_API_ERRNO], 0x00
        jne .invalid_input
        call _MON_USER_API_GET_HEX_BYTE
        mov bl, al
        cmp byte [MON_USER_API_ERRNO], 0x00
        jne .invalid_input
        call _MON_USER_API_PRINT_NL
.loop:
        xor ah, ah
        int 0x16
        cmp al, 0x03
        je .eloop
        mov ah, 0x0E
        cmp al, 0x0A
        jne .test_0D
        mov al, 0x0D
        int 0x10
        mov al, 0x0A
        int 0x10
        jmp .test_end
.test_0D:
        cmp al, 0x0D
        jne .test_else
        mov al, 0x0D
        int 0x10
        mov al, 0x0A
        int 0x10
        jmp .test_end
.test_else:
        cmp al, 0x20
        jl .loop
        cmp al, 0x7E
        jg .loop
        int 0x10
.test_end:
        mov byte [bx], al
        inc bx
        jmp .loop
.eloop:
        call _MON_USER_API_PRINT_NL
        ret
.invalid_input:
        mov byte [MON_USER_API_ERRNO], 0x00
        mov si, WRITER_MON_INVALID_COMMAND_MSG
        call _MON_USER_API_PRINT_STR
        ret


