; lab6_modos.asm - Demostracion de modos de direccionamiento x86
; Compilar: nasm -f bin lab6_modos.asm -o lab6_modos.com
org  100h

; -- Datos de prueba --------------------------------------------------------
jmp  inicio
array     dw  10, 20, 30, 40, 50    ; arreglo de 5 enteros de 16 bits
nota1     dw  85                    ; registro de estudiante: nota1, nota2, promedio
nota2     dw  73
promedio  dw  0
var_x     dw  0FFFFh                ; variable simple para el modo directo
tabla_hex db  30h,31h,32h,33h,34h,35h,36h,37h
          db  38h,39h,41h,42h,43h,44h,45h,46h

inicio:
; -- MODO 1: INMEDIATO: el operando viaja dentro de la instruccion -----------
    MOV  ax, 100          ; AX = 100 (0064h)
    MOV  bx, 0A5h         ; BX = 00A5h
    ADD  cx, 55           ; CX += 55
    AND  dx, 00FFh        ; DX AND mascara inmediata

; -- MODO 2: DIRECTO: la direccion fija viaja dentro de la instruccion -------
    MOV  ax, [var_x]      ; AX = mem[var_x] = FFFFh
    MOV  bx, [array]      ; BX = mem[array] = 10
    MOV  cx, [nota1]      ; CX = mem[nota1] = 85
    MOV  word [var_x], 0  ; mem[var_x] = 0

; -- MODO 3: INDIRECTO POR REGISTRO: el registro contiene la direccion ------
    MOV  si, nota1        ; SI = direccion de nota1
    MOV  ax, [si]         ; AX = mem[SI] = 85 (0055h)
    MOV  si, nota2        ; SI = direccion de nota2
    MOV  bx, [si]         ; BX = mem[SI] = 73 (0049h)
    ADD  ax, bx           ; AX = 158
    SHR  ax, 1            ; AX = 79 (004Fh)
    MOV  si, promedio     ; SI = direccion de promedio
    MOV  [si], ax         ; mem[SI] = 79

; -- MODO 4: INDEXADO: base + indice + desplazamiento ------------------------
    MOV  bx, array        ; BX = base del arreglo
    MOV  si, 4            ; SI = 2 * 2 bytes
    MOV  ax, [bx + si]    ; AX = array[2] = 30
    XOR  ax, ax           ; acumulador
    MOV  bx, array
    MOV  cx, 5
    XOR  si, si
.bucle_array:
    ADD  ax, [bx + si]    ; AX += array[SI / 2]
    ADD  si, 2            ; avanzar una palabra
    LOOP .bucle_array
    ; AX = 10 + 20 + 30 + 40 + 50 = 150 (0096h)

    ; Extension: recorrido inverso desde array[4] hasta array[0]
    XOR  ax, ax
    MOV  bx, array
    MOV  cx, 5
    MOV  si, 8            ; SI = 4 * 2 bytes: ultimo elemento
.bucle_inverso:
    ADD  ax, [bx + si]
    SUB  si, 2            ; retroceder una palabra
    LOOP .bucle_inverso
    ; AX = 50 + 40 + 30 + 20 + 10 = 150 (0096h)

    ; Campos del registro con desplazamiento fijo desde la base
    MOV  bx, nota1
    MOV  ax, [bx]         ; AX = nota1 = 85
    MOV  cx, [bx + 2]     ; CX = nota2 = 73
    MOV  dx, [bx + 4]     ; DX = promedio = 79

    INT  20h              ; retornar a DOS
