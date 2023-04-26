[bits 16]          ; Set the code to 16-bit mode
[org 0x8000]       ; Set the origin of the code to 0x8000, where the bootloader loaded the program

VIDEO_INT     equ 0x10    ; BIOS video interrupt
VIDEO_PRINT   equ 0x0E    ; Print character function of BIOS video interrupt
MSG           db 'Enter an expression (e.g. 2+3): ', 0 ; Message to prompt the user for input

operator      db 0        ; Variable to store the operator (+, -, *, or /)
result        dw 0        ; Variable to store the result of the expression

start:
    ; Prompt the user for input
    mov ah, VIDEO_PRINT ; Set AH register to print character
    mov si, MSG         ; Load message address into SI register
    print:
        lodsb           ; Load character from SI to AL and increment SI
        cmp al, 0       ; Check if end of message has been reached
        je get_input    ; If end of message, prompt the user for input
        int VIDEO_INT   ; Call BIOS video interrupt to print character
        jmp print       ; Repeat for next character

get_input:
    ; Get input from the user
    mov ah, 0x00    ; Set AH register to read character
    int VIDEO_INT   ; Call BIOS video interrupt to get character
    cmp al, 0x0D    ; Check if Enter key was pressed
    je evaluate     ; If Enter key, evaluate the expression
    cmp al, '+'     ; Check if the input is an addition operator
    je add_op       ; If addition operator, store it and get the next input
    cmp al, '-'     ; Check if the input is a subtraction operator
    je sub_op       ; If subtraction operator, store it and get the next input
    cmp al, '*'     ; Check if the input is a multiplication operator
    je mul_op       ; If multiplication operator, store it and get the next input
    cmp al, '/'     ; Check if the input is a division operator
    je div_op       ; If division operator, store it and get the next input
    cmp al, '0'     ; Check if the input is a digit
    jb get_input    ; If not a digit, ignore it and get the next input
    cmp al, '9'     ; If not a digit, ignore it and get the next input
    ja get_input
    ; If it's a digit, add it to the accumulator
    sub al, '0'     ; Convert the digit from ASCII to binary
    mov bl, al      ; Move the digit to BL register
    shl ax, 1       ; Multiply accumulator by 10
    add ax, bx      ; Add the new digit to the accumulator
    jmp get_input   ; Repeat to get the next input

add_op:
    ; Store the addition operator and get the next input
    mov [operator], '+'
    jmp get_input

sub_op:
    ; Store the subtraction operator and get the next input
    mov [operator], '-'
    jmp get_input

mul_op:
    ; Store the multiplication operator and get the next input
    mov [operator], '*'
    jmp get_input

div_op:
    ; Store the division operator and get the next input
    mov [operator], '/'
    jmp get_input

evaluate:
    ; Evaluate the expression
    mov bl, [operator] ; Load the operator into BL register
    cmp bl, '+'        ; Check if the operator is addition
    je add ; If addition, add the operands
    cmp bl, '-' ; Check if the operator is subtraction
    je sub ; If subtraction, subtract the operands
    cmp bl, '*' ; Check if the operator is multiplication
    je mul ; If multiplication, multiply the operands
    cmp bl, '/' ; Check if the operator is division
    je div ; If division, divide the operands
    jmp error ; If unknown operator, display error message and restart

add:
    ; Add the operands and store the result in memory
    add ax, bx
    mov [result], ax
    jmp print_result

sub:
    ; Subtract the operands and store the result in memory
    sub ax, bx
    mov [result], ax
    jmp print_result

mul:
    ; Multiply the operands and store the result in memory
    mul bx
    mov [result], ax
    jmp print_result

div:
    ; Divide the operands and store the result in memory
    xor dx, dx ; Clear DX register
    div bx ; Divide AX by BX
    mov [result], ax
    jmp print_result

print_result:
    ; Print the result to the screen
    mov ah, VIDEO_PRINT ; Set AH register to print character
    mov al, ' ' ; Load a space into AL register
    int VIDEO_INT ; Call BIOS video interrupt to print space
    mov ax, [result] ; Load the result into AX register
    call print_number ; Call subroutine to print the result
    jmp restart ; Restart the program

print_number:
    ; Print a number to the screen
    push dx ; Save DX register
    push ax ; Save AX register
    xor cx, cx ; Set CX register to 0
    mov bx, 10 ; Set BX register to 10
convert:
    xor dx, dx ; Clear DX register
    div bx ; Divide DX:AX by BX
    push dx ; Push remainder onto the stack
    inc cx ; Increment the counter
    cmp ax, 0 ; Check if quotient is zero
    jne convert ; If not zero, repeat division
print:
    pop ax ; Pop remainder from the stack to AX register
    add al, '0' ; Convert remainder to ASCII
    int VIDEO_INT ; Call BIOS video interrupt to print character
    loop print ; Repeat for all remainders on the stack
    pop ax ; Restore AX register
    pop dx ; Restore DX register
    ret ; Return from subroutine

error:
    ; Display an error message and restart the program
    mov ah, VIDEO_PRINT ; Set AH register to print character
    mov si, err_msg ; Load error message address into SI register
print_err:
    lodsb ; Load character from SI to AL and increment SI
    cmp al, 0 ; Check if end of message has been reached
    je restart ; If end of message, restart the program
    int VIDEO_INT ; Call BIOS video interrupt to print character
    jmp print_err ; Repeat for next character

restart:
    ; Restart the program
    jmp start

err_msg db 'Error: Unknown operator', 0 ; Error message to display if unknown operator is entered
