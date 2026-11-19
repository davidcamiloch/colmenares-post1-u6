# colmenares-post1-u6

Laboratorio del Post-contenido de la Unidad 6 (Instrucciones y Direccionamiento) de Arquitectura de Computadores, UFPS. Autor: David Camilo Colmenares Hernández.

El repositorio reúne dos programas .COM en NASM para DOSBox. `lab6_instrucciones.asm` recorre las categorías de instrucciones x86 (Parte 1) y `lab6_modos.asm` demuestra los modos de direccionamiento (Parte 2).

## Entorno

- DOSBox 0.74-3 con la carpeta del laboratorio montada como C:.
- NASM 3.02 para DOS con CWSDPMI como servidor DPMI (`cwsdpmi -p` antes de ensamblar).
- DEBUG 2.51 (clon libre de DEBUG.COM, proyecto DOS-debug de Baron-von-Riedesel), porque DOSBox 0.74 no incluye DEBUG.

```
C:\> nasm -f bin lab6_instrucciones.asm -o lab6_instrucciones.com
C:\> nasm -f bin lab6_modos.asm -o lab6_modos.com
C:\> debug lab6_instrucciones.com
```

## Estructura

```
colmenares-post1-u6/
├── lab6_instrucciones.asm / .com   Parte 1
├── lab6_modos.asm / .com           Parte 2
├── capturas/                       evidencia de DEBUG en DOSBox
└── README.md
```

## Parte 1: Categorías de instrucciones

El programa salta sobre sus datos (`valor_a` = 45 en 0102h; `valor_b` = 12 en 0104h; `resultado` en 0106h; `mascara` = 0Fh en 0109h) y ejecuta cinco bloques. Termina con `INT 20h`.

| Bloque | Instrucciones | Registros y banderas observados |
|--------|---------------|---------------------------------|
| 1. Transferencia | MOV, LEA, XCHG, PUSH/POP | SI = 0102h tras `LEA si, [valor_a]`; AX = 002Dh tras `MOV ax, [si]`; AX vuelve a 002Dh tras el POP |
| 2. Aritmética | ADD, SUB, INC, DEC, MUL, DIV | ADD: AX = 0039h (57), NV PL NZ AC PE NC. SUB: AX = FFDFh (−33), NV NG NZ AC PO CY. MUL: AX = 0046h (70). DIV: AX = 020Eh (AH = 2, AL = 14) |
| 3. Lógica | AND, OR, XOR, TEST, SHL, SHR | AND: AL = 07h, NV PL NZ PO NC. OR: AL = F7h. XOR: AL = 55h. TEST AL,01h: NZ con AL intacto en B7h. SHL/SHR: AL = 20h y luego 10h |
| 4. Control de flujo | CMP, JG, JE, JMP, LOOP | CMP 45 − 12: NV PL NZ NA PE NC; JG salta y CX = 1. Bucle: AX = 000Fh (15) al salir de LOOP |
| 5. Rotación | SHL, ROL, SHR, ROR | BL = 02h, CL = 03h, DL = 40h, BH = C0h, cada uno con CY. `ROL al, 4` sobre A5h deja AL = 5Ah |

La resta del bloque 2 activa también CF porque 12 − 45 exige préstamo; la guía solo menciona SF. El `MUL bl` de 8 bits deja todo el producto en AX y no toca DX; el comentario de la guía que habla de DX corresponde a la versión de 16 bits.

### Variante factorial

El commit "Se agregó la variante factorial del bucle" añade después de la suma un segundo bucle con AX = 1, CX = 5 y BX = 1. Cada vuelta ejecuta `MUL bx` e `INC bx`, así que el producto acumulado es 1 × 2 × 3 × 4 × 5 = 120. Al salir, AX = 0078h y DX = 0000h porque el resultado cabe en 16 bits. La suma original se conserva para que el checkpoint de AX = 15 siga siendo verificable en el mismo programa.

### Decisión técnica 1: SHL/SHR frente a ROL/ROR

SHL y SHR son las instrucciones correctas para aritmética. Desplazar un bit a la izquierda multiplica por 2 y desplazarlo a la derecha divide por 2 sin signo, como en el bloque 3 (8 → 20h → 10h); el bit que sale no forma parte del resultado numérico y basta con consultarlo en CF si hubo desbordamiento. ROL y ROR son las correctas cuando ningún bit puede perderse: el intercambio de nibbles del bloque 5, un cifrado por rotación o un checksum circular que debe ser reversible. Con AL = 81h, `SHL al, 1` saca el bit 7 del registro; el resultado es 02h y ese 1 sobrevive solo en CF hasta la siguiente instrucción que modifique banderas. `ROL al, 1` sobre el mismo valor devuelve 03h; el bit 7 reaparece como bit 0 y CF guarda una copia. SHL nunca puede intercambiar nibbles. Cada desplazamiento a la izquierda descarta los bits altos y rellena con ceros por la derecha; después de `SHL al, 4` el nibble alto A ya no existe en el registro y ningún OR posterior puede reconstruirlo sin una copia previa en otro registro. `ROL al, 4` hace el intercambio en una sola instrucción de 3 bytes (C0 C0 04). La diferencia de destino del bit saliente es exactamente el criterio de elección.

### Decisión técnica 2: LOOP frente a DEC/JNZ

LOOP es más compacta y más legible. Codifica en 2 bytes (E2 desplazamiento) lo que DEC/JNZ expresa con 3 bytes (49 para `DEC cx` y 75 desplazamiento para `JNZ`), y el lector entiende de inmediato que CX es el contador. Sin embargo el número de instrucciones del código fuente no indica cuántos ciclos tarda el procesador. Cada instrucción tiene su propio costo de decodificación y de ejecución; en los procesadores Intel modernos LOOP se implementa con varias micro-operaciones mientras que DEC y JNZ son simples y además pueden fusionarse en una sola micro-operación. Por eso una instrucción puede costar más que dos. En el bucle de 5 iteraciones del bloque 4 la diferencia no se percibe; son unos pocos ciclos en un programa que tarda microsegundos. La respuesta cambia si el bucle se ejecuta millones de veces dentro de un programa mayor. Allí la diferencia por iteración se multiplica por el número de vueltas y DEC/JNZ es la opción razonable para la ruta crítica. La decisión es mantener LOOP en este laboratorio por claridad y usar DEC/JNZ cuando el perfilado señale el bucle como crítico.

