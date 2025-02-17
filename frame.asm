.model tiny
.code
.186
org 100h

Start:
    mov si, offset FrameStyleTable
    call ParseCmdLine
    xor di, di ; di = 0h <=> relative address of top left corner
    push es
    pop ss ; ss - PSP segment
    call DrawFrame

    mov ax, 4c00h
    int 21h


;------------------------------------------------
; Draw line in video mem
; Entry: ah - color attr
;        ds:si - address of 3 byte ASCII segment to draw
;        cx - length
;        es:di - line beginning attr
; Destr: None
;------------------------------------------------
DrawLine proc
    push ax
    push cx
    push di
    push si

    cld   ; df = 0
    lodsb ; load byte from ds:si in al and inc si
    stosw ; mov ax in es:di and di += 2

    lodsb ; load byte from ds:si in al and inc si
    rep stosw ; mov ax in es:di and di += 2 cx times

    lodsb ; load byte from ds:si in al and inc si
    stosw ; mov ax in es:di and di += 2

    pop si
    pop di
    pop cx
    pop ax
    ret
DrawLine endp
;------------------------------------------------

;------------------------------------------------
; draw symbols
; Entry: ah - color attr
;        bl - length
;        si - address of symbol
;        es - address of segment
;        di - position
; Exit: di - new position
; Destr: None
;------------------------------------------------
DrawSymbol proc
    push ax
    push bx

    cmp bl, 0h
    je go_out

again:
    mov al, [si]
    stosw
    dec bl
    cmp bl, 0h
    jne again

go_out:
    pop bx
    pop ax
    ret
DrawSymbol endp
;------------------------------------------------
;------------------------------------------------
; Draw message
; Entry: ah - color attr
;        ch - length
;        ss:bp - begin of message
;        es - seg
;        di - position
; Exit: di - new position
; Destr: None
;------------------------------------------------
DrawMessage proc
    push ax
    push cx
    push si

    cmp ch, 0h
    je return

one_more:
    mov al, ss:[bp]
    inc bp
    mov es:[di], ax
    add di, 2h
    dec ch
    cmp ch, 0h
    jne one_more

return:
    pop si
    pop cx
    pop ax
    ret
DrawMessage endp
;------------------------------------------------
; Draw line with message
; Entry: ah - color attr
;        es:di - address from
;        si - address of symbols
;        ss:bp - address of message
;        cl - length of line
; Exit: None
; Destr: None
;------------------------------------------------
DrawMessageLine proc
    push cx
    push ax
    push dx
    push si
    push di
    push bx

    cld ; df = 0
    lodsb ; load byte from ds:si in al and inc si
    stosw ; mov ax in es:di and di += 2

    call GetMessageLength ; exit: ch = message length

    push ax ; save color attr
    mov ah, 0h
    mov al, cl ; ax = length of line
    sub al, ch ; ax = length of line - message length
    mov dh, 2h
    div dh ; al = ax / 2 (for centering)
    mov bl, al ; bl = al
    pop ax ; return color attr

    call DrawSymbol ; exit: di = new position

    call DrawMessage

    sub cl, bl ; cl = length of line - number spaces before message
    sub cl, ch ; cl = number spaces after message
    mov bl, cl
    call DrawSymbol

    lea si, 1[si] ; si = address of border symbol
    mov al, [si]
    mov es:[di], ax ; draw border symbol (with color)

    pop bx
    pop di
    pop si
    pop dx
    pop ax
    pop cx
    ret
DrawMessageLine endp
;------------------------------------------------

;------------------------------------------------
; Count length of message (ending with '$')
; Entry: bp - address of message
; Exit:  ch - length
; Destr: None
;------------------------------------------------
GetMessageLength proc
    push bp

    mov ch, 0
next_char:
    cmp byte ptr [bp], '$'
    je quit
    inc bp
    inc ch
    jmp next_char

