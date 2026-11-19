; lab6_instrucciones.asm - Demostracion de categorias de instrucciones x86
; Compilar: nasm -f bin lab6_instrucciones.asm -o lab6_instrucciones.com
org  100h               ; offset de inicio para archivos .COM

; -- Datos ------------------------------------------------------------------
jmp  inicio             ; saltar sobre los datos al codigo
valor_a   dw  45        ; primer operando
valor_b   dw  12        ; segundo operando
resultado dw  0         ; almacena el resultado de la suma
contador  db  5         ; contador de bucle
mascara   db  0Fh       ; mascara de los 4 bits bajos

; -- Codigo -----------------------------------------------------------------
inicio:
; -- BLOQUE 1: Transferencia de datos ----------------------------------------
    MOV  ax, [valor_a]    ; AX = 45 (contenido de valor_a)
    MOV  bx, [valor_b]    ; BX = 12 (contenido de valor_b)
    MOV  cx, ax           ; CX = AX = 45
    MOV  dx, bx           ; DX = BX = 12
    LEA  si, [valor_a]    ; SI = direccion de valor_a (no su valor)
    MOV  ax, [si]         ; AX = mem[SI] = 45 (indirecto via SI)
    XCHG cx, dx           ; CX = 12, DX = 45
    XCHG cx, dx           ; restaurar: CX = 45, DX = 12
    PUSH ax               ; guarda AX = 45 en la pila
    MOV  ax, 0FFFFh       ; modifica AX temporalmente
    POP  ax               ; restaura AX = 45

; -- BLOQUE 2: Operaciones aritmeticas ---------------------------------------
    MOV  ax, [valor_a]    ; AX = 45
    ADD  ax, [valor_b]    ; AX = 45 + 12 = 57 (0039h); ZF=0, CF=0, OF=0
    MOV  [resultado], ax  ; guarda 57 en memoria
    MOV  ax, [valor_b]    ; AX = 12
    SUB  ax, [valor_a]    ; AX = 12 - 45 = -33 (FFDFh); SF=1, CF=1 (prestamo), OF=0
    MOV  ax, [valor_a]    ; AX = 45
    INC  ax               ; AX = 46 (INC y DEC no modifican CF)
    DEC  ax               ; AX = 45
    MOV  al, 10           ; AL = 10
    MOV  bl, 7            ; BL = 7
    MUL  bl               ; AX = AL * BL = 70 (0046h); con operando de 8 bits el producto queda en AX
    MOV  ax, 100          ; AX = 100
    MOV  bl, 7            ; BL = 7
    DIV  bl               ; AL = 14 (cociente), AH = 2 (resto): 100 = 7 * 14 + 2

    INT  20h              ; retornar a DOS
