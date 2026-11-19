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

; -- BLOQUE 3: Operaciones logicas -------------------------------------------
    MOV  al, 0B7h         ; AL = 1011 0111b
    AND  al, [mascara]    ; AL = B7h AND 0Fh = 07h (conserva los 4 bits bajos)
    MOV  al, 0B7h         ; restaurar AL
    OR   al, 0F0h         ; AL = B7h OR F0h = F7h (activa los 4 bits altos)
    MOV  al, 0AAh         ; AL = 1010 1010b
    XOR  al, 0FFh         ; AL = 55h (inversion de todos los bits)
    XOR  bx, bx           ; BX = 0 (2 bytes frente a los 3 de MOV bx, 0)
    MOV  al, 0B7h
    TEST al, 01h          ; ZF = 0 porque el bit 0 vale 1; AL no cambia
    MOV  al, 08h          ; AL = 8
    SHL  al, 2            ; AL = 8 << 2 = 20h
    SHR  al, 1            ; AL = 20h >> 1 = 10h

; -- BLOQUE 4: Control de flujo ----------------------------------------------
    MOV  ax, [valor_a]    ; AX = 45
    CMP  ax, [valor_b]    ; 45 - 12 = 33 > 0
    JG   .mayor           ; salta si AX > valor_b (con signo)
    JE   .igual           ; salta si AX == valor_b
    XOR  cx, cx           ; caso menor: CX = 0 (no se alcanza con estos datos)
    JMP  .fin_cmp
.mayor:
    MOV  cx, 1            ; CX = 1: valor_a > valor_b
    JMP  .fin_cmp
.igual:
    MOV  cx, 2            ; CX = 2: igualdad
.fin_cmp:
    ; Bucle: suma acumulada de 1 a 5 (resultado esperado: 15)
    XOR  ax, ax           ; AX = 0 (acumulador)
    MOV  cx, 5            ; CX = contador del bucle
    MOV  bx, 1            ; BX = primer valor a sumar
.bucle_suma:
    ADD  ax, bx           ; AX += BX
    INC  bx               ; siguiente valor
    LOOP .bucle_suma      ; CX = CX - 1; repite si CX != 0
    ; Al terminar: AX = 1 + 2 + 3 + 4 + 5 = 15 (000Fh)

    ; Variante: factorial de 5 con MUL (resultado esperado: 120)
    MOV  ax, 1            ; AX = 1 (acumulador del producto)
    MOV  cx, 5            ; CX = 5 iteraciones
    MOV  bx, 1            ; BX = primer factor
.bucle_fact:
    MUL  bx               ; DX:AX = AX * BX
    INC  bx               ; siguiente factor
    LOOP .bucle_fact
    ; Al terminar: AX = 1 * 2 * 3 * 4 * 5 = 120 (0078h), DX = 0

; -- BLOQUE 5: Rotacion, ROL/ROR frente a SHL/SHR ----------------------------
    MOV  al, 81h          ; AL = 1000 0001b: bits 7 y 0 en 1
    MOV  bl, al
    SHL  bl, 1            ; BL = 02h; CF = 1 (el bit 7 se pierde del registro)
    MOV  cl, al
    ROL  cl, 1            ; CL = 03h; CF = 1 (el bit 7 reaparece como bit 0)
    MOV  dl, al
    SHR  dl, 1            ; DL = 40h; CF = 1 (el bit 0 se pierde del registro)
    MOV  bh, al
    ROR  bh, 1            ; BH = C0h; CF = 1 (el bit 0 reaparece como bit 7)
    MOV  al, 0A5h         ; AL = 1010 0101b
    ROL  al, 4            ; AL = 5Ah: nibbles intercambiados

    INT  20h              ; retornar a DOS
