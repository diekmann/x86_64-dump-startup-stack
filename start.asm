; nasm -f elf64 start.asm && ld -o start start.o && ./start
section .rodata
msg_nl: db 10
msg_startargv: db "argv:", 0
msg_startenvp: db "envp:", 0

section .data
argc:   dq 0
argc_check: dq 0
argv:   dq 0
envc:   dq 0
envp:   dq 0

section .text

; rdi: exitvalue
_exit:
    mov rax, 60
    syscall

; print newline
_printnl:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_nl
    mov rdx, 1
    syscall
    ret

; rsi: ptr to buf
_print1:
    mov rax, 1 ; NR_WRITE
    mov rdi, 1 ; STDOUT
    mov rdx, 1 ; count
    syscall
    ret

; rsi: ptr to NULL-terminated string to print
; destroys r15
_puts:
    mov r15, rsi ; preserve rsi accross syscall
    cmp [r15], byte 0
    je _puts_loop_end
    call _print1
    mov rsi, r15
    inc rsi
    jmp _puts
 _puts_loop_end:
    call _printnl
    ret   

global _start
_start:
    mov rbp, rsp
    pop r12 ; argc
    mov [argc_check], r12
    mov r12, rsp ; argv
    mov [argv], r12
    mov rsi, msg_startargv
    call _puts
 _argv_loop:
    cmp qword [r12], 0
    je _argv_loop_end
    mov rsi, [r12]
    call _puts
    add qword [argc], 1
    add r12, 8
    jmp _argv_loop   
 _argv_loop_end:
    mov rdi, [argc_check]
    cmp rdi, [argc]
    jne _exit ; exit code should show error

    add r12, 8 ; jump over NULL terinating argv
    mov [envp], r12
    mov rsi, msg_startenvp
    call _puts
 _envp_loop:
    cmp qword [r12], 0
    je _envp_loop_end
    mov rsi, [r12]
    call _puts
    add qword [envc], 1
    add r12, 8
    jmp _envp_loop
 _envp_loop_end:
    xor rdi, rdi
    jmp _exit

