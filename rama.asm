.model tiny
.code
org 100h

Start:
    mov si, offset FrameStyle
    mov ah, 01001110b
    mov dx, 04h
    mov di, 0h ; Address of top left corner of screen (relative)
    mov cx, 0ah
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
;        si - begin of message
;        es - seg
;        di - position
; Exit: di - new position
; Destr: None
;------------------------------------------------
DrawMessage proc
    push ax
    push si
    push dx
    push cx

    cmp ch, 0h
    je exit

one_more:
    lodsb ; load byte from ds:si in al and inc si
    stosw ; mov ax in es:di and di += 2
    dec ch
    cmp ch, 0h
    jne one_more

exit:
    pop cx
    pop dx
    pop si
    pop ax
    ret
DrawMessage endp
;------------------------------------------------
; Draw line with message
; Entry: ah - color attr
;        es:di - address from
;        si - address of symbols
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

    push di
    lea di, 5[si] ; di = address begin of message
    call GetMessageLength ; exit: ch = message length
    pop di

    push ax ; save color attr
    mov ah, 0h
    mov al, cl ; ax = length of line
    sub al, ch ; ax = length of line - message length
    mov dh, 2h
    div dh ; al = ax / 2 (for centering)
    mov bl, al ; bl = al
    pop ax ; return color attr

    call DrawSymbol ; exit: di = new position

    lea si, 5[si] ; di
    call DrawMessage

    sub cl, bl ; cl = length of line - number spaces before message
    sub cl, ch ; cl = number spaces after message
    mov bl, cl
    lea si, -5[si] ; si = address of symbol
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
; Entry: di - address of message
; Exit:  ch - length
; Destr: None
;------------------------------------------------
GetMessageLength proc
    push di

    mov ch, 0
next_char:
    cmp byte ptr [di], '$'
    je quit
    inc di
    inc ch
    jmp next_char

quit:
    pop di
    ret
GetMessageLength endp

;------------------------------------------------
; Draw frame
; Entry: ah - color attr (пока не работает)
;        di - address from (relative)
;        ds:si - address of symbols
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

    mov bp, 0b800h
    mov es, bp
    call DrawLine

    push ax
    mov ax, dx ; TODO: баг, если делать через dl (или я лох)

    mov bl, 2h
    div bl
    inc al ; al = height / 2 + 1 (for centering)

    mov bx, ax ; bx = al
    pop ax

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
; Exit: si - new position
; Destr: None
;------------------------------------------------
SkipSpace proc
    mov al, ' ' ; al = ASCII code of space

    xor cx, cx
    dec cx ; cx = 0ffffh

    repe scasb ; while (cx-- && al == ds:[si++])
    ret
SkipSpace endp
;------------------------------------------------

;------------------------------------------------
; atoi
; Entry: si - address of buffer
; Exit: al - number,
;       si - new position
; Destr:
;------------------------------------------------
Atoi proc ; TODO: неправильно, не домножаю на 10...

    mov bl, 0h
    call SkipSpace

next_digit:
    lodsb ; load byte from ds:si in al and inc si
    cmp al, '0'
    jb not_digit
    cmp al, '9'
    ja not_digit

    sub al, 30h ; al = digit
    add bl, al  ; update storage bx
    jmp next_digit

not_digit:
    mov al, bl

    ret
Atoi endp
;------------------------------------------------

;------------------------------------------------
; a to hex
; Entry: si - address of buffer
; Exit: al - number,
;       si - new position
; Destr:
;------------------------------------------------
Atohex proc

    mov bl, 0h
    call SkipSpace

next_hex_digit:
    lodsb ; load byte from ds:si in al and inc si
    cmp al, '0'
    jb not_hex_digit
    cmp al, '9'
    ja not_hex_digit

    sub al, 30h ; al = digit
    add bl, al  ; update storage bx
    jmp next_hex_digit

not_hex_digit:
    mov al, bl

    ret
Atohex endp
;------------------------------------------------

;------------------------------------------------
; Parse command line
; Entry:
; Exit:
; Destr:
;------------------------------------------------
ParseCmdLine proc
    mov ah, 51h
    int 21h ; getting address of PSP segment in bx
    mov si, bx

    mov es, ds
    mov di, offset ParseInfo

    call Atoi
    stosb ; mov al (width) in es:di and di++

    call Atoi
    stosb ; mov al (height) in es:di and di++

    call Atohex

    ret
ParseCmdLine endp
;------------------------------------------------

ParseInfo: db 40 dup(?)
FrameStyle: db 0feh, 0feh, 0feh, 0feh, 2eh, 0feh, 0feh, 0feh, 0feh ;'/-\=+=\-/'
Message: db 'HUI$'
end Start
