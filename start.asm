; building and running:
; nasm -f elf64 start.asm && ld -o start start.o && ./start

section .rodata
msg_nl: db 10                ; '\n' character
msg_startargv: db "argv:", 0 ; string to print before dumping argv
msg_startenvp: db "envp:", 0 ; string to print before dumping envp

section .data
argc:   dq 0     ; argc as initially placed on the stack
argc_check: dq 0 ; argc we count ourselves while stepping through the NULL-
                 ; terminated argv array.  Assert argc == argc_check
argv:   dq 0     ; Will store a pointer to argv on the stack
envc:   dq 0     ; Will hold the size of the envp array
envp:   dq 0     ; Will store a pointer to envp on the stack

section .text

; function to cleanly exit
; rdi: exitvalue
_exit:
    mov rax, 60
    syscall
    hlt  ; unreachable

; function to print a newline
; no parameters
_printnl:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_nl
    mov rdx, 1
    syscall
    ret

; function to print one character
; rsi: ptr to buf
_print1:
    mov rax, 1 ; NR_WRITE
    mov rdi, 1 ; STDOUT
    mov rdx, 1 ; count
    syscall
    ret

; function to print a string
; rsi: ptr to NULL-terminated string to print
; destroys r15
_puts:
    mov r15, rsi ; preserve rsi across syscall
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
; entry point
_start:
    mov rbp, rsp
    pop r12                 ; argc
    mov [argc_check], r12   ; argc_check is now populated with its final value
    mov r12, rsp            ; argv
    mov [argv], r12         ; final value
    mov rsi, msg_startargv  ; _puts("argv:")
    call _puts              ; ...
 _argv_loop:
    cmp qword [r12], 0      ; terminating NULL of argv reached?
    je _argv_loop_end
    mov rsi, [r12]          ; _puts(argv[i])
    call _puts              ; ...
    add qword [argc], 1
    add r12, 8
    jmp _argv_loop
 _argv_loop_end:
    mov rdi, [argc_check]  ; assert argc == argc_check
    cmp rdi, [argc]        ; ...
    jne _exit              ; exit code should show error in case assertion failed

    add r12, 8             ; jump over NULL terminating argv
    mov [envp], r12        ; final value
    mov rsi, msg_startenvp ; _puts("envp:")
    call _puts             ; ...
 _envp_loop:
    cmp qword [r12], 0     ; terminating NULL of envp reached?
    je _envp_loop_end
    mov rsi, [r12]         ; _puts(envp[i])
    call _puts             ; ...
    add qword [envc], 1    ; increment env count
    add r12, 8
    jmp _envp_loop
 _envp_loop_end:
    xor rdi, rdi           ; _exit(0)
    jmp _exit              ; ...
    hlt                    ; unreachable