quit:
    pop bp
    ret
GetMessageLength endp

;------------------------------------------------
; Draw frame
; Entry: ah - color attr (пока не работает)
;        di - address from (relative)
;        ds:si - address of symbols
;        ss:bp - address of message
;        cx - width
;        dx - height
;
; Exit: None
;------------------------------------------------
DrawFrame proc
    push di
    push si
    push cx
    push dx
    push ax

    push bp
    mov bp, 0b800h
    mov es, bp
    call DrawLine
    pop bp

    push ax
    mov ax, dx ; ax - height

    mov bl, 2h
    div bl
    inc al ; al = height / 2 + 1 (for centering)

    mov bl, al ; bl = al
    pop ax ; ah - color attr

    lea si, 3[si] ; si = address of 3 middle symbols
next_symbol:
    add di, 0a0h ; di = address of next line
    cmp dx, bx
    je draw_message

    call DrawLine
    jmp not_message

draw_message:
    call DrawMessageLine ; draw message in center

not_message:
    dec dx
    cmp dx, 0h
    jne next_symbol

    lea si, 3[si] ; si = address of 3 last symbols
    add di, 0a0h ; di = address of next line
    call DrawLine

    pop ax
    pop dx
    pop cx
    pop si
    pop di
    ret
DrawFrame endp
;------------------------------------------------

;------------------------------------------------
; Skip space
; Entry: es:di - begin of buffer
; Exit: di - new position
; Destr: None
;------------------------------------------------
SkipSpace proc
    push cx
    push ax

    mov al, ' ' ; al = ASCII code of space

    xor cx, cx
    dec cx ; cx = 0ffffh

    repe scasb ; while (cx-- && al == es:[di++])
    dec di ; es:di - address after last space

    pop ax
    pop cx
    ret
SkipSpace endp
;------------------------------------------------

;------------------------------------------------
; atoi
; Entry: es:di - address of buffer
; Exit: ax - number
;       di - new position
; Destr: None
;------------------------------------------------
Atoi proc
    push bx
    push cx
    push dx

    mov dl, 0ah ; multiple coeff
    xor ax, ax ; ax = 0
    xor bx, bx ; bx = 0
    xor cx, cx ; cx = 0
    call SkipSpace

next_digit_dec:
    mov al, es:[di] ; al - next symbol
    cmp al, '0'
    jb calculate_dec ; if not digit
    cmp al, '9'
    ja calculate_dec ; if not digit

    inc di
    sub al, 30h ; al = digit value
    push ax ; store digit
    inc bl  ; bl = updated number of digits
    jmp next_digit_dec

calculate_dec:
    cmp bl, bh ; bh - digit number (from right to left)
    ja counting_dec ; bh - digit number < bl - number of digits
    jmp exit_dec

    counting_dec:
        pop ax ; pop next digit
        push bx ; store bh
        cmp bh, 0h
        ja mult_dec
        jmp update_number_dec

        mult_dec:
            mul dl ; dl - multiplier
            ; result in ax, but think that number < 255
            dec bh
            cmp bh, 0h
            ja mult_dec

    update_number_dec:
        pop bx
        inc bh ; bh - next digit number
        add cl, al ; cl - counter
        cmp bl, bh
        ja counting_dec

exit_dec:
    mov al, cl ; return value

    pop dx
    pop cx
    pop bx
    ret
Atoi endp
;------------------------------------------------

;------------------------------------------------
; atohex
; Entry: es:di - address of buffer
; Exit: al - number
;       di - new position
; Destr:
;------------------------------------------------
Atohex proc
    push bx
    push cx

    xor ax, ax ; ax = 0
    xor bx, bx ; bx = 0
    xor cx, cx ; cx = 0
    call SkipSpace

next_digit_hex:
    mov al, es:[di] ; al - next symbol
    cmp al, '0'
    jb check_hex ; if not digit
    cmp al, '9'
    ja check_hex ; if not digit

    jmp is_decimal_digit

