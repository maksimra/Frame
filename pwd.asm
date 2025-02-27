.model tiny
.code
locals @@
.186
org 100h

TerminateFuncCode     equ 4c00h
DOSServices           equ 21h

Start:
    push ds
    pop es
    mov di, offset PromptMsg
    call PutS

    mov di, offset UserPassword
    call GetS

    call PutS

    mov di, offset CrLfMsg
    call PutS

    mov di, offset AdminPassword
    call GetMessageLength
    xor ch, ch ; cl -> cx - length

    mov si, offset UserPassword
    cld
    repe cmpsb ; [ds:si] = [es:di]? ; si++, di++
    jmp @@check

@@check:
    je @@print_ok
    mov di, offset FailedPwdMsg
    jmp @@out

@@print_ok:
    mov di, offset SuccessPwdMsg

@@out:
    call PutS
    mov ax, TerminateFuncCode
    int DOSServices

;------------------------------------------------
; Put String
; Entry: es:di - string address
; Exit: None
; Destr: None
;------------------------------------------------
PutS proc
    push di

    DOSServices             equ 21h
    PutCharInStandartOutput equ 02h

    mov ah, PutCharInStandartOutput

@@next_char:
    mov dl, es:[di]
    cmp dl, '$'
    je @@out
    int DOSServices ; print es:dx in standart output
    inc di
    jmp @@next_char

@@out:
    pop di
    ret
PutS endp
;------------------------------------------------

;------------------------------------------------
; Get String
; Entry: es:di - address for save string
; Exit: None
; Destr: None
;------------------------------------------------
GetS proc
    push ax
    push di

    CarriageReturnCode       equ 0dh
    DOSServices              equ 21h
    GetCharFromStandartInput equ 07h
    mov ah, GetCharFromStandartInput

    cld
@@next_char:
    int DOSServices
    cmp al, CarriageReturnCode
    je @@out
    stosb ; mov al in es:di and di++
    jmp @@next_char

@@out:
    mov byte ptr es:[di], '$'
    pop di
    pop ax
    ret
GetS endp
;------------------------------------------------

;------------------------------------------------
; Count length of message (ending with '$')
; Entry: es:di - address of message
; Exit:  cl - length
; Destr: None
;------------------------------------------------
GetMessageLength proc
    push di

    xor cl, cl
@@next:
    cmp byte ptr es:[di], '$'
    je @@out
    inc di
    inc cl
    jmp @@next

@@out:
    pop di
    ret
GetMessageLength endp
;------------------------------------------------


PromptMsg:     db 'Enter the password: $'
UserPassword:  db 10 dup ('$')
CrLfMsg:       db 0dh, 0ah, '$'
AdminPassword: db 'Don$'
FailedPwdMsg:  db 'Password is not correct.$'
SuccessPwdMsg: db 'Welcome!$'

end Start