check_hex:
    cmp al, 'a'
    jb calculate_hex ; byte is not hex
    cmp al, 'f'
    ja calculate_hex ; byte is not hex

    sub al, 'a' - 0ah ; al = hex symbol value
    jmp is_number

is_decimal_digit:
    sub al, 30h ; al = digit value

is_number:
    inc di ; es:di - address of next symbol
    push ax ; store digit
    inc bl  ; bl = updated number of digits
    jmp next_digit_hex

calculate_hex:

    cmp bl, bh ; bh - digit number
    ja counting_hex ; bh - digit number < bl - number of digits
    jmp exit_hex

    counting_hex:
        pop ax ; pop next digit
        push bx ; store bh
        cmp bh, 0h
        ja mult_hex
        jmp update_number_hex

        mult_hex:
            shl al, 4 ; al *= 16
            dec bh
            cmp bh, 0h
            ja mult_hex

    update_number_hex:
        pop bx
        inc bh ; bh - next digit number
        add cl, al ; cl - counter
        cmp bl, bh
        ja counting_hex

exit_hex:
    mov al, cl ; return value

    pop cx
    pop bx
    ret
Atohex endp
;------------------------------------------------

;------------------------------------------------
; Parse command line
; Entry: si - address of FrameStyleTable
; Exit: cx - width
;       dx - height
;       ah - color
;       es:bp - address of message
;       ds:si - address of frame style
; Destr: None
;------------------------------------------------
ParseCmdLine proc
    push bx
    push di

    mov ah, 51h
    int 21h ; getting address of PSP segment in bx
    mov es, bx ; es - PSP segment address

    xor ax, ax ; ax = 0
    mov di, 81h ; address of command line

    call Atoi ; get width
    mov cx, ax ; width in cx

    call Atoi ; get height
    mov dx, ax ; height in dx

    call Atohex ; get color
    mov bh, al ; save color attr in bh

    call Atoi ; get style number

    call SkipSpace ; es:di - address of
                   ; frame style (if style = 0) or message

    cmp al, 0h ; al = style number
    je parse_style
    jmp count_style_address

parse_style:
    mov si, di ; si - address of symbols
    add di, 9h ; di - address after style symbols (... )
               ;                                di -> ^
    call SkipSpace
    jmp parse_message


count_style_address:
    mov ah, 0h ; ax - style number
    dec al ; ax - style number -= 1
    mov bl, 9h
    mul bl ; ax - style offset
    add ax, si ; ax - address of FrameStyle
    mov si, ax ; si - address of style symbols

parse_message:
    mov bp, di ; bp - message address
    mov ah, bh ; ah - color attr

    pop di
    pop bx
    ret
ParseCmdLine endp
;------------------------------------------------

FrameStyleTable: db 0dah, 0c4h, 0bfh, 0b3h, ' ',  0b3h, 0c0h, 0c4h, 0d9h ; 1 style
                 db 0c9h, 0cdh, 0bbh, 0bah, ' ',  0bah, 0c8h, 0cdh, 0bch ; 2 style
                 db 03h,  03h,  03h,  03h,  2eh,  03h,  03h,  03h,  03h  ; 3 style
                 db 0feh, 0feh, 0feh, 0feh, 2eh,  0feh, 0feh, 0feh, 0feh ; 4 style
                 db 0fh,  0fh,  0fh,  2ah,  2eh,  2ah,  0fh,  0fh,  0fh  ; 5 style
                 db 6h,   6h,   6h,   6h,   ' ',  6h,   6h,   6h,   6h   ; 6 style
                 db 2eh,  2eh,  2eh,  2eh,  9h,   2eh,  2eh,  2eh,  2eh  ; 7 style
                 db 5h,   4h,   5h,   4h,   0f9h, 4h,   5h,   4h,   5h   ; 8 style
end Start
